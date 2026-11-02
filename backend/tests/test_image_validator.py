"""
Unit test untuk validasi citra
"""
import pytest
from PIL import Image
from fastapi import HTTPException

from tests.conftest import (
    make_fake_face_image,
    make_dark_image,
    make_blurry_image,
)


class TestImageValidator:
    """Test suite untuk app.services.image_validator"""

    def test_valid_image_returns_pil(self):
        """Gambar valid mengembalikan PIL Image"""
        from app.services.image_validator import validate_image
        img_bytes = make_fake_face_image(brightness=150)
        # Nonaktifkan deteksi wajah untuk test ini agar tidak bergantung OpenCV Haar
        import app.core.config as cfg_module
        original = cfg_module.get_settings().face_detection_enabled
        cfg_module.get_settings().face_detection_enabled = False

        try:
            result = validate_image(img_bytes, "test.jpg")
            assert isinstance(result, Image.Image)
        finally:
            cfg_module.get_settings().face_detection_enabled = original

    def test_dark_image_rejected(self):
        """Gambar gelap ditolak dengan kode IMAGE_TOO_DARK"""
        from app.services.image_validator import validate_image
        import app.core.config as cfg_module
        cfg_module.get_settings().face_detection_enabled = False

        img_bytes = make_dark_image()
        with pytest.raises(HTTPException) as exc_info:
            validate_image(img_bytes, "dark.jpg")

        assert exc_info.value.status_code == 422
        assert exc_info.value.detail["error"]["code"] == "IMAGE_TOO_DARK"

    def test_blurry_image_rejected(self):
        """Gambar buram ditolak dengan kode IMAGE_TOO_BLURRY"""
        from app.services.image_validator import validate_image
        import app.core.config as cfg_module
        cfg_module.get_settings().face_detection_enabled = False

        img_bytes = make_blurry_image()
        with pytest.raises(HTTPException) as exc_info:
            validate_image(img_bytes, "blurry.jpg")

        assert exc_info.value.status_code == 422
        assert exc_info.value.detail["error"]["code"] == "IMAGE_TOO_BLURRY"

    def test_invalid_extension_rejected(self):
        """File bukan gambar ditolak"""
        from app.services.image_validator import validate_image
        img_bytes = b"ini bukan gambar"
        with pytest.raises(HTTPException) as exc_info:
            validate_image(img_bytes, "file.txt")
        assert exc_info.value.status_code == 422
        assert exc_info.value.detail["error"]["code"] == "INVALID_FILE_TYPE"

    def test_file_too_large_rejected(self):
        """File melebihi batas ukuran ditolak"""
        from app.services.image_validator import validate_image
        # Buat byte array besar melebihi 8MB
        large_bytes = b"x" * (9 * 1024 * 1024)
        with pytest.raises(HTTPException) as exc_info:
            validate_image(large_bytes, "big.jpg")
        assert exc_info.value.status_code == 422
        assert exc_info.value.detail["error"]["code"] == "FILE_TOO_LARGE"
