"""
Skinly Backend - Endpoint Articles
GET /api/v1/articles         -> daftar artikel (filter kategori)
GET /api/v1/articles/{id}    -> detail artikel
"""
import logging
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.models import Article, User
from app.schemas.schemas import ArticleListResponse, ArticleDetail
from app.api.deps import get_current_user_optional

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/articles", tags=["Knowledge"])


@router.get(
    "",
    response_model=ArticleListResponse,
    summary="Daftar artikel edukasi kulit",
)
def list_articles(
    category: str = Query(None, description="Filter: jenis_kulit | masalah_kulit | perawatan"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: Session = Depends(get_db),
):
    query = db.query(Article).order_by(Article.created_at.desc())
    if category:
        query = query.filter(Article.category == category)
    total = query.count()
    items = query.offset((page - 1) * page_size).limit(page_size).all()
    return ArticleListResponse(items=items, total=total)


@router.get(
    "/{article_id}",
    response_model=ArticleDetail,
    summary="Detail isi artikel",
)
def get_article(
    article_id: str,
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: Session = Depends(get_db),
):
    article = db.query(Article).filter(Article.id == article_id).first()
    if not article:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Artikel tidak ditemukan."}}
        )
    return article
