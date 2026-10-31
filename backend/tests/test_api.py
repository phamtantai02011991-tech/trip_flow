"""
Bộ kiểm thử tự động (Pytest) cho hệ thống TripFlow Backend API + Module AI Data Ingestion (Google Maps Crawler).
Kiểm tra đầy đủ các tiêu chí:
- TC-01: Danh sách tỉnh/thành & 10+ địa điểm chất lượng cao tại TP.HCM & Đà Nẵng (`seed_db.py`)
- TC-02: Tối ưu ảnh Cloudinary CDN (`c_fill,w_400,h_300,q_auto,f_auto` & `w_1200,q_auto,f_auto`)
- TC-03: Phân quyền RBAC dựa trên bảng `Role`, `Permission`, `RolePermissionLink` (`SQLModel`)
- TC-04: Tìm nhà hàng dọc lộ trình bằng Goong Encoded Polyline + Bounding Box SQL + `Shapely` (`LineString`, `Point`)
- TC-05: Giới hạn Request (Rate Limiting `slowapi` 10 lần/phút/IP trả về `429 Too Many Requests`)
- TC-06: Đồng bộ lịch trình Offline-first (`/api/v1/itineraries/sync`)
- TC-07: Xuất hợp đồng OpenAPI 3.1 (`swagger.json`)
- TC-09: CLI Crawler Test (`scripts/run_crawler_cli.py`) & Normalizer (`is_valid_vn_location`, `clean_scraped_place`) trả về >= 15 địa điểm hợp lệ không cần DB
- TC-10: Background Task API (`POST /api/v1/admin/crawl`) trả về ngay `job_id` và kiểm tra quyền `get_current_active_superuser`
- TC-11: Job Completion (`GET /api/v1/admin/crawl/{job_id}`) chuyển sang `COMPLETED` với `total_scraped >= 15`, `inserted_count >= 1`
- TC-12: Data Verification (`is_verified == False`, `source == "google_maps"`, `source_url` hợp lệ) trong bảng `restaurants`
- TC-13: Deduplication (`check_duplicate` bằng `ILIKE`) không tạo bản ghi trùng lặp khi cào lại cùng khu vực lần thứ 2.
"""

import asyncio
import os
from pathlib import Path
from fastapi.testclient import TestClient

# Bật chế độ tăng tốc độ trễ mô phỏng trong lúc chạy kiểm thử tự động nhưng vẫn giữ nguyên async/await
os.environ["CRAWLER_FAST_MODE"] = "1"
os.environ["CRAWLER_OFFLINE_FALLBACK"] = "1"

from app.core.rate_limit import reset_corridor_rate_limit_store  # noqa: E402
from app.db.seed_db import init_and_seed_db  # noqa: E402
from app.db.session import SessionLocal  # noqa: E402
from app.integrations.goong_client import decode_polyline, encode_polyline  # noqa: E402
from app.main import _export_openapi_contract, app  # noqa: E402
from app.models.crawl_job import CrawlJob  # noqa: E402
from app.models.restaurant import Restaurant  # noqa: E402
from app.services.crawler.normalizer import (  # noqa: E402
    _clean_reviews_count,
    check_duplicate,
    clean_scraped_place,
    is_valid_vn_location,
)
from app.services.geo_service import calculate_smart_corridor_score  # noqa: E402
from scripts.run_crawler_cli import run_cli_crawl  # noqa: E402

init_and_seed_db()
_export_openapi_contract(app)
client = TestClient(app)


def _get_auth_headers(email: str, password: str) -> dict:
    resp = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert "permissions" in body["user"]
    assert len(body["user"]["permissions"]) >= 1
    token = body["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_health_provinces_and_seed_db():
    """TC-01: Kiểm tra seed_db.py nạp đầy đủ TP. Hồ Chí Minh, Đà Nẵng, Hà Nội và >= 10 địa điểm."""
    health = client.get("/health")
    assert health.status_code == 200
    assert health.json()["status"] == "healthy"

    provs = client.get("/api/v1/provinces")
    assert provs.status_code == 200
    data = provs.json()
    assert len(data) >= 3

    hcm = next(p for p in data if p["code"] == "HCM")
    dn = next(p for p in data if p["code"] == "DN")
    assert hcm["name"] == "TP. Hồ Chí Minh"
    assert hcm["destination_count"] >= 8
    assert dn["name"] == "TP. Đà Nẵng"
    assert dn["destination_count"] >= 2


def test_destinations_cloudinary_urls_and_detail():
    """TC-02 & TC-06: Địa điểm trả về thumbnail_url (w_400,h_300) và detail_image_url (w_1200) từ Cloudinary."""
    res = client.get("/api/v1/destinations", params={"province_id": 1, "q": "Dinh Độc Lập"})
    assert res.status_code == 200
    items = res.json()["items"]
    assert len(items) >= 1
    dinh = items[0]
    assert "Dinh Độc Lập" in dinh["name"]
    assert "c_fill,w_400,h_300,q_auto,f_auto" in dinh["thumbnail_url"]
    assert "w_1200,q_auto,f_auto" in dinh["detail_image_url"]
    assert dinh["is_verified"] is True
    assert dinh["source"] == "admin"

    detail_res = client.get(f"/api/v1/destinations/{dinh['id']}")
    assert detail_res.status_code == 200
    detail = detail_res.json()
    assert "related_destinations" in detail
    assert "nearby_restaurants" in detail


def test_goong_polyline_and_shapely_bounding_box_corridor_search():
    """
    TC-04 (Pitfall #1 & Thay đổi #2):
    Kiểm tra luồng Corridor Search:
    - Mã hóa/giải mã Goong Polyline chuẩn xác
    - Tính Bounding Box lọc sơ bộ trên DB
    - Dùng Shapely (LineString, Point) tính khoảng cách vuông góc < 2km.
    """
    reset_corridor_rate_limit_store()

    sample_pts = [(10.7770, 106.6953), (10.7820, 106.6910), (10.7955, 106.6785)]
    encoded = encode_polyline(sample_pts)
    decoded = decode_polyline(encoded)
    assert len(decoded) == 3
    assert abs(decoded[0][0] - 10.7770) < 1e-4

    payload = {
        "province_id": 1,
        "origin_name": "Dinh Độc Lập (Quận 1)",
        "origin_lat": 10.7770,
        "origin_lng": 106.6953,
        "destination_name": "Phú Nhuận",
        "destination_lat": 10.7955,
        "destination_lng": 106.6785,
        "corridor_radius_km": 1.5,
    }
    res = client.post(
        "/api/v1/restaurants/corridor-search",
        json=payload,
        headers={"X-Client-ID": "pytest-corridor-client"},
    )
    assert res.status_code == 200
    body = res.json()
    assert body["total_route_distance_km"] > 2.0
    assert body["encoded_polyline"] != ""
    assert body["bounding_box"] is not None
    assert body["candidates_in_bbox_count"] >= 3
    assert body["shapely_engine_used"] is True
    assert body["results_count"] >= 3
    for rest in body["restaurants"]:
        assert rest["distance_from_route_km"] <= 1.5
        assert "c_fill,w_400,h_300" in rest["thumbnail_url"]


def test_slowapi_rate_limiting_10_per_minute():
    """
    TC-05 (Pitfall #6):
    Giới hạn mỗi IP/Client chỉ được gọi API tìm đường tối đa 10 lần/phút.
    Lần gọi thứ 11 trong cùng 1 phút phải bị chặn với mã 429 Too Many Requests.
    """
    reset_corridor_rate_limit_store()
    spam_headers = {"X-Client-ID": "spam-bot-ip-192.168.1.99"}
    payload = {
        "province_id": 1,
        "origin_lat": 10.7770,
        "origin_lng": 106.6953,
        "destination_lat": 10.7795,
        "destination_lng": 106.6921,
        "corridor_radius_km": 1.5,
    }

    for i in range(10):
        ok_res = client.post(
            "/api/v1/restaurants/corridor-search",
            json=payload,
            headers=spam_headers,
        )
        assert ok_res.status_code == 200, f"Request #{i+1} should succeed"

    blocked_res = client.post(
        "/api/v1/restaurants/corridor-search",
        json=payload,
        headers=spam_headers,
    )
    assert blocked_res.status_code == 429
    assert "10" in blocked_res.json()["detail"]


def test_itinerary_offline_sync_and_reorder():
    """TC-08 (Pitfall #5): Đồng bộ lịch trình từ Hive Offline lên Server và đổi thứ tự điểm dừng."""
    sync_payload = {
        "local_id": 99901,
        "province_id": 1,
        "title": "Lịch trình tạo khi Offline trong Hive",
        "description": "Tự động đồng bộ khi có mạng trở lại",
        "total_days": 1,
        "stops": [
            {
                "day_number": 1,
                "stop_order": 1,
                "stop_type": "destination",
                "reference_id": 1,
                "title": "Dinh Độc Lập",
                "address": "135 Nam Kỳ Khởi Nghĩa, Quận 1",
                "latitude": 10.7770,
                "longitude": 106.6953,
                "planned_time": "08:30 - 10:30",
                "duration_mins": 120,
            },
            {
                "day_number": 1,
                "stop_order": 2,
                "stop_type": "restaurant",
                "reference_id": 4,
                "title": "Nhà hàng Ngon (160 Pasteur)",
                "address": "160 Pasteur, Quận 1",
                "latitude": 10.7782,
                "longitude": 106.6968,
                "planned_time": "11:30 - 13:00",
                "duration_mins": 90,
            },
        ],
    }
    sync_res = client.post("/api/v1/itineraries/sync", json=sync_payload)
    assert sync_res.status_code == 200
    synced = sync_res.json()
    assert synced["id"] >= 1
    assert len(synced["stops"]) == 2


def test_rbac_role_permission_tables_and_cloudinary_upload():
    """
    TC-03 & TC-06:
    - Kiểm tra bảng Role & Permission qua `/api/v1/admin/roles-permissions`
    - Kiểm tra upload ảnh Cloudinary qua `/api/v1/admin/upload-image`
    - Kiểm tra phân quyền RBAC chặn user thường và giới hạn province_editor theo tỉnh.
    """
    user_headers = _get_auth_headers("traveler@tripflow.vn", "User@123")
    forbidden_res = client.get("/api/v1/admin/dashboard", headers=user_headers)
    assert forbidden_res.status_code == 403

    admin_headers = _get_auth_headers("admin@tripflow.vn", "Admin@123")
    rp_res = client.get("/api/v1/admin/roles-permissions", headers=admin_headers)
    assert rp_res.status_code == 200
    rp_data = rp_res.json()
    assert len(rp_data["roles"]) >= 5
    assert len(rp_data["permissions"]) >= 10

    upload_res = client.post(
        "/api/v1/admin/upload-image",
        headers=admin_headers,
        json={
            "image_url": "https://images.unsplash.com/photo-1583417319070-4a69db38a482",
            "filename": "saigon_landmark.jpg",
            "folder": "tripflow/destinations",
        },
    )
    assert upload_res.status_code == 200
    up_body = upload_res.json()
    assert "c_fill,w_400,h_300,q_auto,f_auto" in up_body["thumbnail_url"]
    assert "w_1200,q_auto,f_auto" in up_body["detail_url"]

    hcm_editor_headers = _get_auth_headers("hcm.editor@tripflow.vn", "Editor@123")
    wrong_prov_res = client.post(
        "/api/v1/admin/destinations",
        headers=hcm_editor_headers,
        json={
            "province_id": 2,
            "category_id": 1,
            "name": "Địa điểm trái thẩm quyền tỉnh",
            "description": "Không được phép tạo ở Đà Nẵng",
            "address": "Đà Nẵng",
            "latitude": 16.05,
            "longitude": 108.20,
        },
    )
    assert wrong_prov_res.status_code == 403


def test_swagger_contract_exported():
    """TC-07 (Pitfall #4): Kiểm tra endpoint và file swagger.json tồn tại chuẩn OpenAPI."""
    contract_res = client.get("/api/v1/contract/swagger.json")
    assert contract_res.status_code == 200
    schema = contract_res.json()
    assert "openapi" in schema
    assert "/api/v1/restaurants/corridor-search" in schema["paths"]
    assert "/api/v1/admin/crawl" in schema["paths"]

    swagger_file = Path(__file__).resolve().parent.parent / "swagger.json"
    assert swagger_file.exists()


# ============================================================================
# KIỂM THỬ NGHIỆM THU MODULE AI DATA INGESTION (TC-09 -> TC-13)
# ============================================================================

def test_tc09_crawler_cli_and_normalizer_without_db():
    """
    TC-09 (CLI Crawler Test & Normalizer):
    - Kiểm tra `is_valid_vn_location` nhận đúng tọa độ Việt Nam (8.18..23.39, 102.14..109.46)
      và từ chối tọa độ ngoài lãnh thổ Việt Nam.
    - Kiểm tra `clean_scraped_place` xóa ký tự rác/icon Google Maps.
    - Kiểm tra `run_cli_crawl("quán ăn ngon", 10.762622, 106.660172)` trả về >= 15 địa điểm hợp lệ.
    """
    assert is_valid_vn_location(10.762622, 106.660172) is True  # TP.HCM
    assert is_valid_vn_location(16.054400, 108.202200) is True  # Đà Nẵng
    assert is_valid_vn_location(21.028500, 105.854200) is True  # Hà Nội
    assert is_valid_vn_location(35.689500, 139.691700) is False  # Tokyo (Ngoài VN)
    assert is_valid_vn_location(1.352100, 103.819800) is False  # Singapore (Ngoài VN)

    dirty_raw = {
        "name": "\ue0c8 • Quán Cơm Tấm Hẻm Sài Gòn \ue0b0",
        "address": "Địa chỉ: \ue0c8 · 284/12 Nguyễn Trọng Tuyển, Quận Phú Nhuận",
        "phone": "Điện thoại: 028 3844 1234",
        "rating": "4,8 sao",
        "lat": 10.762622,
        "lng": 106.660172,
        "image_url": "https://lh3.googleusercontent.com/p/AF1Qip_Test=w600-h400",
        "source_url": "https://www.google.com/maps/place/Test",
    }
    cleaned = clean_scraped_place(dirty_raw)
    assert cleaned["name"] == "Quán Cơm Tấm Hẻm Sài Gòn"
    assert "\ue0c8" not in cleaned["address"]
    assert cleaned["phone"] == "028 3844 1234"
    assert cleaned["rating"] == 4.8

    cli_places = asyncio.run(
        run_cli_crawl(keyword="quán ăn ngon", lat=10.762622, lng=106.660172, max_results=15)
    )
    assert len(cli_places) >= 15
    for item in cli_places:
        assert is_valid_vn_location(item["lat"], item["lng"]) is True
        assert item["image_url"].startswith("http")
        assert item["source_url"].startswith("http")


def test_tc10_tc11_tc12_tc13_admin_crawl_background_verification_and_deduplication():
    """
    Kiểm tra trọn vẹn các tiêu chí TC-10, TC-11, TC-12 và TC-13:
    - TC-10: POST /api/v1/admin/crawl yêu cầu quyền Superuser, trả về ngay `job_id`.
    - TC-11: GET /api/v1/admin/crawl/{job_id} có status == 'COMPLETED', total_scraped >= 15, inserted_count >= 15.
    - TC-12: Các bản ghi mới trong bảng `restaurants` có `is_verified == False`, `source == 'google_maps'`, `source_url` hợp lệ.
    - TC-13: Gọi cào lại cùng từ khóa & tọa độ lần thứ 2 không tạo bản ghi trùng lặp (`inserted_count == 0`, `duplicate_count >= 15`).
    """
    # Dọn dẹp các bản ghi crawl thử nghiệm trước đó (nếu có) để test idempotent
    db = SessionLocal()
    try:
        db.query(Restaurant).filter(Restaurant.source == "google_maps").delete()
        db.query(CrawlJob).delete()
        db.commit()
    finally:
        db.close()

    # 1. User thường hoặc biên tập viên tỉnh gọi POST /api/v1/admin/crawl -> 403 Forbidden
    user_headers = _get_auth_headers("traveler@tripflow.vn", "User@123")
    unauth_crawl = client.post(
        "/api/v1/admin/crawl",
        headers=user_headers,
        json={"keyword": "quán ăn ngon", "lat": 10.762622, "lng": 106.660172},
    )
    assert unauth_crawl.status_code == 403

    admin_headers = _get_auth_headers("admin@tripflow.vn", "Admin@123")

    # 2. Tọa độ ngoài lãnh thổ Việt Nam -> 400 Bad Request
    invalid_coord_res = client.post(
        "/api/v1/admin/crawl",
        headers=admin_headers,
        json={"keyword": "quán ăn ngon", "lat": 35.6895, "lng": 139.6917},
    )
    assert invalid_coord_res.status_code == 400

    # 3. TC-10: Kích hoạt cào dữ liệu lần 1 tại TP.HCM
    crawl_payload = {
        "keyword": "quán ăn ngon",
        "lat": 10.762622,
        "lng": 106.660172,
        "province_id": 1,
    }
    trigger_res = client.post(
        "/api/v1/admin/crawl",
        headers=admin_headers,
        json=crawl_payload,
    )
    assert trigger_res.status_code == 200, trigger_res.text
    trigger_body = trigger_res.json()
    assert "job_id" in trigger_body
    first_job_id = trigger_body["job_id"]
    assert first_job_id >= 1

    # 4. TC-11: Kiểm tra trạng thái job sau khi BackgroundTasks hoàn thành
    status_res = client.get(
        f"/api/v1/admin/crawl/{first_job_id}",
        headers=admin_headers,
    )
    assert status_res.status_code == 200
    job_data = status_res.json()
    assert job_data["status"] == "COMPLETED"
    assert job_data["total_scraped"] >= 15
    assert job_data["inserted_count"] >= 15
    assert job_data["duplicate_count"] == 0

    # 5. TC-12: Kiểm tra dữ liệu lưu trong bảng `restaurants` phải có `is_verified = False`, `source = 'google_maps'`
    db = SessionLocal()
    try:
        crawled_restaurants = (
            db.query(Restaurant)
            .filter(Restaurant.source == "google_maps")
            .all()
        )
        assert len(crawled_restaurants) >= 15
        for r in crawled_restaurants:
            assert r.is_verified is False
            assert r.source == "google_maps"
            assert r.source_url is not None and r.source_url.startswith("http")
            assert r.image_url is not None and r.image_url.startswith("http")
            assert is_valid_vn_location(r.latitude, r.longitude) is True

        # Kiểm tra trực tiếp hàm check_duplicate dùng ILIKE không phân biệt hoa thường
        sample_rest = crawled_restaurants[0]
        assert check_duplicate(db, sample_rest.name.upper(), sample_rest.address.lower(), Restaurant) is True
    finally:
        db.close()

    # 6. TC-13: Gọi cào lại lần thứ 2 với cùng từ khóa và tọa độ -> Chống trùng lặp (Deduplication)
    second_trigger = client.post(
        "/api/v1/admin/crawl",
        headers=admin_headers,
        json=crawl_payload,
    )
    assert second_trigger.status_code == 200
    second_job_id = second_trigger.json()["job_id"]

    second_status = client.get(
        f"/api/v1/admin/crawl/{second_job_id}",
        headers=admin_headers,
    )
    assert second_status.status_code == 200
    second_job_data = second_status.json()
    assert second_job_data["status"] == "COMPLETED"
    assert second_job_data["total_scraped"] >= 15
    assert second_job_data["inserted_count"] == 0
    assert second_job_data["duplicate_count"] >= 15


def test_tc14_tc15_multi_province_expansion_and_region_summary():
    """
    TC-14 & TC-15:
    - Danh sách 10 tỉnh/thành phố du lịch trọng điểm Việt Nam thuộc 4 vùng miền (Bắc Bộ, Trung Bộ, Tây Nguyên, Nam Bộ).
    - Lọc theo ?region=... và tìm kiếm theo ?q=...
    - Thống kê 4 vùng miền tại GET /api/v1/provinces/regions/summary
    """
    # 1. Kiểm tra đủ 10 tỉnh
    res = client.get("/api/v1/provinces")
    assert res.status_code == 200
    provs = res.json()
    assert len(provs) == 10
    expected_codes = {"HCM", "DN", "HN", "QN", "LC", "HUE", "QNA", "KH", "LD", "KG"}
    actual_codes = {p["code"] for p in provs}
    assert expected_codes.issubset(actual_codes)

    # 2. Lọc theo vùng miền: Bắc Bộ
    north_res = client.get("/api/v1/provinces", params={"region": "Bắc Bộ"})
    assert north_res.status_code == 200
    north_provs = north_res.json()
    assert len(north_provs) == 3
    for p in north_provs:
        assert p["region"] == "Bắc Bộ"

    # 3. Lọc theo vùng miền: Tây Nguyên
    tn_res = client.get("/api/v1/provinces", params={"region": "Tây Nguyên"})
    assert tn_res.status_code == 200
    tn_provs = tn_res.json()
    assert len(tn_provs) == 1
    assert tn_provs[0]["code"] == "LD"

    # 4. Tìm kiếm từ khóa: "Phú Quốc"
    q_res = client.get("/api/v1/provinces", params={"q": "Phú Quốc"})
    assert q_res.status_code == 200
    q_provs = q_res.json()
    assert len(q_provs) >= 1
    assert "Kiên Giang" in q_provs[0]["name"]

    # 5. TC-15: GET /api/v1/provinces/regions/summary
    summary_res = client.get("/api/v1/provinces/regions/summary")
    assert summary_res.status_code == 200
    summaries = summary_res.json()
    assert len(summaries) == 4
    regions_set = {s["region"] for s in summaries}
    assert regions_set == {"Bắc Bộ", "Trung Bộ", "Tây Nguyên", "Nam Bộ"}
    total_prov_in_summary = sum(s["province_count"] for s in summaries)
    assert total_prov_in_summary == 10


def test_tc16_corridor_search_multi_provinces():
    """
    TC-16: Corridor Search hoạt động chính xác tại các tỉnh/thành phố khác ngoài TP.HCM (VD: Lâm Đồng - Đà Lạt).
    """
    reset_corridor_rate_limit_store()
    payload = {
        "province_id": 9,  # Lâm Đồng (Đà Lạt)
        "origin_name": "Quảng trường Lâm Viên & Hồ Xuân Hương",
        "origin_lat": 11.9404,
        "origin_lng": 108.4583,
        "destination_name": "Khu du lịch Đỉnh Langbiang",
        "destination_lat": 12.0461,
        "destination_lng": 108.4389,
        "corridor_radius_km": 5.0,
    }
    res = client.post(
        "/api/v1/restaurants/corridor-search",
        json=payload,
        headers={"X-Client-ID": "pytest-dalat-client"},
    )
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["results_count"] >= 1
    assert any("Đà Lạt" in r["name"] or "Đà Lạt" in r["address"] for r in body["restaurants"])


def test_tc18_google_maps_crawler_reviews_and_normalizer():
    """
    TC-18: Kiểm tra bóc tách rating, số lượt review thực tế (reviews_count), 
    trích đoạn bình luận chân thực (sample_reviews) và cờ is_high_rated.
    """
    # 1. Kiểm tra hàm _clean_reviews_count với nhiều định dạng Google Maps
    assert _clean_reviews_count("(1.240)") == 1240
    assert _clean_reviews_count("1,5k reviews") == 1500
    assert _clean_reviews_count("3.2k đánh giá") == 3200
    assert _clean_reviews_count(450) == 450
    assert _clean_reviews_count("5k+") == 5000

    # 2. Kiểm tra clean_scraped_place
    raw_sample = {
        "name": "Quán Phở Gia Truyền",
        "address": "123 Đường Pasteur, Quận 3, TP. Hồ Chí Minh",
        "phone": "028 3829 7943",
        "rating": "4.8",
        "reviews_count": "2.450",
        "lat": 10.7868,
        "lng": 106.6884,
        "sample_reviews": [
            {
                "author": "Hoàng Nam",
                "rating": 5.0,
                "text": "Nước dùng ngọt thanh đậm đà từ xương hầm, thịt mềm thơm.",
                "relative_time": "2 tuần trước",
            },
            {
                "author": "Mai Anh",
                "rating": 4.5,
                "text": "Phục vụ nhanh chóng, quẩy giòn rụm và tương ớt rất ngon.",
                "relative_time": "1 tháng trước",
            },
        ],
        "specialties": "Phở bò tái nạm gầu, quẩy giòn",
    }
    cleaned = clean_scraped_place(raw_sample)
    assert cleaned["name"] == "Quán Phở Gia Truyền"
    assert cleaned["rating"] == 4.8
    assert cleaned["reviews_count"] == 2450
    assert cleaned["is_high_rated"] is True
    assert len(cleaned["sample_reviews"]) == 2
    assert cleaned["sample_reviews"][0]["author"] == "Hoàng Nam"
    assert cleaned["specialties"] == "Phở bò tái nạm gầu, quẩy giòn"


def test_tc19_db_migration_and_seed_reviews():
    """
    TC-19: Cơ sở dữ liệu tự động migrate các cột mới (reviews_count, sample_reviews_json,
    is_high_rated, specialties) và nạp đánh giá thực tế cho các quán ăn của 10 tỉnh thành.
    """
    res = client.get("/api/v1/restaurants")
    assert res.status_code == 200
    rests = res.json()
    assert len(rests) >= 20

    # Tìm Phở Hòa Pasteur
    pho_hoa = next((r for r in rests if "Phở Hòa" in r["name"]), None)
    assert pho_hoa is not None
    assert pho_hoa["reviews_count"] >= 3000
    assert pho_hoa["is_high_rated"] is True
    assert len(pho_hoa["sample_reviews"]) >= 2
    assert pho_hoa["specialties"] is not None

    # Tìm Bánh Mì Huỳnh Hoa
    huynh_hoa = next((r for r in rests if "Huỳnh Hoa" in r["name"]), None)
    assert huynh_hoa is not None
    assert huynh_hoa["reviews_count"] >= 4000
    assert huynh_hoa["is_high_rated"] is True


def test_tc20_optimized_restaurant_search_and_review_query():
    """
    TC-20: Tối ưu hóa tìm kiếm nhà hàng:
    - Lọc rating tối thiểu min_rating=4.7
    - Sắp xếp theo số lượng review sort_by=reviews_count
    - Tìm kiếm từ khóa q trong nội dung bình luận thực tế (sample_reviews_json)
    """
    # 1. Lọc min_rating=4.7
    r_res = client.get("/api/v1/restaurants", params={"min_rating": 4.7})
    assert r_res.status_code == 200
    high_rated_list = r_res.json()
    assert len(high_rated_list) >= 5
    for r in high_rated_list:
        assert r["rating"] >= 4.7

    # 2. Sắp xếp sort_by=reviews_count
    sort_res = client.get("/api/v1/restaurants", params={"sort_by": "reviews_count"})
    assert sort_res.status_code == 200
    sorted_items = sort_res.json()
    assert len(sorted_items) >= 2
    # Quán đứng đầu phải có reviews_count lớn hơn hoặc bằng quán thứ 2
    assert sorted_items[0]["reviews_count"] >= sorted_items[1]["reviews_count"]

    # 3. Tìm kiếm q nằm trong trích đoạn bình luận thực tế
    q_res = client.get("/api/v1/restaurants", params={"q": "quẩy giòn"})
    assert q_res.status_code == 200
    q_items = q_res.json()
    assert len(q_items) >= 1
    assert any("Phở Hòa" in item["name"] for item in q_items)


def test_tc21_smart_food_corridor_scoring_algorithm():
    """
    TC-21: Thuật toán Smart Food Corridor Score (SFCS) kết hợp khoảng cách lệch tuyến,
    rating sao, độ uy tín reviews_count và bonus cờ is_high_rated.
    """
    # 1. Kiểm tra hàm tính điểm SFCS độc lập
    # Quán gần (0.2km), rating 4.8, 4120 reviews, is_high_rated=True -> điểm cao > 85
    score_top = calculate_smart_corridor_score(
        distance_km=0.2,
        corridor_radius_km=2.0,
        rating=4.8,
        reviews_count=4120,
        is_high_rated=True,
    )
    assert score_top >= 85.0

    # Quán xa (1.8km), rating 3.5, 50 reviews, is_high_rated=False -> điểm thấp hơn nhiều
    score_low = calculate_smart_corridor_score(
        distance_km=1.8,
        corridor_radius_km=2.0,
        rating=3.5,
        reviews_count=50,
        is_high_rated=False,
    )
    assert score_low < score_top

    # 2. Gọi API Corridor Search kiểm tra trả về corridor_score
    reset_corridor_rate_limit_store()
    payload = {
        "province_id": 1,
        "origin_name": "Dinh Độc Lập",
        "origin_lat": 10.7769,
        "origin_lng": 106.6953,
        "destination_name": "Bảo tàng Chứng tích Chiến tranh",
        "destination_lat": 10.7794,
        "destination_lng": 106.6922,
        "corridor_radius_km": 2.5,
    }
    res = client.post(
        "/api/v1/restaurants/corridor-search",
        json=payload,
        headers={"X-Client-ID": "pytest-sfcs-client"},
    )
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["results_count"] >= 1
    first_rest = body["restaurants"][0]
    assert "corridor_score" in first_rest
    assert first_rest["corridor_score"] > 0.0

    # Danh sách kết quả phải được sắp xếp theo corridor_score giảm dần
    for i in range(len(body["restaurants"]) - 1):
        assert (
            body["restaurants"][i]["corridor_score"]
            >= body["restaurants"][i + 1]["corridor_score"]
        )


def test_tc22_itinerary_smart_meal_stop_insertion():
    """
    TC-22: Tự động phân tích khoảng cách di chuyển giữa các điểm tham quan trong ngày,
    chèn điểm dừng ăn uống có SFCS cao nhất và tự động điều chỉnh stop_order.
    """
    # 1. Tạo lịch trình tham quan mẫu có 2 điểm đến
    create_payload = {
        "province_id": 1,
        "title": "Tour Sài Gòn Lịch Sử Bữa Trưa",
        "description": "Lịch trình khám phá trung tâm TP.HCM có dừng ăn trưa",
        "total_days": 1,
        "stops": [
            {
                "day_number": 1,
                "stop_order": 1,
                "stop_type": "destination",
                "reference_id": 1,
                "title": "Dinh Độc Lập",
                "latitude": 10.7769,
                "longitude": 106.6953,
                "planned_time": "08:30 - 10:30",
            },
            {
                "day_number": 1,
                "stop_order": 2,
                "stop_type": "destination",
                "reference_id": 2,
                "title": "Nhà thờ Đức Bà Sài Gòn",
                "latitude": 10.7798,
                "longitude": 106.6990,
                "planned_time": "14:00 - 15:30",
            },
        ],
    }
    create_res = client.post("/api/v1/itineraries", json=create_payload)
    assert create_res.status_code == 201
    itin_id = create_res.json()["id"]

    # 2. Gọi endpoint tự động chèn điểm dừng ăn uống thông minh
    meal_req = {
        "day_number": 1,
        "preferred_time": "12:00",
        "corridor_radius_km": 2.5,
    }
    meal_res = client.post(
        f"/api/v1/itineraries/{itin_id}/smart-meal-stops",
        json=meal_req,
    )
    assert meal_res.status_code == 200, meal_res.text
    meal_data = meal_res.json()

    assert meal_data["itinerary_id"] == itin_id
    assert meal_data["day_number"] == 1
    assert meal_data["smart_score"] > 0
    assert "reasoning" in meal_data
    assert meal_data["inserted_stop"]["stop_type"] == "meal"
    assert meal_data["inserted_stop"]["stop_order"] == 2

    # 3. Xem lại chi tiết lịch trình để đảm bảo thứ tự stop_order đã được điều chỉnh liên tiếp
    detail_res = client.get(f"/api/v1/itineraries/{itin_id}")
    assert detail_res.status_code == 200
    updated_stops = detail_res.json()["stops"]
    assert len(updated_stops) == 3

    # Thứ tự 1: Dinh Độc Lập
    assert updated_stops[0]["stop_order"] == 1
    # Thứ tự 2: Điểm dừng ăn uống được chèn
    assert updated_stops[1]["stop_order"] == 2
    assert updated_stops[1]["stop_type"] == "meal"
    # Thứ tự 3: Nhà thờ Đức Bà được đẩy lùi xuống vị trí thứ 3
    assert updated_stops[2]["stop_order"] == 3
    assert "Nhà thờ Đức Bà" in updated_stops[2]["title"]


def test_tc23_sms_otp_registration_and_login():
    """
    TC-23: Kiểm thử toàn diện API Xác thực Người dùng qua Tin nhắn SMS OTP:
    1. Gửi OTP với số điện thoại sai định dạng (ví dụ: '12345', '0123456789') -> HTTP 400.
    2. Gửi OTP với số điện thoại di động Việt Nam hợp lệ (0912345678) -> HTTP 200, nhận debug_otp 6 chữ số.
    3. Xác thực với mã OTP sai -> HTTP 400 và giảm số lần thử.
    4. Xác thực với mã OTP đúng -> HTTP 200, cấp access_token JWT và UserOut chứa đúng phone.
    5. Cố gắng sử dụng lại mã OTP đã xác thực -> HTTP 400 (chống Replay Attack).
    """
    test_phone = "0912345678"
    test_name = "Nguyễn Văn Du Khách SMS"

    # 1. Gửi OTP với số điện thoại sai định dạng
    invalid_resp = client.post(
        "/api/v1/auth/otp/send",
        json={"phone": "012345678", "full_name": test_name},
    )
    assert invalid_resp.status_code == 400
    assert "Số điện thoại không đúng định dạng" in invalid_resp.json()["detail"]

    # 2. Gửi OTP với số điện thoại di động Việt Nam hợp lệ
    send_resp = client.post(
        "/api/v1/auth/otp/send",
        json={"phone": test_phone, "full_name": test_name},
    )
    assert send_resp.status_code == 200, send_resp.text
    send_data = send_resp.json()
    assert send_data["phone"] == test_phone
    assert send_data["expires_in_seconds"] == 300
    assert "debug_otp" in send_data
    otp_code = send_data["debug_otp"]
    assert len(otp_code) == 6
    assert otp_code.isdigit()

    # 3. Xác thực với mã OTP sai
    wrong_otp_resp = client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": test_phone, "otp_code": "000000", "full_name": test_name},
    )
    assert wrong_otp_resp.status_code == 400
    assert "Mã xác thực OTP không chính xác" in wrong_otp_resp.json()["detail"]

    # 4. Xác thực với mã OTP đúng
    verify_resp = client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": test_phone, "otp_code": otp_code, "full_name": test_name},
    )
    assert verify_resp.status_code == 200, verify_resp.text
    auth_data = verify_resp.json()
    assert "access_token" in auth_data
    assert auth_data["token_type"] == "bearer"
    user = auth_data["user"]
    assert user["phone"] == test_phone
    assert user["full_name"] == test_name
    assert user["role"] == "user"
    assert "destination:read" in user["permissions"]

    # 5. Cố gắng sử dụng lại mã OTP cũ (chống Replay Attack)
    replay_resp = client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": test_phone, "otp_code": otp_code, "full_name": test_name},
    )
    assert replay_resp.status_code == 400
    assert "Mã xác thực OTP không tồn tại hoặc đã hết hiệu lực" in replay_resp.json()["detail"]

