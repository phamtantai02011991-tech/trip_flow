"""Smoke test cho các module mới (trips, places, expenses) và các chốt bảo mật.

Bộ test này bổ sung cho `test_api.py` (vốn chỉ phủ module catalog/crawler):
- Module 1/6/7: tạo chuyến, thêm điểm dừng, ghi chi phí, xem ngân sách.
- Module 5: `/places/nearby` trả dữ liệu catalog.
- Bảo mật: itinerary bắt buộc đăng nhập và chặn IDOR giữa hai người dùng.
"""

import uuid

from fastapi.testclient import TestClient

from app.db.seed_db import init_and_seed_db
from app.main import app

init_and_seed_db()
client = TestClient(app)


def _register() -> dict:
    suffix = uuid.uuid4().hex[:10]
    resp = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"smoke_{suffix}@tripflow.vn",
            "full_name": f"Smoke {suffix[:4]}",
            "password": "SmokeTest@12345",
        },
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    return {"Authorization": f"Bearer {body['access_token']}"}


def test_health_and_readiness():
    assert client.get("/health").status_code == 200
    ready = client.get("/health/ready")
    assert ready.status_code == 200
    assert ready.json()["database"] == "ok"


def test_trips_crud_and_expenses_flow():
    headers = _register()

    created = client.post(
        "/api/v1/trips",
        headers=headers,
        json={
            "title": "Chuyến thử nghiệm Đà Nẵng",
            "origin_name": "TP. Hồ Chí Minh",
            "origin_lat": 10.7769,
            "origin_lng": 106.7009,
            "destination_name": "TP. Đà Nẵng",
            "destination_lat": 16.0544,
            "destination_lng": 108.2022,
            "total_days": 2,
            "party_size": 2,
            "vehicle": "motorbike",
            "budget_level": "balanced",
            "budget_amount": 3000000,
            "preferences": ["food", "sightseeing"],
        },
    )
    assert created.status_code == 201, created.text
    trip = created.json()
    trip_id = trip["id"]
    assert len(trip["days"]) == 2

    listed = client.get("/api/v1/trips", headers=headers)
    assert listed.status_code == 200
    assert any(t["id"] == trip_id for t in listed.json())

    stop = client.post(
        f"/api/v1/trips/{trip_id}/days/1/stops",
        headers=headers,
        json={
            "name": "Bánh mì Huỳnh Hoa",
            "address": "26 Lê Thị Riêng, Quận 1",
            "lat": 10.7756,
            "lng": 106.6907,
            "kind": "restaurant",
            "stay_mins": 45,
            "est_cost": 70000,
        },
    )
    assert stop.status_code == 201, stop.text
    stop_id = stop.json()["days"][0]["stops"][0]["id"]

    expense = client.post(
        f"/api/v1/trips/{trip_id}/expenses",
        headers=headers,
        json={"title": "Vé tham quan", "amount": 120000, "category": "ticket"},
    )
    assert expense.status_code == 201, expense.text

    budget = client.get(f"/api/v1/trips/{trip_id}/budget-summary", headers=headers)
    assert budget.status_code == 200
    assert budget.json()["budget_amount"] == 3000000
    assert budget.json()["by_category"]["ticket"] == 120000

    removed = client.delete(f"/api/v1/trips/{trip_id}/stops/{stop_id}", headers=headers)
    assert removed.status_code == 200
    assert removed.json()["days"][0]["stops"] == []

    deleted = client.delete(f"/api/v1/trips/{trip_id}", headers=headers)
    assert deleted.status_code == 204
    assert client.get(f"/api/v1/trips/{trip_id}", headers=headers).status_code == 404


def test_itinerary_requires_auth_and_blocks_idor():
    # Khách chưa đăng nhập chỉ thấy lịch trình mẫu, không tạo được.
    guest_list = client.get("/api/v1/itineraries")
    assert guest_list.status_code == 200
    assert all(item["is_template"] for item in guest_list.json())

    guest_create = client.post(
        "/api/v1/itineraries",
        json={"province_id": 1, "title": "Lịch trình của khách", "total_days": 1, "stops": []},
    )
    assert guest_create.status_code == 401

    owner = _register()
    intruder = _register()

    created = client.post(
        "/api/v1/itineraries",
        headers=owner,
        json={
            "province_id": 1,
            "title": "Lịch trình riêng tư",
            "description": "Chỉ chủ sở hữu được xem",
            "total_days": 1,
            "stops": [],
        },
    )
    assert created.status_code == 201, created.text
    itinerary_id = created.json()["id"]

    assert client.get(f"/api/v1/itineraries/{itinerary_id}", headers=owner).status_code == 200
    # Người khác phải nhận 404, không lộ dữ liệu.
    assert client.get(f"/api/v1/itineraries/{itinerary_id}", headers=intruder).status_code == 404
    assert (
        client.put(
            f"/api/v1/itineraries/{itinerary_id}",
            headers=intruder,
            json={"title": "Chiếm đoạt lịch trình"},
        ).status_code
        == 404
    )
    assert client.delete(f"/api/v1/itineraries/{itinerary_id}", headers=intruder).status_code == 404

    deleted = client.delete(f"/api/v1/itineraries/{itinerary_id}", headers=owner)
    assert deleted.status_code == 204


def test_places_nearby_returns_catalog_data():
    resp = client.get(
        "/api/v1/places/nearby",
        params={"lat": 10.7769, "lng": 106.7009, "radius_km": 5, "kinds": "food,sight"},
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    # API giới hạn số item trả về (limit) trong khi total là tổng số khớp.
    assert body["total"] >= len(body["items"])
    assert len(body["items"]) <= 40
    assert body["total"] >= 1
    assert body["source"] in {"catalog", "goong", "mixed"}


def test_guest_trips_are_scoped_to_device():
    """Chuyến của khách vãng lai chỉ mở cho đúng thiết bị (X-Guest-Token)."""
    device_a = f"device-{uuid.uuid4().hex}"
    device_b = f"device-{uuid.uuid4().hex}"

    created = client.post(
        "/api/v1/trips",
        headers={"X-Guest-Token": device_a},
        json={
            "title": "Chuyến khách vãng lai",
            "origin_name": "Hà Nội",
            "origin_lat": 21.0285,
            "origin_lng": 105.8542,
            "total_days": 1,
            "party_size": 1,
        },
    )
    assert created.status_code == 201, created.text
    trip_id = created.json()["id"]

    assert (
        client.get(f"/api/v1/trips/{trip_id}", headers={"X-Guest-Token": device_b}).status_code
        == 404
    )
    assert (
        client.get(f"/api/v1/trips/{trip_id}", headers={"X-Guest-Token": device_a}).status_code
        == 200
    )

    listed_b = client.get("/api/v1/trips", headers={"X-Guest-Token": device_b}).json()
    assert all(t["id"] != trip_id for t in listed_b)
    listed_a = client.get("/api/v1/trips", headers={"X-Guest-Token": device_a}).json()
    assert any(t["id"] == trip_id for t in listed_a)

    assert (
        client.delete(f"/api/v1/trips/{trip_id}", headers={"X-Guest-Token": device_b}).status_code
        == 404
    )
    assert (
        client.delete(f"/api/v1/trips/{trip_id}", headers={"X-Guest-Token": device_a}).status_code
        == 204
    )


def test_otp_response_never_leaks_code_by_default():
    phone = "09" + f"{uuid.uuid4().int % 100000000:08d}"
    resp = client.post(
        "/api/v1/auth/otp/send",
        json={"phone": phone, "full_name": "Kiểm thử OTP"},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json().get("debug_otp") is None
