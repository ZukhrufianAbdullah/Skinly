"""
Skinly Backend - Validasi Citra (kompatibel dengan OpenCV 5.0)
Memeriksa kualitas foto sebelum diproses model ML:
 - Ukuran & tipe file
 - Brightness (cahaya cukup)
 - Sharpness (tidak buram)
 - Deteksi wajah via skin color heuristic (kompatibel OpenCV 4 & 5)
"""
import io
import logging
import cv2
import numpy as np
from PIL import Image
from fastapi import HTTPException, status
from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


def _pil_to_cv2(img: Image.Image) -> np.ndarray:
    """Konversi PIL Image ke array OpenCV BGR"""
    return cv2.cvtColor(np.array(img.convert("RGB")), cv2.COLOR_RGB2BGR)


def _detect_face_skin_color(cv_img: np.ndarray) -> bool:
    """
    Deteksi keberadaan wajah menggunakan analisis warna kulit (HSV skin color range).
    Lebih kompatibel dengan berbagai versi OpenCV.
    Mengembalikan True jika area dengan warna kulit cukup besar terdeteksi.
    """
    # Konversi ke HSV
    hsv = cv2.cvtColor(cv_img, cv2.COLOR_BGR2HSV)

    # Range warna kulit dalam HSV (mencakup berbagai warna kulit)
    # H: 0-20 (merah-oranye), S: 20-150, V: 70-255
    lower_skin = np.array([0, 20, 70], dtype=np.uint8)
    upper_skin = np.array([20, 180, 255], dtype=np.uint8)
    mask1 = cv2.inRange(hsv, lower_skin, upper_skin)

    # Range kedua untuk warna kulit lebih gelap / coklat
    lower_skin2 = np.array([170, 20, 70], dtype=np.uint8)
    upper_skin2 = np.array([180, 180, 255], dtype=np.uint8)
    mask2 = cv2.inRange(hsv, lower_skin2, upper_skin2)

    mask = cv2.bitwise_or(mask1, mask2)

    # Hitung persentase piksel warna kulit
    total_pixels = cv_img.shape[0] * cv_img.shape[1]
    skin_pixels = cv2.countNonZero(mask)
    skin_ratio = skin_pixels / total_pixels

    logger.debug(f"Skin ratio: {skin_ratio:.3f} (min: 0.10)")

    # Minimal 10% gambar harus berwarna kulit
    return skin_ratio >= 0.10


def validate_image(image_bytes: bytes, filename: str) -> Image.Image:
    """
    Validasi lengkap citra yang diunggah.
    Melempar HTTPException 422 dengan pesan Indonesia jika tidak valid.
    Mengembalikan PIL Image jika valid.
    """
    # 1. Cek ukuran file
    if len(image_bytes) > settings.max_upload_size_bytes:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "error": {
                    "code": "FILE_TOO_LARGE",
                    "message": (
                        f"Ukuran file melebihi batas {settings.max_upload_size_mb} MB. "
                        "Silakan kompres atau pilih foto yang lebih kecil."
                    ),
                }
            },
        )

    # 2. Cek ekstensi / tipe file
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    if ext not in settings.allowed_extensions_list:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "error": {
                    "code": "INVALID_FILE_TYPE",
                    "message": (
                        f"Tipe file '{ext}' tidak didukung. "
                        f"Gunakan salah satu dari: {', '.join(settings.allowed_extensions_list).upper()}."
                    ),
                }
            },
        )

    # 3. Buka sebagai PIL Image
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img.verify()          # cek integritas
        img = Image.open(io.BytesIO(image_bytes))  # buka ulang setelah verify
        img = img.convert("RGB")
    except Exception as e:
        logger.warning(f"Gagal membuka gambar: {e}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "error": {
                    "code": "INVALID_IMAGE",
                    "message": "File gambar tidak dapat dibaca atau rusak. Coba unggah foto yang lain.",
                }
            },
        )

    # 4. Konversi ke OpenCV
    cv_img = _pil_to_cv2(img)
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)

    # 5. Cek Brightness
    mean_brightness = float(np.mean(gray))
    logger.debug(f"Brightness rata-rata: {mean_brightness:.1f} (min: {settings.min_brightness})")
    if mean_brightness < settings.min_brightness:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "error": {
                    "code": "IMAGE_TOO_DARK",
                    "message": (
                        "Foto terlalu gelap. Pastikan pencahayaan cukup (dekat jendela atau nyalakan lampu) "
                        "dan coba ambil foto kembali."
                    ),
                }
            },
        )

    # 6. Cek Sharpness (Variance of Laplacian)
    laplacian_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    logger.debug(f"Sharpness (var Laplacian): {laplacian_var:.1f} (min: {settings.min_sharpness})")
    if laplacian_var < settings.min_sharpness:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "error": {
                    "code": "IMAGE_TOO_BLURRY",
                    "message": (
                        "Foto terlihat buram. Pegang kamera dengan stabil, "
                        "pastikan fokus pada wajah, lalu coba lagi."
                    ),
                }
            },
        )

    # 7. Deteksi Wajah (menggunakan skin color heuristic, kompatibel OpenCV 4 & 5)
    if settings.face_detection_enabled:
        has_face = _detect_face_skin_color(cv_img)
        if not has_face:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail={
                    "error": {
                        "code": "NO_FACE_DETECTED",
                        "message": (
                            "Wajah tidak terdeteksi pada foto. "
                            "Pastikan wajah menghadap ke depan, "
                            "pencahayaan cukup, dan tidak ada penghalang (masker, kacamata hitam). "
                            "Coba lagi dengan foto yang lebih jelas."
                        ),
                    }
                },
            )
        logger.debug("Wajah terdeteksi via skin color analysis")

    return img
