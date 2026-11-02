"""Buat tabel awal Skinly

Revision ID: 001_initial
Revises: 
Create Date: 2026-10-13 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.mysql import TINYINT, LONGTEXT

revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- Tabel skin_type_info ---
    op.create_table(
        "skin_type_info",
        sa.Column(
            "skin_type",
            sa.Enum("normal", "oily", "dry", "combination", name="skin_type_info_enum"),
            primary_key=True,
            nullable=False,
        ),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("characteristics", sa.JSON, nullable=False),
        sa.Column("routine_morning", sa.JSON, nullable=False),
        sa.Column("routine_night", sa.JSON, nullable=False),
        sa.Column("recommended_products", sa.JSON, nullable=False),
        mysql_engine="InnoDB",
        mysql_charset="utf8mb4",
        mysql_collate="utf8mb4_unicode_ci",
    )

    # --- Tabel scan_history ---
    op.create_table(
        "scan_history",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("device_id", sa.String(64), nullable=False),
        sa.Column(
            "skin_type",
            sa.Enum("normal", "oily", "dry", "combination", name="skin_type_enum"),
            nullable=False,
        ),
        sa.Column("confidence", sa.Float, nullable=False),
        sa.Column("probabilities", sa.JSON, nullable=False),
        sa.Column("image_path", sa.String(255), nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False),
        sa.Index("ix_scan_history_device_id", "device_id"),
        sa.Index("ix_scan_history_created_at", "created_at"),
        mysql_engine="InnoDB",
        mysql_charset="utf8mb4",
        mysql_collate="utf8mb4_unicode_ci",
    )

    # --- Tabel articles ---
    op.create_table(
        "articles",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column(
            "category",
            sa.Enum("jenis_kulit", "masalah_kulit", "perawatan", name="article_category_enum"),
            nullable=False,
        ),
        sa.Column("summary", sa.String(500), nullable=False),
        sa.Column("content", LONGTEXT, nullable=False),
        sa.Column("cover_image_url", sa.String(255), nullable=True),
        sa.Column("read_minutes", sa.Integer, nullable=False, server_default="3"),
        sa.Column("created_at", sa.DateTime, nullable=False),
        mysql_engine="InnoDB",
        mysql_charset="utf8mb4",
        mysql_collate="utf8mb4_unicode_ci",
    )

    # --- Tabel feedback ---
    op.create_table(
        "feedback",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("device_id", sa.String(64), nullable=False),
        sa.Column("rating", TINYINT, nullable=False),
        sa.Column("comment", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False),
        sa.Index("ix_feedback_device_id", "device_id"),
        mysql_engine="InnoDB",
        mysql_charset="utf8mb4",
        mysql_collate="utf8mb4_unicode_ci",
    )

    # Tambah index secara eksplisit (kompatibel MariaDB 10.4+)
    op.create_index("ix_scan_history_device_id", "scan_history", ["device_id"], unique=False)
    op.create_index("ix_scan_history_created_at", "scan_history", ["created_at"], unique=False)
    op.create_index("ix_feedback_device_id", "feedback", ["device_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_feedback_device_id", table_name="feedback")
    op.drop_index("ix_scan_history_created_at", table_name="scan_history")
    op.drop_index("ix_scan_history_device_id", table_name="scan_history")
    op.drop_table("feedback")
    op.drop_table("articles")
    op.drop_table("scan_history")
    op.drop_table("skin_type_info")
