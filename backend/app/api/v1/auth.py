"""
Skinly Backend - Auth Endpoints
POST /api/v1/auth/register
POST /api/v1/auth/login
GET  /api/v1/auth/me
"""
import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token
from app.models.models import User
from app.schemas.auth import (
    UserRegisterRequest,
    UserLoginRequest,
    UserResponse,
    TokenResponse,
)
from app.api.deps import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrasi Akun Baru",
)
def register(
    data: UserRegisterRequest,
    db: Session = Depends(get_db),
):
    """Mendaftar akun baru dan langsung menghasilkan access token JWT"""
    # Cek apakah email sudah terdaftar
    existing_email = db.query(User).filter(User.email == data.email).first()
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "EMAIL_EXISTS", "message": "Email sudah terdaftar. Silakan login atau gunakan email lain."}},
        )

    # Cek apakah username sudah dipakai
    existing_username = db.query(User).filter(User.username == data.username).first()
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "USERNAME_EXISTS", "message": "Username sudah digunakan. Pilih username lain."}},
        )

    # Buat user baru
    user = User(
        username=data.username,
        name=data.name.strip(),
        email=data.email,
        password_hash=hash_password(data.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    logger.info(f"User baru terdaftar: id={user.id}, username={user.username}")

    token = create_access_token(
        subject=user.id,
        extra_data={"username": user.username, "email": user.email},
    )

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
    )


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Login Pengguna",
)
def login(
    data: UserLoginRequest,
    db: Session = Depends(get_db),
):
    """Login dengan email (atau username) dan password"""
    login_id = data.email.strip().lower()
    user = (
        db.query(User)
        .filter((User.email == login_id) | (User.username == login_id))
        .first()
    )

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_CREDENTIALS", "message": "Email atau password salah."}},
        )

    token = create_access_token(
        subject=user.id,
        extra_data={"username": user.username, "email": user.email},
    )

    logger.info(f"User login berhasil: id={user.id}, username={user.username}")

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
    )


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Data Profil User Saat Ini",
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    """Mendapatkan profil pengguna yang sedang login berdasarkan token JWT"""
    return UserResponse.model_validate(current_user)
