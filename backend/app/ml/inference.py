"""
Skinly Backend - ML Inference Service
Memuat model MobileNetV2 sekali saat startup.
Jika model belum ada, berjalan dalam MODE DEMO (prediksi dummy).
"""
import json
import logging
import os
import random
import numpy as np
from PIL import Image
from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Urutan kelas sesuai training (alphabetical default Keras)
DEFAULT_CLASS_NAMES = ["combination", "dry", "normal", "oily"]

# State global model
_model = None
_class_names: list[str] = DEFAULT_CLASS_NAMES
_demo_mode: bool = True


def load_model() -> None:
    """
    Dimuat SATU KALI saat startup FastAPI (lifespan event).
    Jika file model tidak ada, aktifkan mode demo.
    """
    global _model, _class_names, _demo_mode

    # Coba muat class_names.json
    if os.path.exists(settings.class_names_path):
        try:
            with open(settings.class_names_path, "r") as f:
                _class_names = json.load(f)
            logger.info(f"✅ Class names dimuat: {_class_names}")
        except Exception as e:
            logger.warning(f"Gagal membaca class_names.json: {e}. Gunakan default.")
            _class_names = DEFAULT_CLASS_NAMES
    else:
        logger.warning(f"class_names.json tidak ditemukan di '{settings.class_names_path}'. Gunakan default.")
        _class_names = DEFAULT_CLASS_NAMES

    # Coba muat model Keras
    if not os.path.exists(settings.model_path):
        logger.warning(
            "⚠️  FILE MODEL TIDAK DITEMUKAN di '%s'. "
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
        logger.info(f"✅ Model ML dimuat dari '{settings.model_path}'")
    except Exception as e:
        logger.error(
            f"❌ Gagal memuat model dari '{settings.model_path}': {e}. "
            "Berjalan dalam MODE DEMO."
        )
        _demo_mode = True
        _model = None


def is_demo_mode() -> bool:
    return _demo_mode


def is_model_loaded() -> bool:
    return _model is not None


def preprocess_image(img: Image.Image) -> np.ndarray:
    """
    Preprocessing citra untuk MobileNetV2:
    - Resize ke 224x224
    - Normalisasi dengan mobilenet_v2.preprocess_input (range [-1, 1])
    """
    img_resized = img.resize((224, 224), Image.LANCZOS)
    img_array = np.array(img_resized, dtype=np.float32)

    # Expand dims untuk batch: (1, 224, 224, 3)
    img_array = np.expand_dims(img_array, axis=0)

    # Normalisasi MobileNetV2: [0,255] -> [-1,1]
    img_array = (img_array / 127.5) - 1.0

    return img_array


def predict(img: Image.Image) -> dict:
    """
    Jalankan inferensi pada gambar PIL.
    Mengembalikan dict: {skin_type, confidence, probabilities, demo}
    """
    global _model, _class_names, _demo_mode

    if _demo_mode or _model is None:
        # MODE DEMO: kembalikan prediksi acak dengan flag demo=True
        raw_scores = [random.random() for _ in _class_names]
        total = sum(raw_scores)
        probs = [s / total for s in raw_scores]

        best_idx = int(np.argmax(probs))
        skin_type = _class_names[best_idx]
        confidence = float(probs[best_idx])
        probabilities = {name: float(p) for name, p in zip(_class_names, probs)}

        logger.warning(
            "🔧 MODE DEMO - Prediksi: %s (%.1f%%) - BUKAN HASIL NYATA",
            skin_type, confidence * 100
        )
        return {
            "skin_type": skin_type,
            "confidence": confidence,
            "probabilities": probabilities,
            "demo": True,
        }

    # MODE NYATA
    try:
        preprocessed = preprocess_image(img)
        predictions = _model.predict(preprocessed, verbose=0)
        probs = predictions[0].tolist()

        best_idx = int(np.argmax(probs))
        skin_type = _class_names[best_idx]
        confidence = float(probs[best_idx])
        probabilities = {name: float(p) for name, p in zip(_class_names, probs)}

        logger.info(
            "🔍 Prediksi: %s (%.1f%%)",
            skin_type, confidence * 100
        )
        return {
            "skin_type": skin_type,
            "confidence": confidence,
            "probabilities": probabilities,
            "demo": False,
        }
    except Exception as e:
        logger.error(f"Error saat inferensi: {e}")
        raise
