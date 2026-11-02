"""
Skinly - Konfigurasi pytest dan fixtures bersama
"""
import io
import os
import sys
import pytest
from PIL import Image, ImageDraw
from fastapi.testclient import TestClient

# Tambah backend root ke path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def make_fake_face_image(
    width: int = 300,
    height: int = 300,
    brightness: int = 150,
    blur: bool = False,
) -> bytes:
    """
    Buat gambar sintetis dengan wajah oval agar lolos validasi OpenCV.
    Mengembalikan bytes JPEG.
    """
    # Buat gambar dengan warna kulit
    img = Image.new("RGB", (width, height), color=(brightness, brightness // 2, brightness // 3))
    draw = ImageDraw.Draw(img)

    # Gambar oval sebagai "wajah" agar Haar Cascade bisa mendeteksinya
    face_bbox = [width // 4, height // 6, 3 * width // 4, 4 * height // 5]
    draw.ellipse(face_bbox, fill=(220, 180, 150), outline=(180, 140, 110), width=3)

    # Tambah "mata" agar lebih mirip wajah
    eye_y = height // 3
    left_eye_x = width // 3
    right_eye_x = 2 * width // 3
    draw.ellipse([left_eye_x - 10, eye_y - 8, left_eye_x + 10, eye_y + 8], fill=(50, 30, 20))
    draw.ellipse([right_eye_x - 10, eye_y - 8, right_eye_x + 10, eye_y + 8], fill=(50, 30, 20))

    # "Hidung"
    draw.ellipse([width // 2 - 8, height // 2 - 5, width // 2 + 8, height // 2 + 5], fill=(180, 140, 110))

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=85)
    return buf.getvalue()


def make_dark_image(width: int = 300, height: int = 300) -> bytes:
    """Gambar sangat gelap (gagal validasi brightness)"""
    img = Image.new("RGB", (width, height), color=(10, 10, 10))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


def make_blurry_image(width: int = 300, height: int = 300) -> bytes:
    """Gambar berwarna seragam = variance Laplacian = 0 (gagal validasi sharpness)"""
    img = Image.new("RGB", (width, height), color=(150, 120, 100))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


def make_no_face_image(width: int = 300, height: int = 300) -> bytes:
    """Gambar terang tapi tanpa wajah (gagal deteksi wajah)"""
    img = Image.new("RGB", (width, height), color=(200, 200, 200))
    # Tambah beberapa persegi acak, bukan wajah
    draw = ImageDraw.Draw(img)
    draw.rectangle([50, 50, 150, 150], fill=(100, 150, 200))
    draw.rectangle([180, 80, 260, 200], fill=(200, 100, 100))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


@pytest.fixture
def client():
    """FastAPI TestClient dengan database test (MySQL jika tersedia, fallback in-memory SQLite)"""
    os.environ["DB_NAME"] = os.environ.get("DB_TEST_NAME", "skinly_test")

    from app.main import app
    from app.core.database import get_db, check_db_connection, Base
    from app.models.models import Article, SkinTypeInfo
    from app.ml import inference

    # Pastikan mode demo aktif untuk testing
    inference._demo_mode = True
    inference._model = None

    if not check_db_connection():
        # Fallback ke SQLite in-memory untuk testing offline
        from sqlalchemy import create_engine
        from sqlalchemy.orm import sessionmaker
        from sqlalchemy.pool import StaticPool

        test_engine = create_engine(
            "sqlite:///:memory:",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        Base.metadata.create_all(test_engine)
        TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

        # Seed data minimal untuk artikel dan jenis kulit agar test query berhasil
        with TestingSession() as seed_db:
            info = SkinTypeInfo(
                skin_type="normal",
                description="Kulit seimbang dan normal.",
                characteristics=["Pori-pori kecil", "Tekstur halus"],
                routine_morning=["Pembersih lembut", "Moisturizer", "Sunscreen SPF 30+"],
                routine_night=["Double cleansing", "Hydrating toner", "Night cream"],
                recommended_products=["Gentle cleanser", "Hyaluronic acid", "Ceramide cream"],
            )
            art = Article(
                id="art-test-1",
                title="Kenali Jenis Kulit Wajah",
                category="jenis_kulit",
                summary="Panduan singkat mengenali 4 jenis kulit wajah.",
                content="Isi lengkap artikel edukasi mengenai jenis kulit normal, oily, dry, combination.",
                read_minutes=3,
            )
            seed_db.add(info)
            seed_db.add(art)
            seed_db.commit()

        def override_get_db():
            db = TestingSession()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = override_get_db
        with TestClient(app) as c:
            yield c
        app.dependency_overrides.pop(get_db, None)
    else:
        with TestClient(app) as c:
            yield c
