"""
Skinly Backend - Endpoint Health Check
GET /api/v1/health
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db, check_db_connection
from app.ml import inference
from app.schemas.schemas import HealthResponse

router = APIRouter(prefix="/health", tags=["Health"])


@router.get("", response_model=HealthResponse, summary="Cek status layanan backend")
def health_check(db: Session = Depends(get_db)):
    db_ok = check_db_connection()
    return HealthResponse(
        status="ok" if db_ok else "degraded",
        database="connected" if db_ok else "disconnected",
        model_loaded=inference.is_model_loaded(),
        demo_mode=inference.is_demo_mode(),
    )
