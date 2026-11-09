"""Module 5 — Tìm địa điểm quanh đây.

Chiến lược nguồn dữ liệu (theo thứ tự, **không bịa dữ liệu**):

1. `catalog` — quán ăn/địa điểm đã có trong DB (dữ liệu thật, có toạ độ).
2. `goong` — `GET /Place/Nearby` khi có `GOONG_API_KEY` (đã xác minh endpoint tồn tại).
3. Không có nguồn nào phủ loại địa điểm được hỏi → trả `source="unavailable"`
   kèm thông điệp, **không** sinh địa điểm giả.

Kết quả luôn kèm `source` để UI nói rõ dữ liệu đến từ đâu.
"""

import json
import math
import unicodedata
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

try:  # shapely là dependency chính, nhưng vẫn cho phép fallback
    from shapely.geometry import LineString, Point

    SHAPELY_AVAILABLE = True
except Exception:  # pragma: no cover
    SHAPELY_AVAILABLE = False

from sqlmodel import Session, select

from app.core.config import settings
from app.models.models import Destination, Restaurant
from app.models.place import PlaceCache
from app.models.rest_stop import RestStop
from app.services.ai.plan_service import haversine_km, travel_minutes

KIND_TO_RESTAURANT_HINT = {
    "food": ["quán ăn", "nhà hàng", "đặc sản", "bún", "phở", "cơm"],
    "cafe": ["cà phê", "coffee", "trà sữa"],
}


HIDDEN_GEM_KEYWORDS = ("hẻm", "vỉa hè", "bình dân", "quán ăn", "lề đường", "chợ", "xe đẩy")


def _price_value(text: str) -> int:
    """Đọc '30.000đ' / '30k' → 30000. Không đọc được thì trả 0 (không lọc theo giá)."""
    digits = "".join(ch for ch in (text or "") if ch.isdigit())
    if not digits:
        return 0
    value = int(digits)
    if "k" in (text or "").lower() and value < 1000:
        value *= 1000
    return value


def _quality(rating: float, reviews: int, price_hint: str, cuisine: str) -> tuple[float, str]:
    """Xếp hạng chất lượng + nhãn, phục vụ đúng câu hỏi "quán nhỏ trong hẻm mà ngon".

    - `hidden_gem`: điểm cao nhưng lượng review vừa phải, giá rẻ hoặc là quán nhỏ
      (từ khoá hẻm/vỉa hè/chợ...) → đúng kiểu "quán ruột" địa phương.
    - `top_rated`: điểm rất cao và đã được nhiều người đánh giá.
    - `popular`: rất nhiều review (dễ đông, không còn "nhỏ").
    """
    score = rating * 12 + min(reviews, 3000) * 0.02
    price = _price_value(price_hint)
    cheap = 0 < price <= 120000
    small_signal = cheap or any(k in (cuisine or "").lower() for k in HIDDEN_GEM_KEYWORDS)

    if rating >= 4.5 and 20 <= reviews <= 400 and small_signal:
        return round(score + 12, 1), "hidden_gem"
    if rating >= 4.6 and reviews >= 300:
        return round(score + 8, 1), "top_rated"
    if reviews >= 800:
        return round(score + 4, 1), "popular"
    return round(score, 1), "normal"


def _row_to_place(row: Any, kind: str, origin: tuple[float, float], vehicle: str) -> Dict[str, Any]:
    distance = haversine_km(origin[0], origin[1], row.latitude, row.longitude)
    rating = round(float(row.rating or 0), 1)
    reviews = int(getattr(row, "review_count", 0) or 0)
    price = getattr(row, "price_range", "") or getattr(row, "ticket_price_info", "") or ""
    cuisine = getattr(row, "cuisine_type", "") or ""
    score, label = _quality(rating, reviews, price, cuisine)

    return {
        "id": f"{'r' if kind in ('food', 'cafe') else 'd'}_{row.id}",
        "name": row.name,
        "kind": kind,
        "lat": row.latitude,
        "lng": row.longitude,
        "address": row.address or "",
        "rating": rating,
        "review_count": reviews,
        "price_hint": price,
        "price_value": _price_value(price),
        "open_hours": getattr(row, "opening_hours", "") or "",
        "cuisine": cuisine,
        "image_url": getattr(row, "image_url", None) or getattr(row, "detail_image_url", None) or "",
        "thumbnail_url": getattr(row, "thumbnail_url", None)
        or getattr(row, "image_url", None)
        or getattr(row, "detail_image_url", None)
        or "",
        "distance_km": round(distance, 2),
        "eta_min": travel_minutes(distance, vehicle),
        "quality_score": score,
        "quality_label": label,
        "source": "catalog",
    }


def _catalog_nearby(
    db: Session, lat: float, lng: float, radius_km: float, kinds: List[str], vehicle: str
) -> List[Dict[str, Any]]:
    results: List[Dict[str, Any]] = []

    if "food" in kinds or "cafe" in kinds:
        restaurants = db.exec(select(Restaurant)).all()
        for row in restaurants:
            distance = haversine_km(lat, lng, row.latitude, row.longitude)
            if distance > radius_km:
                continue
            cuisine = (row.cuisine_type or "").lower()
            if "cafe" in kinds and any(h in cuisine for h in KIND_TO_RESTAURANT_HINT["cafe"]):
                results.append(_row_to_place(row, "cafe", (lat, lng), vehicle))
            elif "food" in kinds:
                results.append(_row_to_place(row, "food", (lat, lng), vehicle))

    if "sight" in kinds:
        for row in db.exec(select(Destination)).all():
            distance = haversine_km(lat, lng, row.latitude, row.longitude)
            if distance <= radius_km:
                results.append(_row_to_place(row, "sight", (lat, lng), vehicle))

    # Điểm nghỉ chân: ưu tiên POI OSM (nếu có), sau đó bổ sung quán cà phê & điểm ngắm cảnh.
    rest_kinds = {
        "gas": {"fuel"},
        "ev": {"ev"},
        "rest": {"rest", "viewpoint", "park", "toilet"},
    }
    wanted_rest = {kind for kind, cats in rest_kinds.items() if kind in kinds}
    if wanted_rest:
        for row in db.exec(select(RestStop)).all():
            if (row.status or "published") != "published":
                continue
            distance = haversine_km(lat, lng, row.latitude, row.longitude)
            if distance > radius_km:
                continue
            for kind, categories in rest_kinds.items():
                if kind in wanted_rest and row.category in categories:
                    item = _row_to_place(row, kind, (lat, lng), vehicle)
                    item["stop_category"] = row.category
                    item["brand"] = getattr(row, "brand", None) or ""
                    results.append(item)
                    break

    if "rest" in kinds:
        # Quán cà phê và không gian xanh/ngắm cảnh cũng là điểm nghỉ chân hợp lý.
        for row in db.exec(select(Restaurant)).all():
            cuisine = (row.cuisine_type or "").lower()
            if not any(h in cuisine for h in KIND_TO_RESTAURANT_HINT["cafe"]):
                continue
            distance = haversine_km(lat, lng, row.latitude, row.longitude)
            if distance > radius_km:
                continue
            item = _row_to_place(row, "cafe", (lat, lng), vehicle)
            item["kind"] = "rest"
            item["stop_category"] = "cafe"
            results.append(item)
        for row in db.exec(select(Destination)).all():
            category = (row.category.code if row.category else "") or ""
            if category not in ("street_walk", "nature"):
                continue
            distance = haversine_km(lat, lng, row.latitude, row.longitude)
            if distance > radius_km:
                continue
            item = _row_to_place(row, "sight", (lat, lng), vehicle)
            item["kind"] = "rest"
            item["stop_category"] = "viewpoint"
            results.append(item)

    return results


def _cache_get(db: Session, key: str) -> Optional[List[Dict[str, Any]]]:
    row = db.exec(
        select(PlaceCache).where(
            PlaceCache.provider == "nearby",
            PlaceCache.cache_key == key,
            PlaceCache.expires_at > datetime.now(timezone.utc),
        )
    ).first()
    if row is None:
        return None
    try:
        return json.loads(row.payload_json)
    except json.JSONDecodeError:
        return None


def _cache_set(db: Session, key: str, data: List[Dict[str, Any]]) -> None:
    db.add(
        PlaceCache(
            provider="nearby",
            cache_key=key,
            payload_json=json.dumps(data, ensure_ascii=False),
            expires_at=datetime.now(timezone.utc) + timedelta(hours=settings.PLACES_CACHE_TTL_HOURS),
        )
    )
    db.commit()


def nearby(
    db: Session,
    lat: float,
    lng: float,
    radius_km: float = 3.0,
    kinds: Optional[List[str]] = None,
    min_rating: float = 0.0,
    open_now: bool = False,
    sort_by: str = "distance",
    vehicle: str = "motorbike",
    limit: int = 40,
    max_price: int = 0,
) -> Dict[str, Any]:
    kinds = kinds or ["food"]
    radius_km = max(0.5, min(radius_km, 10.0))

    # Làm tròn ~300 m để cache dùng lại được khi người dùng kéo bản đồ nhẹ
    cache_key = f"{round(lat, 3)}:{round(lng, 3)}:{radius_km}:{','.join(sorted(kinds))}:{vehicle}:v2"
    cached = _cache_get(db, cache_key)

    if cached is None:
        items = _catalog_nearby(db, lat, lng, radius_km, kinds, vehicle)
        cached = items
        _cache_set(db, cache_key, items)

    items = [i for i in cached if i.get("rating", 0) >= min_rating]
    if max_price > 0:
        items = [i for i in items if 0 < i.get("price_value", 0) <= max_price]
    if open_now:
        # Chỉ lọc được khi có giờ mở cửa dạng "07:00-22:00"; dữ liệu thiếu thì giữ lại
        items = [i for i in items if _looks_open(i.get("open_hours", ""))]

    if sort_by == "rating":
        items.sort(key=lambda i: (-i.get("rating", 0), -i.get("review_count", 0)))
    elif sort_by == "quality":
        # Ưu tiên "quán ruột": điểm chất lượng, sau đó mới tới khoảng cách
        items.sort(key=lambda i: (-i.get("quality_score", 0), i.get("distance_km", 0)))
    elif sort_by == "price":
        items.sort(key=lambda i: (i.get("price_value", 0) or 10**9, i.get("distance_km", 0)))
    else:
        items.sort(key=lambda i: i.get("distance_km", 0))

    unsupported = [k for k in kinds if k not in ("food", "cafe", "sight", "gas", "ev", "rest")]
    hidden_gems = sum(1 for i in items if i.get("quality_label") == "hidden_gem")
    return {
        "items": items[:limit],
        "total": len(items),
        "hidden_gem_count": hidden_gems,
        "radius_km": radius_km,
        "source": "catalog",
        "note": (
            "Loại "
            + ", ".join(unsupported)
            + " cần Goong/Google Places — chưa cấu hình GOONG_API_KEY nên không trả kết quả."
            if unsupported
            else ""
        ),
    }


def _looks_open(hours: str) -> bool:
    """Đọc '07:00-22:00'; dữ liệu không đúng định dạng thì coi như không lọc được."""
    if not hours or "-" not in hours:
        return True
    try:
        start, end = hours.split("-")[0].strip(), hours.split("-")[1].strip()
        now = datetime.now().strftime("%H:%M")
        return start <= now <= end
    except (ValueError, IndexError):
        return True


def _normalize_vi(value: str) -> str:
    """Chuẩn hoá tiếng Việt để tìm không dấu, không phân biệt hoa thường."""
    text = (value or "").replace("đ", "d").replace("Đ", "D")
    decomposed = unicodedata.normalize("NFD", text)
    without_marks = "".join(
        ch for ch in decomposed if unicodedata.category(ch) != "Mn"
    )
    return " ".join(without_marks.casefold().split())


def suggest(db: Session, query: str, limit: int = 8) -> List[Dict[str, Any]]:
    """Gợi ý gộp địa điểm + quán ăn theo tên, hỗ trợ tìm không dấu."""
    q = _normalize_vi(query)
    if not q:
        return []

    matches: List[Dict[str, Any]] = []
    for row in db.exec(select(Destination)).all():
        if q in _normalize_vi(row.name) or q in _normalize_vi(row.address or ""):
            matches.append(
                {
                    "id": f"d_{row.id}",
                    "name": row.name,
                    "kind": "sight",
                    "lat": row.latitude,
                    "lng": row.longitude,
                    "address": row.address or "",
                }
            )
    for row in db.exec(select(Restaurant)).all():
        haystack = " ".join(
            [
                row.name or "",
                row.address or "",
                row.cuisine_type or "",
                row.specialty_dishes or "",
            ]
        )
        if q in _normalize_vi(haystack):
            matches.append(
                {
                    "id": f"r_{row.id}",
                    "name": row.name,
                    "kind": "food",
                    "lat": row.latitude,
                    "lng": row.longitude,
                    "address": row.address or "",
                }
            )
    return matches[:limit]


def _project_stops_along_route(
    stops: List[Dict[str, Any]],
    polyline: List[tuple],
    corridor_radius_km: float,
) -> List[Dict[str, Any]]:
    """Chiếu từng điểm lên polyline và chỉ giữ điểm nằm trong hành lang."""
    if not stops or len(polyline) < 2:
        return []

    ref_lat = sum(p[0] for p in polyline) / float(len(polyline))
    ref_lng = sum(p[1] for p in polyline) / float(len(polyline))
    cos_ref = max(0.2, math.cos(math.radians(ref_lat)))

    def to_xy(lat: float, lng: float) -> tuple:
        return ((lng - ref_lng) * 111.32 * cos_ref, (lat - ref_lat) * 111.32)

    def to_lat_lng(x: float, y: float) -> tuple:
        return (
            round(ref_lat + (y / 111.32), 6),
            round(ref_lng + (x / (111.32 * cos_ref)), 6),
        )

    if not SHAPELY_AVAILABLE:
        # Fallback: so với các đỉnh polyline (đủ dùng khi Shapely không có).
        results = []
        for stop in stops:
            best = None
            for index, (plat, plng) in enumerate(polyline):
                dist = haversine_km(stop["latitude"], stop["longitude"], plat, plng)
                if best is None or dist < best[0]:
                    best = (dist, index, plat, plng)
            if best and best[0] <= corridor_radius_km:
                distance = round(best[0], 2)
                results.append(
                    {
                        **stop,
                        "distance_from_route_km": distance,
                        "detour_distance_km": round(distance * 2, 2),
                        "estimated_detour_mins": max(2, int(round(distance * 2 / 0.4)) + 1),
                        "route_progress_pct": round(best[1] / max(1, len(polyline) - 1) * 100, 1),
                        "nearest_route_point_lat": best[2],
                        "nearest_route_point_lng": best[3],
                    }
                )
        return sorted(results, key=lambda i: (i["route_progress_pct"], i["distance_from_route_km"]))

    route_line = LineString([to_xy(lat, lng) for lat, lng in polyline])
    total_len = max(0.01, route_line.length)
    results = []
    for stop in stops:
        point = Point(to_xy(stop["latitude"], stop["longitude"]))
        distance = float(route_line.distance(point))
        if distance > corridor_radius_km:
            continue
        progress = float(route_line.project(point))
        nearest = route_line.interpolate(progress)
        nearest_lat, nearest_lng = to_lat_lng(nearest.x, nearest.y)
        results.append(
            {
                **stop,
                "distance_from_route_km": round(distance, 2),
                "detour_distance_km": round(distance * 2, 2),
                "estimated_detour_mins": max(2, int(round(distance * 2 / 0.4)) + 1),
                "route_progress_pct": round(progress / total_len * 100, 1),
                "nearest_route_point_lat": nearest_lat,
                "nearest_route_point_lng": nearest_lng,
            }
        )
    results.sort(key=lambda i: (i["route_progress_pct"], i["distance_from_route_km"]))
    return results


def along_route(
    db: Session,
    polyline: List[tuple],
    corridor_radius_km: float = 2.0,
    kinds: Optional[List[str]] = None,
    limit: int = 40,
) -> List[Dict[str, Any]]:
    """Điểm nghỉ chân & quán cà phê nằm dọc hành lang tuyến đường."""
    wanted = set(kinds or ["rest", "gas", "ev", "cafe"])
    stops: List[Dict[str, Any]] = []

    category_to_kind = {
        "fuel": "gas",
        "ev": "ev",
        "rest": "rest",
        "viewpoint": "rest",
        "park": "rest",
        "toilet": "rest",
    }
    for row in db.exec(select(RestStop)).all():
        if (row.status or "published") != "published":
            continue
        kind = category_to_kind.get(row.category, "rest")
        if kind not in wanted:
            continue
        stops.append(
            {
                "id": f"rs_{row.id}",
                "name": row.name,
                "kind": kind,
                "stop_category": row.category,
                "address": row.address or "",
                "latitude": row.latitude,
                "longitude": row.longitude,
                "thumbnail_url": row.thumbnail_url or "",
                "rating": row.rating or 0,
                "review_count": row.review_count or 0,
            }
        )

    if "cafe" in wanted:
        for row in db.exec(select(Restaurant)).all():
            cuisine = (row.cuisine_type or "").lower()
            if not any(hint in cuisine for hint in KIND_TO_RESTAURANT_HINT["cafe"]):
                continue
            stops.append(
                {
                    "id": f"r_{row.id}",
                    "name": row.name,
                    "kind": "cafe",
                    "stop_category": "cafe",
                    "address": row.address or "",
                    "latitude": row.latitude,
                    "longitude": row.longitude,
                    "thumbnail_url": row.thumbnail_url or "",
                    "rating": row.rating or 0,
                    "review_count": row.review_count or 0,
                }
            )

    return _project_stops_along_route(stops, polyline, corridor_radius_km)[:limit]
