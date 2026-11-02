"""
Skinly Backend - Endpoint Feedback
POST /api/v1/feedback  -> kirim rating & komentar (terikat akun user)
"""
import logging
import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.models import Feedback, User
from app.schemas.schemas import FeedbackCreateRequest, FeedbackResponse
from app.api.deps import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/feedback", tags=["Feedback"])


@router.post(
    "",
    response_model=FeedbackResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Kirim rating dan ulasan kepuasan pengguna",
)
def submit_feedback(
    request: FeedbackCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    fb = Feedback(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        rating=request.rating,
        comment=request.comment,
        created_at=datetime.now(timezone.utc).replace(tzinfo=None),
    )
    db.add(fb)
    db.commit()
    db.refresh(fb)
    logger.info(f"Feedback diterima: rating={request.rating} | user_id={current_user.id}")
    return fb
