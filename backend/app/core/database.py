"""
Skinly Backend - Koneksi Database MySQL via SQLAlchemy
Menggunakan connection pool dengan pool_pre_ping=True agar koneksi idle tidak error
"""
import logging
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.core.config import get_settings

logger = logging.getLogger(__name__)

settings = get_settings()

# Buat engine SQLAlchemy (sinkron, PyMySQL)
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,       # cek koneksi sebelum digunakan
    pool_size=10,
    max_overflow=20,
    pool_recycle=3600,        # daur ulang koneksi setiap 1 jam
    echo=(settings.app_env == "development"),
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    """Base class untuk semua model SQLAlchemy"""
    pass


def get_db():
    """Dependency injection untuk FastAPI - menyediakan database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def check_db_connection() -> bool:
    """Cek apakah koneksi ke MySQL berhasil"""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("✅ Koneksi ke database MySQL berhasil")
        return True
    except Exception as e:
        logger.error(f"❌ Gagal koneksi ke database: {e}")
        return False
