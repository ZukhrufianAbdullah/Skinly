"""Tambah tabel users dan autentikasi

Revision ID: 002_add_users_and_auth
Revises: 001_initial
Create Date: 2026-10-19 22:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "002_add_users_and_auth"
down_revision: Union[str, None] = "001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Buat tabel users
    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("username", sa.String(50), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("email", sa.String(120), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("created_at", sa.DateTime, nullable=False),
        mysql_engine="InnoDB",
        mysql_charset="utf8mb4",
        mysql_collate="utf8mb4_unicode_ci",
    )
    op.create_index("ix_users_username", "users", ["username"], unique=True)
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    # 2. Tambah user_id ke scan_history & jadikan device_id nullable
    op.add_column("scan_history", sa.Column("user_id", sa.String(36), nullable=True))
    op.create_index("ix_scan_history_user_id", "scan_history", ["user_id"], unique=False)
    op.create_foreign_key(
        "fk_scan_history_user_id",
        "scan_history",
        "users",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.alter_column(
        "scan_history",
        "device_id",
        existing_type=sa.String(64),
        nullable=True,
    )

    # 3. Tambah user_id ke feedback & jadikan device_id nullable
    op.add_column("feedback", sa.Column("user_id", sa.String(36), nullable=True))
    op.create_index("ix_feedback_user_id", "feedback", ["user_id"], unique=False)
    op.create_foreign_key(
        "fk_feedback_user_id",
        "feedback",
        "users",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.alter_column(
        "feedback",
        "device_id",
        existing_type=sa.String(64),
        nullable=True,
    )


def downgrade() -> None:
    # Hapus FK dan kolom dari feedback
    op.drop_constraint("fk_feedback_user_id", "feedback", type_="foreignkey")
    op.drop_index("ix_feedback_user_id", table_name="feedback")
    op.drop_column("feedback", "user_id")
    op.alter_column(
        "feedback",
        "device_id",
        existing_type=sa.String(64),
        nullable=False,
    )

    # Hapus FK dan kolom dari scan_history
    op.drop_constraint("fk_scan_history_user_id", "scan_history", type_="foreignkey")
    op.drop_index("ix_scan_history_user_id", table_name="scan_history")
    op.drop_column("scan_history", "user_id")
    op.alter_column(
        "scan_history",
        "device_id",
        existing_type=sa.String(64),
        nullable=False,
    )

    # Hapus tabel users
    op.drop_index("ix_users_email", table_name="users")
    op.drop_index("ix_users_username", table_name="users")
    op.drop_table("users")
