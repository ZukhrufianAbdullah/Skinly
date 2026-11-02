"""
Skinly Backend - Models SQLAlchemy
Definisi tabel database MySQL
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Float, Text, Integer, DateTime,
    Enum as SAEnum, ForeignKey, JSON
)
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.mysql import TINYINT, LONGTEXT
from app.core.database import Base


def gen_uuid() -> str:
    """Generate UUID string untuk primary key"""
    return str(uuid.uuid4())


def utcnow() -> datetime:
    """Waktu UTC saat ini"""
    return datetime.now(timezone.utc).replace(tzinfo=None)


class User(Base):
    """Tabel Pengguna Skinly"""
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    username = Column(String(50), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relasi
    scans = relationship("ScanHistory", back_populates="user", cascade="all, delete-orphan")
    feedbacks = relationship("Feedback", back_populates="user", cascade="all, delete-orphan")


class ScanHistory(Base):
    """Riwayat scan kulit pengguna"""
    __tablename__ = "scan_history"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    device_id = Column(String(64), nullable=True, index=True)
    skin_type = Column(
        SAEnum("normal", "oily", "dry", "combination", name="skin_type_enum"),
        nullable=False,
    )
    confidence = Column(Float, nullable=False)          # nilai 0.0 - 1.0
    probabilities = Column(JSON, nullable=False)        # {"normal": 0.x, ...}
    image_path = Column(String(255), nullable=True)     # path file thumbnail
    created_at = Column(DateTime, default=utcnow, index=True, nullable=False)

    user = relationship("User", back_populates="scans")


class Article(Base):
    """Artikel edukasi kulit"""
    __tablename__ = "articles"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    title = Column(String(200), nullable=False)
    category = Column(
        SAEnum("jenis_kulit", "masalah_kulit", "perawatan", name="article_category_enum"),
        nullable=False,
    )
    summary = Column(String(500), nullable=False)
    content = Column(Text().with_variant(LONGTEXT, "mysql"), nullable=False)
    cover_image_url = Column(String(255), nullable=True)
    read_minutes = Column(Integer, nullable=False, default=3)
    created_at = Column(DateTime, default=utcnow, nullable=False)


class SkinTypeInfo(Base):
    """Informasi & rekomendasi per jenis kulit - diisi melalui seed"""
    __tablename__ = "skin_type_info"

    skin_type = Column(
        SAEnum("normal", "oily", "dry", "combination", name="skin_type_info_enum"),
        primary_key=True,
    )
    description = Column(Text, nullable=False)
    characteristics = Column(JSON, nullable=False)      # list string
    routine_morning = Column(JSON, nullable=False)      # list langkah pagi
    routine_night = Column(JSON, nullable=False)        # list langkah malam
    recommended_products = Column(JSON, nullable=False) # list kategori produk


class Feedback(Base):
    """Feedback kepuasan pengguna terhadap akurasi aplikasi"""
    __tablename__ = "feedback"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    device_id = Column(String(64), nullable=True, index=True)
    rating = Column(Integer().with_variant(TINYINT(unsigned=False), "mysql"), nullable=False)    # 1 - 5
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=utcnow, nullable=False)

    user = relationship("User", back_populates="feedbacks")
