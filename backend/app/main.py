"""
Skinly Backend - Aplikasi FastAPI Utama
Menangani startup (muat model ML), CORS, routing, dan error handler seragam.
"""
import logging
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.core.config import get_settings
from app.core.logging import setup_logging
from app.core.database import check_db_connection
from app.ml import inference
from app.api.v1 import api_router

# Setup logging lebih awal
setup_logging()
logger = logging.getLogger(__name__)
settings = get_settings()


# ============================================================
# Lifespan: startup & shutdown
# ============================================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Dijalankan saat startup dan shutdown.
    Model ML dimuat SATU KALI di sini agar tidak reload per request.
    """
    logger.info("🚀 Skinly Backend sedang dimulai...")

    # Cek koneksi database
    db_ok = check_db_connection()
    if not db_ok:
        logger.warning("⚠️  Database tidak terhubung. Pastikan MySQL menyala (Laragon/XAMPP).")

    # Muat model ML (atau aktifkan mode demo)
    inference.load_model()

    # Buat folder uploads jika belum ada
    os.makedirs(settings.upload_dir, exist_ok=True)
    logger.info(f"📁 Folder upload: {os.path.abspath(settings.upload_dir)}")

    logger.info("✅ Skinly Backend siap! Buka http://localhost:8000/docs untuk API docs.")
    yield
    logger.info("👋 Skinly Backend berhenti.")


# ============================================================
# Buat aplikasi FastAPI
# ============================================================
app = FastAPI(
    title="Skinly API",
    description=(
        "Backend Skinly - Aplikasi pendeteksi jenis kulit wajah berbasis Machine Learning. "
        "Semua endpoint menggunakan header **X-Device-Id** untuk identifikasi anonim."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)


# ============================================================
# CORS
# ============================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins_list if settings.allowed_origins != "*" else [],
    allow_origin_regex=r"^https?://.*" if settings.allowed_origins == "*" else None,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
    expose_headers=["*"],
)


# ============================================================
# Error Handler Seragam
# ============================================================
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"error": {"code": "INTERNAL_ERROR", "message": "Terjadi kesalahan pada server. Coba lagi nanti."}},
    )


# ============================================================
# Mount static files (untuk thumbnail gambar)
# ============================================================
uploads_dir = settings.upload_dir
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")


# ============================================================
# Include Routers
# ============================================================
app.include_router(api_router, prefix="/api/v1")


# ============================================================
# Root endpoint
# ============================================================
@app.get("/", tags=["Root"])
def root():
    return {
        "app": "Skinly API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/api/v1/health",
        "demo_mode": inference.is_demo_mode(),
    }
