"""
Skinly Backend - Auth Schemas
Pydantic model untuk registrasi, login, dan respons profil
"""
import re
from datetime import datetime
from pydantic import BaseModel, Field, field_validator


class UserRegisterRequest(BaseModel):
    username: str = Field(..., min_length=4, max_length=50, description="Username unik minimal 4 karakter tanpa spasi")
    name: str = Field(..., min_length=1, max_length=100, description="Nama lengkap")
    email: str = Field(..., max_length=120, description="Email aktif")
    password: str = Field(..., min_length=8, max_length=100, description="Password minimal 8 karakter")

    @field_validator("username")
    @classmethod
    def validate_username(cls, v: str) -> str:
        v_clean = v.strip().lower()
        if len(v_clean) < 4:
            raise ValueError("Username minimal 4 karakter.")
        if not re.match(r"^[a-zA-Z0-9_]+$", v_clean):
            raise ValueError("Username hanya boleh berisi huruf, angka, dan underscore (tanpa spasi).")
        return v_clean

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        v_clean = v.strip().lower()
        if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", v_clean):
            raise ValueError("Format email tidak valid.")
        return v_clean

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password minimal 8 karakter.")
        return v


class UserLoginRequest(BaseModel):
    email: str = Field(..., description="Email atau username")
    password: str = Field(..., description="Password akun")

    @field_validator("email")
    @classmethod
    def clean_email(cls, v: str) -> str:
        return v.strip().lower()


class UserResponse(BaseModel):
    id: str
    username: str
    name: str
    email: str
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
