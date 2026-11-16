"""
Skinly Backend - Endpoint Informasi Model ML
GET /api/v1/ml/info

Menampilkan kelas, backbone, aturan kombinasi aktif, hasil evaluasi terakhir,
dan status kalibrasi. Berguna untuk demo, debugging, dan lampiran laporan.
"""
from fastapi import APIRouter

from app.ml import inference

router = APIRouter(prefix="/ml", tags=["ML"])


@router.get("/info", summary="Informasi model ML dan aturan kombinasi")
def ml_info():
    return inference.get_model_info()
