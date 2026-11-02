"""
Test autentikasi pengguna dan isolasi data per akun
"""
import uuid
import pytest
from fastapi.testclient import TestClient


def register_user(client: TestClient, username: str = None, email: str = None, password: str = "password123"):
    u = username or f"user_{uuid.uuid4().hex[:8]}"
    e = email or f"{u}@skinly.test"
    payload = {
        "username": u,
        "name": f"User {u}",
        "email": e,
        "password": password,
    }
    resp = client.post("/api/v1/auth/register", json=payload)
    return resp, u, e, password


class TestAuthEndpoints:
    def test_register_success(self, client: TestClient):
        resp, username, email, _ = register_user(client)
        assert resp.status_code == 201
        data = resp.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert data["user"]["username"] == username
        assert data["user"]["email"] == email

    def test_register_duplicate_email(self, client: TestClient):
        _, _, email, _ = register_user(client)
        # Coba daftar lagi dengan email yang sama tapi username beda
        resp, _, _, _ = register_user(client, username=f"other_{uuid.uuid4().hex[:6]}", email=email)
        assert resp.status_code == 409
        assert resp.json()["detail"]["error"]["code"] == "EMAIL_EXISTS"

    def test_register_duplicate_username(self, client: TestClient):
        _, username, _, _ = register_user(client)
        # Coba daftar lagi dengan username yang sama tapi email beda
        resp, _, _, _ = register_user(client, username=username, email=f"other_{uuid.uuid4().hex[:6]}@skinly.test")
        assert resp.status_code == 409
        assert resp.json()["detail"]["error"]["code"] == "USERNAME_EXISTS"

    def test_register_invalid_data(self, client: TestClient):
        # Username terlalu pendek (< 4 char)
        resp = client.post("/api/v1/auth/register", json={
            "username": "abc",
            "name": "Testing",
            "email": "abc@skinly.test",
            "password": "password123",
        })
        assert resp.status_code == 422

        # Password terlalu pendek (< 8 char)
        resp2 = client.post("/api/v1/auth/register", json={
            "username": "valid_user",
            "name": "Testing",
            "email": "valid@skinly.test",
            "password": "123",
        })
        assert resp2.status_code == 422

    def test_login_success(self, client: TestClient):
        _, _, email, password = register_user(client)
        resp = client.post("/api/v1/auth/login", json={
            "email": email,
            "password": password,
        })
        assert resp.status_code == 200
        data = resp.json()
        assert "access_token" in data
        assert data["user"]["email"] == email

    def test_login_wrong_password(self, client: TestClient):
        _, _, email, _ = register_user(client)
        resp = client.post("/api/v1/auth/login", json={
            "email": email,
            "password": "wrongpassword123",
        })
        assert resp.status_code == 401
        assert resp.json()["detail"]["error"]["code"] == "INVALID_CREDENTIALS"

    def test_get_me(self, client: TestClient):
        reg_resp, username, email, _ = register_user(client)
        token = reg_resp.json()["access_token"]

        # Request tanpa token
        unauth_resp = client.get("/api/v1/auth/me")
        assert unauth_resp.status_code == 401

        # Request dengan token valid
        auth_resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
        assert auth_resp.status_code == 200
        assert auth_resp.json()["username"] == username
        assert auth_resp.json()["email"] == email


class TestUserDataIsolation:
    def test_user_cannot_access_other_user_scan(self, client: TestClient):
        # User A daftar dan simpan scan
        resp_a, _, _, _ = register_user(client)
        token_a = resp_a.json()["access_token"]
        headers_a = {"Authorization": f"Bearer {token_a}"}

        scan_payload = {
            "skin_type": "oily",
            "confidence": 0.88,
            "probabilities": {"normal": 0.05, "oily": 0.88, "dry": 0.03, "combination": 0.04},
        }
        create_resp = client.post("/api/v1/scans", json=scan_payload, headers=headers_a)
        assert create_resp.status_code == 201
        scan_id = create_resp.json()["id"]

        # User B daftar
        resp_b, _, _, _ = register_user(client)
        token_b = resp_b.json()["access_token"]
        headers_b = {"Authorization": f"Bearer {token_b}"}

        # User B mencoba membaca scan milik User A -> 404
        get_b_resp = client.get(f"/api/v1/scans/{scan_id}", headers=headers_b)
        assert get_b_resp.status_code == 404

        # User B list scans -> tidak ada scan milik User A
        list_b_resp = client.get("/api/v1/scans", headers=headers_b)
        assert list_b_resp.status_code == 200
        scan_ids = [item["id"] for item in list_b_resp.json()["items"]]
        assert scan_id not in scan_ids

        # User B mencoba menghapus scan milik User A -> 404
        del_b_resp = client.delete(f"/api/v1/scans/{scan_id}", headers=headers_b)
        assert del_b_resp.status_code == 404

        # User A masih bisa mengakses scannya
        get_a_resp = client.get(f"/api/v1/scans/{scan_id}", headers=headers_a)
        assert get_a_resp.status_code == 200
        assert get_a_resp.json()["id"] == scan_id
