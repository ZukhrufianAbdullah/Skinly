"""
Skinly Backend - Settings & Konfigurasi
Dibaca dari file .env
"""
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # --- Database ---
    db_host: str = "127.0.0.1"
    db_port: int = 3306
    db_user: str = "root"
    db_password: str = ""
    db_name: str = "skinly"
    db_test_name: str = "skinly_test"

    # --- Upload ---
    max_upload_size_mb: int = 8
    allowed_extensions: str = "jpg,jpeg,png,webp"
    upload_dir: str = "uploads"

    # --- Validasi Citra ---
    min_brightness: float = 40.0
    min_sharpness: float = 80.0
    face_detection_enabled: bool = True

    # --- Model ML ---
    model_path: str = "app/ml/skin_model.keras"
    class_names_path: str = "app/ml/class_names.json"

    # --- Aplikasi ---
    app_env: str = "development"
    allowed_origins: str = "*"

    # --- Autentikasi / JWT ---
    jwt_secret_key: str = "skinly-secret-key-change-in-production-2026"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 10080  # 7 hari

    @property
    def database_url(self) -> str:
        return (
            f"mysql+pymysql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
            f"?charset=utf8mb4"
        )

    @property
    def test_database_url(self) -> str:
        return (
            f"mysql+pymysql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_test_name}"
            f"?charset=utf8mb4"
        )

    @property
    def max_upload_size_bytes(self) -> int:
        return self.max_upload_size_mb * 1024 * 1024

    @property
    def allowed_extensions_list(self) -> list[str]:
        return [ext.strip().lower() for ext in self.allowed_extensions.split(",")]

    @property
    def origins_list(self) -> list[str]:
        if self.allowed_origins == "*":
            return ["*"]
        return [o.strip() for o in self.allowed_origins.split(",")]


@lru_cache()
def get_settings() -> Settings:
    return Settings()
