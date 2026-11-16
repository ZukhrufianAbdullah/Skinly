"""
Skinly Backend - Endpoint Scan
POST /api/v1/scans/analyze  -> validasi + inferensi ML (belum simpan ke DB)
POST /api/v1/scans          -> simpan hasil ke riwayat
GET  /api/v1/scans          -> daftar riwayat milik user
GET  /api/v1/scans/{id}     -> detail riwayat
DELETE /api/v1/scans/{id}   -> hapus riwayat
"""
import logging
import os
import uuid
import aiofiles
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.config import get_settings
from app.models.models import ScanHistory, SkinTypeInfo, User
from app.schemas.schemas import (
    AnalyzeResponse, ScanCreateRequest, ScanResponse, ScanDetailResponse, ScanListResponse
)
from app.services.image_validator import validate_image
from app.ml import inference
from app.api.deps import get_current_user

logger = logging.getLogger(__name__)
settings = get_settings()

router = APIRouter(prefix="/scans", tags=["Scan"])


def _get_skin_info(db: Session, skin_type: str) -> Optional[SkinTypeInfo]:
    return db.query(SkinTypeInfo).filter(SkinTypeInfo.skin_type == skin_type).first()


def _normalize_routine(items: Optional[list], label: str) -> list[dict]:
    """
    Pastikan format routine selalu list of dict {step, name, detail}.
    Data seed terbaru sudah berupa dict; ini menjaga kompatibilitas data lama.
    """
    if not isinstance(items, list):
        return []

    normalized: list[dict] = []
    for index, item in enumerate(items, start=1):
        if isinstance(item, dict):
            normalized.append(
                {
                    "step": str(item.get("step", index)),
                    "name": str(item.get("name", item.get("title", label))),
                    "detail": str(item.get("detail", item.get("description", ""))),
                }
            )
        else:
            normalized.append(
                {
                    "step": str(index),
                    "name": str(item),
                    "detail": "",
                }
            )
    return normalized


def _normalize_products(items: Optional[list]) -> list[dict]:
    """Pastikan format produk selalu list of dict {name, note}."""
    if not isinstance(items, list):
        return []

    normalized: list[dict] = []
    for item in items:
        if isinstance(item, dict):
            normalized.append(
                {
                    "name": str(item.get("name", item.get("category", str(item)))),
                    "note": str(item.get("note", item.get("description", ""))),
                }
            )
        else:
            normalized.append({"name": str(item), "note": ""})
    return normalized


# ============================================================
# POST /scans/analyze
# ============================================================
@router.post(
    "/analyze",
    response_model=AnalyzeResponse,
    summary="Analisis foto wajah dan klasifikasikan jenis kulit",
)
async def analyze_skin(
    image: UploadFile = File(..., description="Foto wajah (JPEG/PNG/WebP, maks 8 MB)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Menerima foto wajah, memvalidasi kualitas, menjalankan inferensi ML,
    dan mengembalikan jenis kulit beserta rekomendasi.
    BELUM menyimpan ke database - gunakan POST /scans untuk menyimpan.
    """
    # Baca bytes file
    image_bytes = await image.read()

    # Validasi citra (melempar HTTPException jika gagal)
    pil_img = validate_image(image_bytes, image.filename or "upload.jpg")

    # Inferensi ML
    result = inference.predict(pil_img)
    skin_type = result["skin_type"]

    # Ambil info dari DB
    skin_info = _get_skin_info(db, skin_type)

    if skin_info:
        description = skin_info.description
        routine = {
            "morning": _normalize_routine(skin_info.routine_morning, "Perawatan pagi"),
            "night": _normalize_routine(skin_info.routine_night, "Perawatan malam"),
        }
        products = _normalize_products(skin_info.recommended_products)
    else:
        # Fallback jika seed belum dijalankan
        description = f"Jenis kulit {skin_type} terdeteksi."
        routine = {
            "morning": [
                {"step": "1", "name": "Cuci muka", "detail": "Gunakan pembersih wajah yang lembut."},
                {"step": "2", "name": "Pelembap", "detail": "Pilih pelembap sesuai jenis kulit."},
                {"step": "3", "name": "Sunscreen", "detail": "Gunakan SPF 30+ setiap pagi."},
            ],
            "night": [
                {"step": "1", "name": "Cuci muka", "detail": "Bersihkan sisa makeup dan kotoran."},
                {"step": "2", "name": "Pelembap", "detail": "Kunci kelembapan kulit sebelum tidur."},
            ],
        }
        products = [
            {"name": "Pembersih wajah gentle", "note": "Untuk membersihkan tanpa membuat kering"},
            {"name": "Pelembap ringan", "note": "Jaga hidrasi kulit"},
            {"name": "Sunscreen SPF 30+", "note": "Proteksi dari sinar UV"},
        ]

    return AnalyzeResponse(
        skin_type=skin_type,
        confidence=result["confidence"],
        probabilities=result["probabilities"],
        description=description,
        routine=routine,
        products=products,
        demo=result["demo"],
        raw_probabilities=result.get("raw_probabilities", {}),
        combination_score=result.get("combination_score", 0.0),
        is_combination=result.get("is_combination", False),
        rule_version=result.get("rule_version", "rule-v3"),
    )


# ============================================================
# POST /scans  (simpan riwayat)
# ============================================================
@router.post(
    "",
    response_model=ScanResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Simpan hasil analisis ke riwayat",
)
async def save_scan(
    request: ScanCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    scan = ScanHistory(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        skin_type=request.skin_type.value,
        confidence=request.confidence,
        probabilities=request.probabilities,
        image_path=request.image_path,
        created_at=datetime.now(timezone.utc).replace(tzinfo=None),
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)
    logger.info(f"Riwayat scan disimpan: {scan.id} | user_id: {current_user.id}")
    return scan


# ============================================================
# POST /scans/upload-image  (simpan thumbnail)
# ============================================================
@router.post(
    "/upload-image",
    summary="Unggah gambar thumbnail untuk disimpan di server",
)
async def upload_scan_image(
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Simpan thumbnail gambar dan kembalikan path-nya"""
    os.makedirs(settings.upload_dir, exist_ok=True)
    ext = (image.filename or "img.jpg").rsplit(".", 1)[-1].lower()
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = os.path.join(settings.upload_dir, filename)

    contents = await image.read()
    async with aiofiles.open(filepath, "wb") as f:
        await f.write(contents)

    return {"image_path": filepath, "filename": filename}


# ============================================================
# GET /scans  (daftar riwayat)
# ============================================================
@router.get(
    "",
    response_model=ScanListResponse,
    summary="Daftar riwayat scan milik user (urut terbaru)",
)
def list_scans(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    query = (
        db.query(ScanHistory)
        .filter(ScanHistory.user_id == current_user.id)
        .order_by(ScanHistory.created_at.desc())
    )
    total = query.count()
    items = query.offset((page - 1) * page_size).limit(page_size).all()

    return ScanListResponse(items=items, total=total, page=page, page_size=page_size)


# ============================================================
# GET /scans/{id}
# ============================================================
@router.get(
    "/{scan_id}",
    response_model=ScanDetailResponse,
    summary="Detail riwayat scan",
)
def get_scan(
    scan_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    scan = (
        db.query(ScanHistory)
        .filter(ScanHistory.id == scan_id, ScanHistory.user_id == current_user.id)
        .first()
    )
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Riwayat scan tidak ditemukan."}}
        )

    skin_type_str = scan.skin_type.value if hasattr(scan.skin_type, "value") else str(scan.skin_type)
    skin_info = _get_skin_info(db, skin_type_str)

    if skin_info:
        description = skin_info.description
        routine = {
            "morning": _normalize_routine(skin_info.routine_morning, "Perawatan pagi"),
            "night": _normalize_routine(skin_info.routine_night, "Perawatan malam"),
        }
        products = _normalize_products(skin_info.recommended_products)
    else:
        description = f"Jenis kulit {skin_type_str} terdeteksi."
        routine = {
            "morning": [
                {"step": "1", "name": "Cuci muka", "detail": "Gunakan pembersih wajah yang lembut."},
                {"step": "2", "name": "Pelembap", "detail": "Pilih pelembap sesuai jenis kulit."},
                {"step": "3", "name": "Sunscreen", "detail": "Gunakan SPF 30+ setiap pagi."},
            ],
            "night": [
                {"step": "1", "name": "Cuci muka", "detail": "Bersihkan sisa makeup dan kotoran."},
                {"step": "2", "name": "Pelembap", "detail": "Kunci kelembapan kulit sebelum tidur."},
            ],
        }
        products = [
            {"name": "Pembersih wajah gentle", "note": "Untuk membersihkan tanpa membuat kering"},
            {"name": "Pelembap ringan", "note": "Jaga hidrasi kulit"},
            {"name": "Sunscreen SPF 30+", "note": "Proteksi dari sinar UV"},
        ]

    return ScanDetailResponse(
        id=scan.id,
        user_id=scan.user_id,
        device_id=scan.device_id,
        skin_type=scan.skin_type,
        confidence=scan.confidence,
        probabilities=scan.probabilities,
        image_path=scan.image_path,
        created_at=scan.created_at,
        description=description,
        routine=routine,
        products=products,
    )


# ============================================================
# DELETE /scans/{id}
# ============================================================
@router.delete(
    "/{scan_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Hapus riwayat scan beserta gambarnya",
)
def delete_scan(
    scan_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    scan = (
        db.query(ScanHistory)
        .filter(ScanHistory.id == scan_id, ScanHistory.user_id == current_user.id)
        .first()
    )
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Riwayat scan tidak ditemukan."}}
        )

    # Hapus file gambar jika ada
    if scan.image_path and os.path.exists(scan.image_path):
        try:
            os.remove(scan.image_path)
            logger.info(f"File gambar dihapus: {scan.image_path}")
        except OSError as e:
            logger.warning(f"Gagal hapus file: {e}")

    db.delete(scan)
    db.commit()
    logger.info(f"Riwayat scan dihapus: {scan_id}")
