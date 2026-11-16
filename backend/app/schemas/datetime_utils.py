"""Helper serialisasi datetime untuk respons API.

Database menyimpan waktu dalam UTC tanpa timezone (naive). Jika Pydantic
men-serialisasi apa adanya, klien akan membaca string tanpa penanda zona
waktu dan menganggapnya sebagai waktu lokal (mis. WIB), sehingga tampilan
riwayat bisa meleset beberapa jam. Helper ini memastikan semua timestamp
dikirim sebagai ISO 8601 UTC dengan penanda "Z".
"""

from __future__ import annotations

from datetime import datetime, timezone


def serialize_utc(value: datetime) -> str:
    """Serialisasi datetime sebagai ISO 8601 UTC (contoh: 2026-11-16T05:12:00Z)."""
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
