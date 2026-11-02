"""
Skinly Backend - API Dependencies
get_db & get_current_user
"""
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.models import User

# HTTPBearer untuk mengambil token Bearer dari header Authorization
security_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Dependency untuk mendapatkan user saat ini dari header Authorization: Bearer <token>"""
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "UNAUTHORIZED", "message": "Autentikasi diperlukan. Silakan login terlebih dahulu."}},
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    payload = decode_access_token(token)
    if payload is None or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_TOKEN", "message": "Token tidak valid atau sudah kedaluwarsa."}},
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload["sub"]
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "USER_NOT_FOUND", "message": "Pengguna tidak ditemukan."}},
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user


def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
    db: Session = Depends(get_db),
) -> Optional[User]:
    """Dependency opsional: mengembalikan User jika token Bearer valid, atau None jika tanpa token"""
    if credentials is None or not credentials.credentials:
        return None

    token = credentials.credentials
    payload = decode_access_token(token)
    if payload is None or "sub" not in payload:
        return None

    user_id = payload["sub"]
    return db.query(User).filter(User.id == user_id).first()
