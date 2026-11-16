"""
Skinly Backend - ML Inference Service

Model dilatih langsung untuk 4 kelas: combination, dry, normal, oily
(aturan keputusan "rule-v3": argmax softmax atas 4 kelas).

Kompatibilitas: jika masih memakai model lama 3 kelas (dry, normal, oily),
kelas "combination" diturunkan dengan aturan lama "rule-v2":

    combination_score = 2 * min(P(dry), P(oily))

Model dimuat SATU KALI saat startup FastAPI. Jika file model belum ada,
backend berjalan dalam MODE DEMO (prediksi acak, flag demo=true).
"""

from __future__ import annotations

import json
import logging
import os
import random

import numpy as np
from PIL import Image

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Urutan kelas sesuai training (alphabetical): combination < dry < normal < oily.
DEFAULT_CLASS_NAMES = ["combination", "dry", "normal", "oily"]

RULE_VERSION = "rule-v3"

# State global model
_model = None
_class_names: list[str] = DEFAULT_CLASS_NAMES
_demo_mode: bool = True
_preprocess_mode: str = "mobilenet_v2"
_model_meta: dict = {}
_calibration: dict = {}
_training_summary: dict = {}


def _read_json(path: str) -> dict | None:
    try:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as handle:
                data = json.load(handle)
            return data if isinstance(data, dict) else None
    except Exception as exc:
        logger.warning("Gagal membaca '%s': %s", path, exc)
    return None


def _find_latest_training_summary() -> dict:
    """Ambil training_summary_*.json terbaru di folder model (untuk /ml/info)."""
    model_dir = os.path.dirname(settings.model_path) or "."
    try:
        candidates = [
            os.path.join(model_dir, name)
            for name in os.listdir(model_dir)
            if name.startswith("training_summary_") and name.endswith(".json")
        ]
    except OSError:
        return {}
    if not candidates:
        return {}
    latest = max(candidates, key=os.path.getmtime)
    summary = _read_json(latest) or {}
    summary["summary_file"] = os.path.basename(latest)
    return summary


def load_model() -> None:
    """Dimuat SATU KALI saat startup FastAPI (lifespan event)."""
    global _model, _class_names, _demo_mode, _preprocess_mode, _model_meta
    global _calibration, _training_summary

    if os.path.exists(settings.class_names_path):
        try:
            with open(settings.class_names_path, "r", encoding="utf-8") as f:
                loaded = json.load(f)
            if isinstance(loaded, list) and all(isinstance(x, str) for x in loaded) and loaded:
                _class_names = [name.lower() for name in loaded]
                logger.info("Class names dimuat: %s", _class_names)
            else:
                raise ValueError("class_names.json harus berupa list string yang tidak kosong")
        except Exception as exc:
            logger.warning("Gagal membaca class_names.json: %s. Gunakan default.", exc)
            _class_names = DEFAULT_CLASS_NAMES
    else:
        logger.warning(
            "class_names.json tidak ditemukan di '%s'. Gunakan default.",
            settings.class_names_path,
        )
        _class_names = DEFAULT_CLASS_NAMES

    # Metadata preprocessing/backbone (opsional, model lama tetap jalan).
    meta_path = os.path.join(os.path.dirname(settings.model_path) or ".", "model_meta.json")
    _model_meta = _read_json(meta_path) or {}
    _preprocess_mode = str(_model_meta.get("preprocessing") or "mobilenet_v2")

    # Kalibrasi temperature scaling (opsional).
    calibration_path = os.path.join(os.path.dirname(settings.model_path) or ".", "calibration.json")
    _calibration = _read_json(calibration_path) or {}
    _training_summary = _find_latest_training_summary()

    if not os.path.exists(settings.model_path):
        logger.warning(
            "WARNING: FILE MODEL TIDAK DITEMUKAN di '%s'. "
            "Backend berjalan dalam MODE DEMO - prediksi bersifat ACAK dan TIDAK AKURAT. "
            "Latih model terlebih dahulu dengan menjalankan ml_training/train.py.",
            settings.model_path,
        )
        _demo_mode = True
        _model = None
        return

    try:
        import tensorflow as tf  # type: ignore

        _model = tf.keras.models.load_model(settings.model_path)
        _demo_mode = False
        logger.info("Model ML dimuat dari '%s'", settings.model_path)
        logger.info("   Backbone/preprocessing: %s", _preprocess_mode)
        logger.info("   Input shape : %s", getattr(_model, "input_shape", "unknown"))
        logger.info("   Output shape: %s", getattr(_model, "output_shape", "unknown"))
        if getattr(_model, "output_shape", None) and _model.output_shape[-1] != len(_class_names):
            logger.warning(
                "WARNING: Jumlah output model (%s) tidak cocok dengan class_names (%s).",
                _model.output_shape[-1],
                _class_names,
            )
    except Exception as exc:
        logger.error(
            "ERROR: Gagal memuat model dari '%s': %s. Berjalan dalam MODE DEMO.",
            settings.model_path,
            exc,
        )
        _demo_mode = True
        _model = None


def is_demo_mode() -> bool:
    return _demo_mode


def is_model_loaded() -> bool:
    return _model is not None


def get_model_info() -> dict:
    """Ringkasan model & aturan keputusan untuk endpoint /ml/info."""
    temperature = float(_calibration.get("temperature", 1.0) or 1.0)
    legacy_rule = "combination" not in _class_names
    return {
        "model_loaded": is_model_loaded(),
        "demo_mode": is_demo_mode(),
        "classes": list(_class_names),
        "num_classes": len(_class_names),
        "backbone": _model_meta.get("backbone"),
        "preprocessing": _preprocess_mode,
        "img_size": _model_meta.get("img_size", [224, 224]),
        "rule_version": RULE_VERSION,
        "decision_rule": (
            "argmax(softmax) atas kelas combination/dry/normal/oily"
            if not legacy_rule
            else "combination_score = 2 * min(P(dry), P(oily))"
        ),
        "combination_score_threshold": float(settings.combination_score_threshold),
        "temperature": round(temperature, 4),
        "calibration": _calibration or None,
        "training_summary": _training_summary or None,
    }


def preprocess_image(img: Image.Image) -> np.ndarray:
    """
    Resize 224x224 lalu sesuaikan preprocessing dengan backbone:
    - mobilenet_v2: normalisasi ke [-1, 1]
    - efficientnet: biarkan 0-255 (normalisasi ada di dalam model)
    """
    img_resized = img.resize((224, 224), Image.LANCZOS)
    img_array = np.array(img_resized, dtype=np.float32)

    if str(_preprocess_mode).lower().startswith("efficientnet"):
        img_array = np.expand_dims(img_array, axis=0)
        return img_array

    img_array = np.expand_dims(img_array, axis=0)
    img_array = (img_array / 127.5) - 1.0
    return img_array


def _normalize_three(raw_probs: dict[str, float]) -> tuple[float, float, float]:
    normal = max(float(raw_probs.get("normal", 0.0)), 0.0)
    dry = max(float(raw_probs.get("dry", 0.0)), 0.0)
    oily = max(float(raw_probs.get("oily", 0.0)), 0.0)
    total = normal + dry + oily
    if total > 0:
        normal, dry, oily = normal / total, dry / total, oily / total
    return normal, dry, oily


def _apply_temperature(probs: dict[str, float]) -> dict[str, float]:
    """Temperature scaling: p^(1/T) lalu normalisasi (T dari calibration.json)."""
    temperature = float(_calibration.get("temperature", 1.0) or 1.0)
    if abs(temperature - 1.0) < 1e-3:
        return probs

    scaled = {}
    for key, value in probs.items():
        scaled[key] = float(np.power(max(float(value), 1e-12), 1.0 / temperature))
    total = sum(scaled.values())
    if total <= 0:
        return probs
    return {key: value / total for key, value in scaled.items()}


def derive_combination(
    raw_probs: dict[str, float],
) -> tuple[dict[str, float], str, float, float, bool]:
    """
    Tentukan jenis kulit akhir dari probabilitas model.

    - Model 4 kelas: argmax langsung (rule-v3), confidence = P(kelas terpilih),
      combination_score = P(combination).
    - Model lama 3 kelas: combination diturunkan dengan rule-v2.

    Returns:
        (probabilities, skin_type, confidence, combination_score, is_combination)
    """
    calibrated = {key: float(value) for key, value in raw_probs.items()}

    if "combination" in calibrated and len(calibrated) >= 4:
        probabilities = calibrated
        skin_type = max(probabilities, key=probabilities.get)
        score = float(probabilities.get("combination", 0.0))
        confidence = float(probabilities[skin_type])
        return probabilities, skin_type, confidence, score, skin_type == "combination"

    # --- Kompatibilitas model lama 3 kelas (rule-v2) ---
    normal, dry, oily = _normalize_three(calibrated)
    combination_score = 2.0 * min(dry, oily)
    is_combination = combination_score >= float(settings.combination_score_threshold)

    probabilities = {
        "normal": normal,
        "dry": dry,
        "oily": oily,
        "combination": combination_score,
    }
    skin_type = max(
        ("normal", "dry", "oily"),
        key=lambda name: probabilities[name],
    )
    confidence = float(probabilities[skin_type])
    return probabilities, skin_type, confidence, combination_score, is_combination


def predict(img: Image.Image) -> dict:
    """
    Jalankan inferensi pada gambar PIL.

    Returns dict dengan kunci:
        skin_type, confidence, probabilities, raw_probabilities,
        combination_score, is_combination, rule_version, demo
    """
    global _model, _class_names, _demo_mode

    if _demo_mode or _model is None:
        raw_scores = [random.random() for _ in _class_names]
        total = sum(raw_scores)
        raw_probs = {
            name: float(score / total) for name, score in zip(_class_names, raw_scores)
        }
        probabilities, skin_type, confidence, score, is_combination = derive_combination(
            _apply_temperature(raw_probs)
        )

        logger.warning(
            "MODE DEMO - Prediksi: %s (%.1f%%) - BUKAN HASIL NYATA",
            skin_type,
            confidence * 100,
        )
        return {
            "skin_type": skin_type,
            "confidence": confidence,
            "probabilities": probabilities,
            "raw_probabilities": dict(raw_probs),
            "combination_score": score,
            "is_combination": is_combination,
            "rule_version": RULE_VERSION,
            "demo": True,
        }

    try:
        preprocessed = preprocess_image(img)
        predictions = _model.predict(preprocessed, verbose=0)
        probs = predictions[0].tolist()

        if len(probs) != len(_class_names):
            raise ValueError(
                f"Jumlah output model ({len(probs)}) tidak cocok dengan class_names "
                f"({len(_class_names)}: {_class_names}). Latih ulang model atau perbaiki class_names.json."
            )

        raw_probs = {
            name: float(p) for name, p in zip(_class_names, probs)
        }
        probabilities, skin_type, confidence, score, is_combination = derive_combination(
            _apply_temperature(raw_probs)
        )

        logger.info(
            "Prediksi: %s (%.1f%%) | probs=%s | combination_score=%.4f",
            skin_type,
            confidence * 100,
            {k: round(v, 4) for k, v in probabilities.items()},
            score,
        )
        return {
            "skin_type": skin_type,
            "confidence": confidence,
            "probabilities": probabilities,
            "raw_probabilities": raw_probs,
            "combination_score": score,
            "is_combination": is_combination,
            "rule_version": RULE_VERSION,
            "demo": False,
        }
    except Exception as exc:
        logger.error("Error saat inferensi: %s", exc)
        raise
