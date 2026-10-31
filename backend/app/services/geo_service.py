import math
from typing import Any, Dict, List, Optional, Tuple
from sqlmodel import Session, select

try:
    from shapely.geometry import LineString, Point
    SHAPELY_AVAILABLE = True
except ImportError:  # pragma: no cover
    SHAPELY_AVAILABLE = False

from app.models.models import Restaurant
from app.repositories.repositories import serialize_restaurant

EARTH_RADIUS_KM = 6371.0


def haversine_distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Tính khoảng cách đường chim bay (km) giữa 2 tọa độ GPS bằng công thức Haversine."""
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lng2 - lng1)

    a = (
        math.sin(d_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(max(0.0, 1.0 - a)))
    return EARTH_RADIUS_KM * c


def build_route_polyline(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float,
    waypoints: Optional[List[Tuple[float, float]]] = None,
) -> List[Tuple[float, float]]:
    """Sinh chuỗi tọa độ Polyline mô phỏng tuyến đường di chuyển qua các nút giao đô thị."""
    anchor_points: List[Tuple[float, float]] = [(origin_lat, origin_lng)]
    if waypoints:
        anchor_points.extend(waypoints)
    anchor_points.append((dest_lat, dest_lng))

    polyline: List[Tuple[float, float]] = []
    for idx in range(len(anchor_points) - 1):
        a_lat, a_lng = anchor_points[idx]
        b_lat, b_lng = anchor_points[idx + 1]
        if idx == 0:
            polyline.append((round(a_lat, 6), round(a_lng, 6)))

        d_lat = b_lat - a_lat
        d_lng = b_lng - a_lng
        steps = 4
        for step in range(1, steps):
            frac = step / float(steps)
            curve_offset = math.sin(frac * math.pi) * 0.0008
            inter_lat = a_lat + d_lat * frac + curve_offset * (1 if d_lng >= 0 else -1)
            inter_lng = a_lng + d_lng * frac - curve_offset * (1 if d_lat >= 0 else -1)
            polyline.append((round(inter_lat, 6), round(inter_lng, 6)))

        polyline.append((round(b_lat, 6), round(b_lng, 6)))

    return polyline


def calculate_polyline_length_km(polyline: List[Tuple[float, float]]) -> float:
    """Tính tổng chiều dài tuyến đường Polyline (km)."""
    if len(polyline) < 2:
        return 0.0
    total = 0.0
    for i in range(len(polyline) - 1):
        total += haversine_distance_km(
            polyline[i][0],
            polyline[i][1],
            polyline[i + 1][0],
            polyline[i + 1][1],
        )
    return round(total, 2)


# ============================================================================
# BƯỚC 3 CỦA PITFALL #1: LỌC SƠ BỘ BẰNG BOUNDING BOX TRÊN B-TREE INDEX (lat, lng)
# ============================================================================

def compute_route_bounding_box(
    polyline: List[Tuple[float, float]],
    corridor_radius_km: float,
) -> Dict[str, float]:
    """
    Tính hình chữ nhật bao quanh tuyến đường (Bounding Box) mở rộng thêm bán kính hành lang
    `corridor_radius_km` để lọc nhanh trên Database bằng B-Tree Index (latitude, longitude).
    """
    if not polyline:
        return {"min_lat": 0.0, "max_lat": 0.0, "min_lng": 0.0, "max_lng": 0.0}

    lats = [pt[0] for pt in polyline]
    lngs = [pt[1] for pt in polyline]
    min_lat, max_lat = min(lats), max(lats)
    min_lng, max_lng = min(lngs), max(lngs)

    mean_lat_rad = math.radians((min_lat + max_lat) / 2.0)
    cos_lat = max(0.2, math.cos(mean_lat_rad))

    # 1 độ vĩ tuyến ~ 111.0 km; 1 độ kinh tuyến ~ 111.32 * cos(lat) km
    lat_buffer = (corridor_radius_km + 0.15) / 111.0
    lng_buffer = (corridor_radius_km + 0.15) / (111.32 * cos_lat)

    return {
        "min_lat": round(min_lat - lat_buffer, 6),
        "max_lat": round(max_lat + lat_buffer, 6),
        "min_lng": round(min_lng - lng_buffer, 6),
        "max_lng": round(max_lng + lng_buffer, 6),
    }


def filter_restaurants_by_bounding_box(
    db: Session,
    bbox: Dict[str, float],
    province_id: Optional[int] = None,
) -> List[Restaurant]:
    """
    Thực thi truy vấn SQL lọc sơ bộ các nhà hàng nằm trong khung chữ nhật Bounding Box:
    SELECT * FROM restaurants WHERE latitude BETWEEN min_lat AND max_lat AND longitude BETWEEN min_lng AND max_lng
    Nhờ B-Tree Composite Index `ix_restaurants_lat_lng`, bước này loại bỏ ngay >95% các điểm ở xa
    mà không cần cài đặt PostGIS.
    """
    stmt = select(Restaurant).where(
        Restaurant.status == "published",
        Restaurant.latitude >= bbox["min_lat"],
        Restaurant.latitude <= bbox["max_lat"],
        Restaurant.longitude >= bbox["min_lng"],
        Restaurant.longitude <= bbox["max_lng"],
    )
    if province_id is not None:
        stmt = stmt.where(Restaurant.province_id == province_id)
    return list(db.exec(stmt).all())


def calculate_smart_corridor_score(
    distance_km: float,
    corridor_radius_km: float,
    rating: float,
    reviews_count: int,
    is_high_rated: bool = True,
) -> float:
    """
    Tính điểm thông minh Smart Food Corridor Score (SFCS) - Thang điểm 0 - 105:
    1. Điểm cự ly (Max 40 điểm): Quán càng sát lộ trình càng nhiều điểm.
    2. Điểm sao đánh giá (Max 35 điểm): Chuẩn hóa rating [3.0, 5.0] sang [0, 35].
    3. Độ phổ biến & uy tín thực tế (Max 25 điểm): Dùng hàm log10 của số lượng reviews.
    4. Thưởng quán uy tín (Bonus 5 điểm): Nếu is_high_rated == True.
    """
    safe_radius = max(0.1, corridor_radius_km)
    dist_ratio = max(0.0, min(1.0, distance_km / safe_radius))
    dist_score = (1.0 - dist_ratio) * 40.0

    clamped_rating = max(3.0, min(5.0, rating))
    rating_score = ((clamped_rating - 3.0) / 2.0) * 35.0

    safe_reviews = max(10, min(reviews_count, 10000))
    review_score = (math.log10(safe_reviews) / 4.0) * 25.0

    bonus = 5.0 if is_high_rated else 0.0

    total_score = dist_score + rating_score + review_score + bonus
    return round(total_score, 2)


# ============================================================================
# BƯỚC 4 CỦA PITFALL #1: TÍNH KHOẢNG CÁCH VUÔNG GÓC CHÍNH XÁC BẰNG SHAPELY
# ============================================================================

def point_to_segment_distance_km(
    px: float,
    py: float,
    ax: float,
    ay: float,
    bx: float,
    by: float,
) -> Tuple[float, float, float, float]:
    """Chiếu điểm P lên đoạn thẳng AB (Hỗ trợ fallback nếu môi trường không có C-extension)."""
    mean_lat_rad = math.radians((px + ax + bx) / 3.0)
    cos_lat = max(0.2, math.cos(mean_lat_rad))

    ab_x = bx - ax
    ab_y = (by - ay) * cos_lat
    ap_x = px - ax
    ap_y = (py - ay) * cos_lat

    ab_len_sq = ab_x * ab_x + ab_y * ab_y
    if ab_len_sq <= 1e-12:
        t = 0.0
    else:
        t = (ap_x * ab_x + ap_y * ab_y) / ab_len_sq
        t = max(0.0, min(1.0, t))

    closest_lat = ax + t * (bx - ax)
    closest_lng = ay + t * (by - ay)
    dist_km = haversine_distance_km(px, py, closest_lat, closest_lng)
    return dist_km, round(closest_lat, 6), round(closest_lng, 6), t


def find_restaurants_along_corridor_shapely(
    restaurants: List[Restaurant],
    polyline: List[Tuple[float, float]],
    corridor_radius_km: float,
    cuisine_filter: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """
    Thuật toán tìm nhà hàng dọc lộ trình sử dụng thư viện hình học `Shapely` (LineString & Point)
    theo đúng hướng dẫn Phòng tránh Pitfalls #1:
    1. Chiếu tọa độ (lat, lng) của Polyline sang mặt phẳng mét/kilomet cục bộ quanh tâm tuyến đường.
    2. Tạo đối tượng `LineString` đại diện cho tuyến đường và `Point` cho từng nhà hàng trong Bounding Box.
    3. Dùng `route_line.distance(point)` tính khoảng cách vuông góc chính xác từ nhà hàng đến đường đi.
    4. Dùng `route_line.project(point)` và `route_line.interpolate(...)` tìm tọa độ điểm rẽ gần nhất trên tuyến.
    5. Chỉ giữ lại những nhà hàng có khoảng cách <= `corridor_radius_km` (mặc định < 2km).
    """
    if not polyline:
        return []

    cuisine_kw = cuisine_filter.strip().lower() if cuisine_filter and cuisine_filter != "all" else None

    if SHAPELY_AVAILABLE and len(polyline) >= 2:
        ref_lat = sum(p[0] for p in polyline) / float(len(polyline))
        ref_lng = sum(p[1] for p in polyline) / float(len(polyline))
        cos_ref = max(0.2, math.cos(math.radians(ref_lat)))

        def to_xy_km(lat: float, lng: float) -> Tuple[float, float]:
            x = (lng - ref_lng) * 111.32 * cos_ref
            y = (lat - ref_lat) * 111.32
            return (x, y)

        def to_lat_lng(x: float, y: float) -> Tuple[float, float]:
            lat = ref_lat + (y / 111.32)
            lng = ref_lng + (x / (111.32 * cos_ref))
            return (round(lat, 6), round(lng, 6))

        route_line = LineString([to_xy_km(lat, lng) for lat, lng in polyline])
        total_line_len = max(0.01, route_line.length)

        results: List[Dict[str, Any]] = []
        for rest in restaurants:
            if rest.status != "published":
                continue
            if cuisine_kw:
                haystack = f"{rest.cuisine_type or ''} {rest.specialty_dishes or ''} {rest.name or ''}".lower()
                if cuisine_kw not in haystack:
                    continue

            rx, ry = to_xy_km(rest.latitude, rest.longitude)
            pt = Point(rx, ry)

            # Tính khoảng cách vuông góc chính xác từ Point tới LineString bằng Shapely
            dist_km = float(route_line.distance(pt))

            if dist_km <= corridor_radius_km:
                proj_along_km = float(route_line.project(pt))
                nearest_pt = route_line.interpolate(proj_along_km)
                nearest_lat, nearest_lng = to_lat_lng(nearest_pt.x, nearest_pt.y)

                dist_rounded = round(dist_km, 2)
                detour_km = round(dist_km * 2.0, 2)
                detour_mins = max(2, int(round(detour_km / 0.4)) + 1)
                progress_pct = round(
                    min(100.0, max(0.0, (proj_along_km / total_line_len) * 100.0)), 1
                )

                corridor_score = calculate_smart_corridor_score(
                    distance_km=dist_rounded,
                    corridor_radius_km=corridor_radius_km,
                    rating=rest.rating,
                    reviews_count=getattr(rest, "reviews_count", rest.review_count or 120),
                    is_high_rated=getattr(rest, "is_high_rated", True),
                )

                base_data = serialize_restaurant(rest)
                base_data.update(
                    {
                        "distance_from_route_km": dist_rounded,
                        "detour_distance_km": detour_km,
                        "estimated_detour_mins": detour_mins,
                        "nearest_route_point_lat": nearest_lat,
                        "nearest_route_point_lng": nearest_lng,
                        "route_progress_pct": progress_pct,
                        "corridor_score": corridor_score,
                    }
                )
                results.append(base_data)

        # Sắp xếp ưu tiên theo Smart Food Corridor Score (SFCS) cao nhất lên đầu
        results.sort(key=lambda r: (-r.get("corridor_score", 0.0), r["distance_from_route_km"]))
        return results

    # Fallback toán học tương đương nếu chạy trên môi trường thiếu thư viện C
    total_length_km = max(0.01, calculate_polyline_length_km(polyline))
    segment_lengths: List[float] = []
    for i in range(len(polyline) - 1):
        seg_len = haversine_distance_km(
            polyline[i][0], polyline[i][1], polyline[i + 1][0], polyline[i + 1][1]
        )
        segment_lengths.append(seg_len)

    results = []
    for rest in restaurants:
        if rest.status != "published":
            continue
        if cuisine_kw:
            haystack = f"{rest.cuisine_type or ''} {rest.specialty_dishes or ''} {rest.name or ''}".lower()
            if cuisine_kw not in haystack:
                continue

        min_dist_km = float("inf")
        best_lat = polyline[0][0]
        best_lng = polyline[0][1]
        best_along_km = 0.0
        cumulative_km = 0.0

        if len(polyline) == 1:
            min_dist_km = haversine_distance_km(
                rest.latitude, rest.longitude, polyline[0][0], polyline[0][1]
            )
        else:
            for idx in range(len(polyline) - 1):
                ax, ay = polyline[idx]
                bx, by = polyline[idx + 1]
                dist_km, c_lat, c_lng, seg_t = point_to_segment_distance_km(
                    rest.latitude, rest.longitude, ax, ay, bx, by
                )
                if dist_km < min_dist_km:
                    min_dist_km = dist_km
                    best_lat = c_lat
                    best_lng = c_lng
                    best_along_km = cumulative_km + seg_t * segment_lengths[idx]
                cumulative_km += segment_lengths[idx]

        if min_dist_km <= corridor_radius_km:
            dist_rounded = round(min_dist_km, 2)
            corridor_score = calculate_smart_corridor_score(
                distance_km=dist_rounded,
                corridor_radius_km=corridor_radius_km,
                rating=rest.rating,
                reviews_count=getattr(rest, "reviews_count", rest.review_count or 120),
                is_high_rated=getattr(rest, "is_high_rated", True),
            )

            base_data = serialize_restaurant(rest)
            detour_km = round(min_dist_km * 2.0, 2)
            detour_mins = max(2, int(round(detour_km / 0.4)) + 1)
            progress_pct = round(
                min(100.0, max(0.0, (best_along_km / total_length_km) * 100.0)), 1
            )
            base_data.update(
                {
                    "distance_from_route_km": dist_rounded,
                    "detour_distance_km": detour_km,
                    "estimated_detour_mins": detour_mins,
                    "nearest_route_point_lat": best_lat,
                    "nearest_route_point_lng": best_lng,
                    "route_progress_pct": progress_pct,
                    "corridor_score": corridor_score,
                }
            )
            results.append(base_data)

    results.sort(key=lambda r: (-r.get("corridor_score", 0.0), r["distance_from_route_km"]))
    return results


# Alias giữ tương thích cho các module gọi tên hàm cũ
find_restaurants_along_corridor = find_restaurants_along_corridor_shapely
