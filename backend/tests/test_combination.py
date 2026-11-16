"""
Test aturan keputusan inferensi.

Model 4 kelas (rule-v3): argmax softmax atas combination/dry/normal/oily.
Model lama 3 kelas (rule-v2):
    combination_score = 2 * min(P(dry), P(oily))
    is_combination    = score >= COMBINATION_SCORE_THRESHOLD
"""
import pytest

from app.core.config import get_settings
from app.ml import inference


def _derive(dry: float, oily: float, normal: float = 0.0):
    return inference.derive_combination({"dry": dry, "normal": normal, "oily": oily})


def test_dry_oily_seimbang_menjadi_kombinasi():
    probabilities, skin_type, confidence, score, is_combination = _derive(0.54, 0.46)

    assert is_combination is True
    assert score == pytest.approx(0.92, abs=1e-6)
    assert skin_type == "dry"
    # Probabilitas asli TIDAK dinol-kan
    assert probabilities["dry"] == pytest.approx(0.54, abs=1e-6)
    assert probabilities["oily"] == pytest.approx(0.46, abs=1e-6)
    assert probabilities["combination"] == pytest.approx(0.92, abs=1e-6)
    # Confidence = confidence kelas utama, bukan penjumlahan dua kelas
    assert confidence == pytest.approx(0.54, abs=1e-6)


def test_dry_dominan_bukan_kombinasi():
    probabilities, skin_type, confidence, score, is_combination = _derive(
        dry=0.80, oily=0.05, normal=0.15
    )

    assert is_combination is False
    assert score == pytest.approx(0.10, abs=1e-6)
    assert skin_type == "dry"
    assert confidence == pytest.approx(0.80, abs=1e-6)
    assert probabilities["combination"] == pytest.approx(0.10, abs=1e-6)


def test_normal_dominan_bukan_kombinasi():
    _, skin_type, confidence, score, is_combination = _derive(
        dry=0.05, oily=0.05, normal=0.90
    )

    assert is_combination is False
    assert score == pytest.approx(0.10, abs=1e-6)
    assert skin_type == "normal"
    assert confidence == pytest.approx(0.90, abs=1e-6)


def test_ambang_batas_skor():
    # dry=0.25, oily=0.25 -> skor 0.50 (tepat di ambang, harus kombinasi)
    _, _, _, score, is_combination = _derive(dry=0.25, oily=0.25, normal=0.50)
    assert score == pytest.approx(0.50, abs=1e-6)
    assert is_combination is True

    # dry=0.24, oily=0.26 -> skor 0.48 (di bawah ambang)
    _, _, _, score, is_combination = _derive(dry=0.24, oily=0.26, normal=0.50)
    assert score == pytest.approx(0.48, abs=1e-6)
    assert is_combination is False


def test_probabilitas_dinormalisasi():
    probabilities, skin_type, _, score, is_combination = _derive(
        dry=1.08, oily=0.92, normal=0.0
    )

    assert probabilities["dry"] == pytest.approx(0.54, abs=1e-6)
    assert probabilities["oily"] == pytest.approx(0.46, abs=1e-6)
    assert score == pytest.approx(0.92, abs=1e-6)
    assert is_combination is True
    assert skin_type == "dry"


def test_threshold_dari_settings(monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "combination_score_threshold", 0.95, raising=False)

    _, _, _, score, is_combination = _derive(0.54, 0.46)
    assert score == pytest.approx(0.92, abs=1e-6)
    assert is_combination is False


def test_model_4_kelas_memakai_argmax():
    probabilities = {"normal": 0.1, "oily": 0.2, "dry": 0.1, "combination": 0.6}
    result_probs, skin_type, confidence, score, is_combination = inference.derive_combination(
        probabilities
    )

    assert skin_type == "combination"
    assert is_combination is True
    assert confidence == pytest.approx(0.6, abs=1e-6)
    assert score == pytest.approx(0.6, abs=1e-6)
    assert result_probs == probabilities


def test_model_4_kelas_bukan_combination():
    probabilities = {"combination": 0.05, "dry": 0.15, "normal": 0.65, "oily": 0.15}
    _, skin_type, confidence, score, is_combination = inference.derive_combination(probabilities)

    assert skin_type == "normal"
    assert is_combination is False
    assert confidence == pytest.approx(0.65, abs=1e-6)
    assert score == pytest.approx(0.05, abs=1e-6)


def test_ml_info_endpoint(client):
    response = client.get("/api/v1/ml/info")
    assert response.status_code == 200

    data = response.json()
    assert data["rule_version"] == inference.RULE_VERSION
    assert data["classes"] == inference._class_names
    assert data["num_classes"] == len(inference._class_names)
    assert "decision_rule" in data
    assert "combination_score_threshold" in data
