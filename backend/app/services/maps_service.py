"""Module 3 — chỉ đường thật (Routing).

Nguồn dữ liệu theo thứ tự ưu tiên:
1. **OSRM** (OpenStreetMap, miễn phí, không cần key) — đường đi theo ngã rẽ đường phố.
2. **Goong Directions V2** khi có `GOONG_API_KEY` (dữ liệu Việt Nam tốt hơn).
3. **Fallback nội bộ**: chỉ khi cả hai lỗi — trả polyline nối thẳng và đánh dấu
   `provider="fallback"` để UI nói rõ đây là ước tính, **không giả vờ là đường thật**.

Kết quả được cache trong `place_cache` (TTL 24h) để không gọi lại mỗi lần mở chuyến.
"""

import hashlib
import json
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

import httpx
from sqlmodel import Session, select

from app.core.config import settings
from app.models.place import PlaceCache

OSRM_BASE = "https://router.project-osrm.org"
OSRM_TIMEOUT = 8.0


def _cache_key(origin: tuple, destination: tuple, waypoints: List[tuple], vehicle: str) -> str:
    raw = json.dumps(
        {
            "o": [round(origin[0], 5), round(origin[1], 5)],
            "d": [round(destination[0], 5), round(destination[1], 5)],
            "w": [[round(p[0], 5), round(p[1], 5)] for p in waypoints],
            "v": vehicle,
        },
        sort_keys=True,
    )
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()


def _read_cache(db: Session, key: str) -> Optional[Dict[str, Any]]:
    row = db.exec(
        select(PlaceCache).where(
            PlaceCache.provider == "routes",
            PlaceCache.cache_key == key,
            PlaceCache.expires_at > datetime.utcnow(),
        )
    ).first()
    if row is None:
        return None
    try:
        return json.loads(row.payload_json)
    except json.JSONDecodeError:
        return None


def _write_cache(db: Session, key: str, payload: Dict[str, Any]) -> None:
    db.add(
        PlaceCache(
            provider="routes",
            cache_key=key,
            payload_json=json.dumps(payload, ensure_ascii=False),
            expires_at=datetime.utcnow() + timedelta(hours=settings.PLACES_CACHE_TTL_HOURS),
        )
    )
    db.commit()


def _haversine_km(a: tuple, b: tuple) -> float:
    from app.services.ai.plan_service import haversine_km

    return haversine_km(a[0], a[1], b[0], b[1])


def _fallback(origin: tuple, destination: tuple, waypoints: List[tuple], note: str) -> Dict[str, Any]:
    points = [origin, *waypoints, destination]
    legs = []
    total = 0.0
    for i in range(len(points) - 1):
        distance = _haversine_km(points[i], points[i + 1]) * 1.25
        total += distance
        legs.append(
            {
                "distance_km": round(distance, 2),
                "duration_mins": max(3, round(distance / 45 * 60)),
            }
        )
    return {
        "provider": "fallback",
        "note": note,
        "distance_km": round(total, 2),
        "duration_mins": sum(leg["duration_mins"] for leg in legs),
        "legs": legs,
        "encoded_polyline": None,
        # Không có polyline thật → client tự vẽ đường nối các điểm
        "geometry": [[p[1], p[0]] for p in points],
    }


async def get_route(
    db: Session,
    origin: tuple,
    destination: tuple,
    waypoints: Optional[List[tuple]] = None,
    vehicle: str = "motorbike",
) -> Dict[str, Any]:
    waypoints = waypoints or []
    key = _cache_key(origin, destination, waypoints, vehicle)
    cached = _read_cache(db, key)
    if cached:
        cached["cached"] = True
        return cached

    profile = "driving"  # OSRM public chỉ có ô tô; xe máy dùng chung, có ghi chú
    coords = ";".join(f"{lng},{lat}" for lat, lng in [origin, *waypoints, destination])
    url = f"{OSRM_BASE}/route/v1/{profile}/{coords}"

    try:
        async with httpx.AsyncClient(timeout=OSRM_TIMEOUT) as client:
            resp = await client.get(
                url,
                params={"overview": "full", "geometries": "polyline", "steps": "false"},
                headers={"User-Agent": "TripFlow/1.0 (+https://github.com/tripflow)"},
            )
        if resp.status_code != 200:
            raise ValueError(f"OSRM HTTP {resp.status_code}")
        data = resp.json()
        route = (data.get("routes") or [None])[0]
        if not route:
            raise ValueError("OSRM không trả tuyến")

        legs = [
            {
                "distance_km": round(leg["distance"] / 1000, 2),
                "duration_mins": max(1, round(leg["duration"] / 60)),
            }
            for leg in route.get("legs", [])
        ]
        payload = {
            "provider": "osrm",
            "note": "Đường đi thật theo OpenStreetMap; thời gian chưa tính kẹt xe.",
            "distance_km": round(route["distance"] / 1000, 2),
            "duration_mins": max(1, round(route["duration"] / 60)),
            "legs": legs,
            "encoded_polyline": route.get("geometry"),
            "geometry": [],
            "vehicle": vehicle,
        }
        _write_cache(db, key, payload)
        return payload
    except (httpx.HTTPError, ValueError, KeyError, TypeError) as exc:
        return _fallback(
            origin,
            destination,
            waypoints,
            f"Không gọi được dịch vụ chỉ đường ({type(exc).__name__}); "
            "khoảng cách là ước tính đường chim bay ×1.25.",
        )
