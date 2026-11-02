"""
Skinly Backend - Alembic env.py
Konfigurasi migrasi database dengan SQLAlchemy
"""
import os
import sys
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

# Tambah backend root ke path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import settings dan models
from app.core.config import get_settings
from app.core.database import Base

# Import semua model agar Alembic menemukannya
from app.models.models import ScanHistory, Article, SkinTypeInfo, Feedback  # noqa: F401

settings = get_settings()

# Konfigurasi Alembic dari alembic.ini
config = context.config

# Timpa URL database dari settings (agar .env digunakan)
config.set_main_option("sqlalchemy.url", settings.database_url)

# Setup logging dari alembic.ini jika tersedia
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Jalankan migrasi dalam mode offline (tanpa koneksi DB)"""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Jalankan migrasi dalam mode online (dengan koneksi DB)"""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
