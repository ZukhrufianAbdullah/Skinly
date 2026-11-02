"""
Test endpoint scan history, feedback, dan articles
Menggunakan database test dan autentikasi token Bearer
"""
import os
import uuid
import pytest
from fastapi.testclient import TestClient

# Set test DB sebelum import app
os.environ.setdefault("DB_NAME", "skinly_test")


@pytest.fixture
def auth_headers(client: TestClient) -> dict[str, str]:
    """Helper fixture untuk mendaftarkan user dan mengembalikan header Authorization"""
    uid = uuid.uuid4().hex[:8]
    resp = client.post(
        "/api/v1/auth/register",
        json={
            "username": f"testuser_{uid}",
            "name": f"Test User {uid}",
            "email": f"test_{uid}@skinly.test",
            "password": "password123",
        },
    )
    assert resp.status_code == 201
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


class TestHealthEndpoint:
    def test_health_check(self, client: TestClient):
        resp = client.get("/api/v1/health")
        assert resp.status_code == 200
        data = resp.json()
        assert "status" in data
        assert "database" in data
        assert "demo_mode" in data


class TestScanHistoryEndpoints:
    def test_list_scans_empty(self, client: TestClient, auth_headers: dict[str, str]):
        """GET /scans mengembalikan list kosong untuk user baru"""
        resp = client.get("/api/v1/scans", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert "items" in data
        assert isinstance(data["items"], list)

    def test_save_and_retrieve_scan(self, client: TestClient, auth_headers: dict[str, str]):
        """POST /scans lalu GET /scans/{id}"""
        payload = {
            "skin_type": "oily",
            "confidence": 0.87,
            "probabilities": {
                "normal": 0.05,
                "oily": 0.87,
                "dry": 0.03,
                "combination": 0.05,
            },
        }
        # Simpan
        resp = client.post("/api/v1/scans", json=payload, headers=auth_headers)
        assert resp.status_code == 201
        scan = resp.json()
        assert scan["skin_type"] == "oily"
        assert scan["confidence"] == pytest.approx(0.87, abs=0.01)
        scan_id = scan["id"]

        # Ambil detail
        resp2 = client.get(f"/api/v1/scans/{scan_id}", headers=auth_headers)
        assert resp2.status_code == 200
        assert resp2.json()["id"] == scan_id

    def test_list_scans_after_save(self, client: TestClient, auth_headers: dict[str, str]):
        """Setelah save, list scans harus berisi data"""
        payload = {
            "skin_type": "dry",
            "confidence": 0.75,
            "probabilities": {"normal": 0.10, "oily": 0.05, "dry": 0.75, "combination": 0.10},
        }
        client.post("/api/v1/scans", json=payload, headers=auth_headers)

        resp = client.get("/api/v1/scans", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] >= 1

    def test_delete_scan(self, client: TestClient, auth_headers: dict[str, str]):
        """DELETE /scans/{id} menghapus data"""
        payload = {
            "skin_type": "normal",
            "confidence": 0.92,
            "probabilities": {"normal": 0.92, "oily": 0.03, "dry": 0.03, "combination": 0.02},
        }
        resp = client.post("/api/v1/scans", json=payload, headers=auth_headers)
        scan_id = resp.json()["id"]

        # Hapus
        del_resp = client.delete(f"/api/v1/scans/{scan_id}", headers=auth_headers)
        assert del_resp.status_code == 204

        # Verifikasi sudah tidak ada
        get_resp = client.get(f"/api/v1/scans/{scan_id}", headers=auth_headers)
        assert get_resp.status_code == 404

    def test_missing_auth(self, client: TestClient):
        """Request tanpa token Authorization ditolak dengan 401"""
        resp = client.get("/api/v1/scans")
        assert resp.status_code == 401

    def test_scan_not_found(self, client: TestClient, auth_headers: dict[str, str]):
        """Scan ID yang tidak ada mengembalikan 404"""
        resp = client.get("/api/v1/scans/nonexistent-id-xyz", headers=auth_headers)
        assert resp.status_code == 404


class TestFeedbackEndpoint:
    def test_submit_valid_feedback(self, client: TestClient, auth_headers: dict[str, str]):
        """POST /feedback dengan rating valid"""
        payload = {"rating": 4, "comment": "Aplikasi sangat membantu!"}
        resp = client.post("/api/v1/feedback", json=payload, headers=auth_headers)
        assert resp.status_code == 201
        data = resp.json()
        assert data["rating"] == 4
        assert data["comment"] == "Aplikasi sangat membantu!"

    def test_feedback_rating_boundary(self, client: TestClient, auth_headers: dict[str, str]):
        """Rating 1 dan 5 valid"""
        for rating in [1, 5]:
            resp = client.post(
                "/api/v1/feedback", json={"rating": rating}, headers=auth_headers
            )
            assert resp.status_code == 201

    def test_feedback_invalid_rating(self, client: TestClient, auth_headers: dict[str, str]):
        """Rating di luar 1-5 ditolak"""
        for rating in [0, 6, -1]:
            resp = client.post(
                "/api/v1/feedback", json={"rating": rating}, headers=auth_headers
            )
            assert resp.status_code == 422

    def test_feedback_no_comment(self, client: TestClient, auth_headers: dict[str, str]):
        """Feedback tanpa komentar valid"""
        resp = client.post(
            "/api/v1/feedback", json={"rating": 3}, headers=auth_headers
        )
        assert resp.status_code == 201


class TestArticlesEndpoint:
    def test_list_articles(self, client: TestClient, auth_headers: dict[str, str]):
        """GET /articles mengembalikan list"""
        resp = client.get("/api/v1/articles", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert "items" in data
        assert "total" in data

    def test_article_not_found(self, client: TestClient, auth_headers: dict[str, str]):
        """Artikel tidak ada mengembalikan 404"""
        resp = client.get("/api/v1/articles/nonexistent-id", headers=auth_headers)
        assert resp.status_code == 404
