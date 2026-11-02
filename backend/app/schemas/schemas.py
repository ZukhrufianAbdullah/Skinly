"""
Skinly Backend - Pydantic Schemas (Request & Response)
Menggunakan Pydantic v2
"""
from __future__ import annotations
from datetime import datetime
from typing import Optional, Any
from pydantic import BaseModel, Field, field_validator
from enum import Enum


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
    probabilities: dict[str, float]
    description: str
    routine: dict[str, list[str]]  # {"morning": [...], "night": [...]}
    products: list[str]
    demo: bool = False              # True jika model belum ada (mode demo)


# ============================================================
# Scan History
# ============================================================

class ScanCreateRequest(BaseModel):
    skin_type: SkinTypeEnum
    confidence: float = Field(..., ge=0.0, le=1.0)
    probabilities: dict[str, float]
    image_path: Optional[str] = None


class ScanResponse(BaseModel):
    id: str
    user_id: Optional[str] = None
    device_id: Optional[str] = None
    skin_type: SkinTypeEnum
    confidence: float
    probabilities: dict[str, float]
    image_path: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ScanListResponse(BaseModel):
    items: list[ScanResponse]
    total: int
    page: int
    page_size: int


# ============================================================
# Articles
# ============================================================

class ArticleListItem(BaseModel):
    id: str
    title: str
    category: ArticleCategoryEnum
    summary: str
    cover_image_url: Optional[str] = None
    read_minutes: int
    created_at: datetime

    model_config = {"from_attributes": True}


class ArticleDetail(BaseModel):
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


class FeedbackResponse(BaseModel):
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
