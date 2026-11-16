"""
Skinly Backend - Pydantic Schemas (Request & Response)
Menggunakan Pydantic v2
"""
from __future__ import annotations
from datetime import datetime
from typing import Optional, Any
from pydantic import BaseModel, Field, field_serializer, field_validator
from enum import Enum

from app.schemas.datetime_utils import serialize_utc


class UTCModel(BaseModel):
    """Base model yang selalu mengirim timestamp sebagai UTC ber-offset ("Z")."""

    @field_serializer("created_at", check_fields=False)
    def _serialize_created_at(self, value: datetime) -> str:
        return serialize_utc(value)


# ============================================================
# Enums
# ============================================================

class SkinTypeEnum(str, Enum):
    normal = "normal"
    oily = "oily"
    dry = "dry"
    combination = "combination"


class ArticleCategoryEnum(str, Enum):
    jenis_kulit = "jenis_kulit"
    masalah_kulit = "masalah_kulit"
    perawatan = "perawatan"


# ============================================================
# Error Response
# ============================================================

class ErrorDetail(BaseModel):
    code: str
    message: str


class ErrorResponse(BaseModel):
    error: ErrorDetail


# ============================================================
# Analyze (Hasil inferensi ML - belum disimpan ke DB)
# ============================================================

class AnalyzeResponse(BaseModel):
    skin_type: SkinTypeEnum
    confidence: float = Field(..., ge=0.0, le=1.0)
    probabilities: dict[str, float]   # 4 key: combination, dry, normal, oily
    description: str
    # {"morning": [{step, name, detail}, ...], "night": [...]}
    routine: dict[str, list[dict[str, Any]]]
    products: list[dict[str, Any]]   # [{name, note}, ...]
    demo: bool = False               # True jika model belum ada (mode demo)
    # --- rule-v3 (opsional supaya klien lama tetap kompatibel) ---
    raw_probabilities: dict[str, float] = Field(default_factory=dict)
    combination_score: float = Field(0.0, ge=0.0, le=1.0)
    is_combination: bool = False
    rule_version: str = "rule-v3"


# ============================================================
# Scan History
# ============================================================

class ScanCreateRequest(BaseModel):
    skin_type: SkinTypeEnum
    confidence: float = Field(..., ge=0.0, le=1.0)
    probabilities: dict[str, float]
    image_path: Optional[str] = None


class ScanResponse(UTCModel):
    id: str
    user_id: Optional[str] = None
    device_id: Optional[str] = None
    skin_type: SkinTypeEnum
    confidence: float
    probabilities: dict[str, float]
    image_path: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ScanDetailResponse(ScanResponse):
    description: Optional[str] = None
    routine: Optional[dict[str, list[dict[str, Any]]]] = None
    products: Optional[list[dict[str, Any]]] = None


class ScanListResponse(BaseModel):
    items: list[ScanResponse]
    total: int
    page: int
    page_size: int


# ============================================================
# Articles
# ============================================================

class ArticleListItem(UTCModel):
    id: str
    title: str
    category: ArticleCategoryEnum
    summary: str
    cover_image_url: Optional[str] = None
    read_minutes: int
    created_at: datetime

    model_config = {"from_attributes": True}


class ArticleDetail(UTCModel):
    id: str
    title: str
    category: ArticleCategoryEnum
    summary: str
    content: str
    cover_image_url: Optional[str] = None
    read_minutes: int
    created_at: datetime

    model_config = {"from_attributes": True}


class ArticleListResponse(BaseModel):
    items: list[ArticleListItem]
    total: int


# ============================================================
# Skin Type Info
# ============================================================

class SkinTypeInfoResponse(BaseModel):
    skin_type: SkinTypeEnum
    description: str
    characteristics: list[str]
    routine_morning: list[dict[str, str]]
    routine_night: list[dict[str, str]]
    recommended_products: list[dict[str, Any]]

    model_config = {"from_attributes": True}


# ============================================================
# Feedback
# ============================================================

class FeedbackCreateRequest(BaseModel):
    rating: int = Field(..., ge=1, le=5, description="Rating 1-5 bintang")
    comment: Optional[str] = Field(None, max_length=2000)

    @field_validator("rating")
    @classmethod
    def validate_rating(cls, v: int) -> int:
        if not 1 <= v <= 5:
            raise ValueError("Rating harus antara 1 sampai 5")
        return v


class FeedbackResponse(UTCModel):
    id: str
    user_id: Optional[str] = None
    device_id: Optional[str] = None
    rating: int
    comment: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


# ============================================================
# Health Check
# ============================================================

class HealthResponse(BaseModel):
    status: str
    database: str
    model_loaded: bool
    demo_mode: bool
    version: str = "1.0.0"
