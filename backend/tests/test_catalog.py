"""Kiểm tra tính toàn vẹn của catalog dữ liệu thật (OSM/Wikipedia/Wikimedia)."""

import json
from pathlib import Path

from fastapi.testclient import TestClient

from app.db.seed_db import init_and_seed_db
from app.main import app

CATALOG_PATH = Path(__file__).resolve().parents[1] / "app" / "data" / "catalog_extra.json"

init_and_seed_db()
client = TestClient(app)


def _records() -> list[dict]:
    return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))["records"]


def test_catalog_integrity_and_licenses():
    records = _records()
    assert len(records) >= 120, "Catalog phải có tối thiểu 120 địa điểm/quán đã kiểm chứng"
    assert len({r["key"] for r in records}) == len(records), "Key bị trùng"

    for record in records:
        # Toạ độ phải nằm trong lãnh thổ Việt Nam.
        assert 8.0 <= record["lat"] <= 24.0, record["name"]
        assert 102.0 <= record["lng"] <= 110.0, record["name"]
        assert record["province_code"] in {
            "HN", "DN", "HCM", "QN", "LC", "HUE", "QNA", "KH", "LD", "KG",
        }, record["name"]

        image = record.get("image")
        if image:
            assert image.get("url", "").startswith("http"), record["name"]
            assert image.get("thumb_url", "").startswith("http"), record["name"]
            assert image.get("license"), f"Thiếu giấy phép ảnh: {record['name']}"
            assert image.get("source_url", "").startswith("http"), record["name"]

    with_images = sum(1 for r in records if r.get("image"))
    assert with_images >= 90, f"Chỉ có {with_images} ảnh hợp lệ"


def test_catalog_is_seeded_and_served_with_images():
    expected_min = {1: 30, 2: 22, 3: 28}  # HCM, ĐN, HN
    for province_id, minimum in expected_min.items():
        data = client.get(
            "/api/v1/destinations",
            params={"province_id": province_id, "page_size": 100},
        ).json()
        assert data["total"] >= minimum, (province_id, data["total"])

    hanoi_food = client.get("/api/v1/restaurants", params={"province_id": 3}).json()
    assert len(hanoi_food) >= 14
    assert any(r.get("thumbnail_url") for r in hanoi_food)


def test_all_10_provinces_have_destinations():
    for province_id in range(1, 11):
        data = client.get(
            "/api/v1/destinations",
            params={"province_id": province_id, "page_size": 100},
        ).json()
        assert data["total"] >= 5, (province_id, data["total"])


def test_all_10_provinces_have_restaurants():
    for province_id in range(1, 11):
        data = client.get("/api/v1/restaurants", params={"province_id": province_id}).json()
        assert len(data) >= 2, (province_id, len(data))


def test_rest_stops_nearby_include_cafes_and_parks():
    resp = client.get(
        "/api/v1/places/nearby",
        params={"lat": 21.0288, "lng": 105.8525, "radius_km": 3, "kinds": "rest"},
    )
    assert resp.status_code == 200, resp.text
    items = resp.json()["items"]
    assert len(items) >= 3
    assert all(item["kind"] == "rest" for item in items)
    assert any(item.get("stop_category") in {"cafe", "viewpoint"} for item in items)


def test_suggest_is_accent_insensitive():
    body = client.get("/api/v1/places/suggest", params={"q": "hoi an"}).json()
    assert isinstance(body, list) and body
    assert any("Hội An" in item["name"] for item in body)

    body2 = client.get("/api/v1/places/suggest", params={"q": "bun cha"}).json()
    assert any("Bún" in item["name"] for item in body2)


def test_along_route_returns_rest_stops():
    resp = client.post(
        "/api/v1/places/along-route",
        json={
            "origin_lat": 21.0288,
            "origin_lng": 105.8525,
            "dest_lat": 21.0288,
            "dest_lng": 105.8359,
            "corridor_radius_km": 2.0,
            "kinds": "rest,gas,ev,cafe",
        },
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["count"] >= 1
    for stop in body["stops"]:
        assert stop["distance_from_route_km"] <= 2.0
        assert stop["kind"] in {"rest", "gas", "ev", "cafe"}
        assert 0 <= stop["route_progress_pct"] <= 100


def test_gas_and_ev_nearby_from_osm():
    gas = client.get(
        "/api/v1/places/nearby",
        params={"lat": 21.0288, "lng": 105.8525, "radius_km": 6, "kinds": "gas"},
    ).json()
    assert gas["total"] >= 1
    assert all(item["kind"] == "gas" for item in gas["items"])
    assert any(item.get("stop_category") == "fuel" for item in gas["items"])

    ev = client.get(
        "/api/v1/places/nearby",
        params={"lat": 21.0288, "lng": 105.8525, "radius_km": 10, "kinds": "ev"},
    ).json()
    assert ev["total"] >= 1
    assert all(item["kind"] == "ev" for item in ev["items"])


def test_nearby_returns_images_for_real_places():
    resp = client.get(
        "/api/v1/places/nearby",
        params={"lat": 21.0288, "lng": 105.8525, "radius_km": 3, "kinds": "food,sight"},
    )
    assert resp.status_code == 200, resp.text
    items = resp.json()["items"]
    assert items
    assert any(item.get("thumbnail_url") for item in items)
