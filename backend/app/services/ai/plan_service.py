"""Module 2 — Tạo lộ trình bằng AI, có ràng buộc "không bịa dữ liệu".

Luồng 5 bước:
1. Gom ứng viên THẬT từ DB (địa điểm + quán ăn của tỉnh).
2. Dựng prompt chỉ chứa ứng viên, yêu cầu AI chọn & xếp lịch.
3. Gọi Gemini, nhận JSON theo schema.
4. VALIDATE: mọi `place_id` phải nằm trong danh sách ứng viên; cái lạ bị loại.
5. Backend tự tính khoảng cách, thời gian di chuyển, chi phí, giờ đến.

AI không bao giờ sinh toạ độ / giờ mở cửa / giá.
"""

import json
import math
import re
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from sqlmodel import Session, select

from app.models.models import Destination, Restaurant
from app.models.trip import Trip, TripDay, TripStatus, TripStop
from app.services.ai.gemini_client import GeminiError, gemini_client


class InvalidPlan(RuntimeError):
    """AI trả về lộ trình không dùng được (toàn địa điểm ảo hoặc JSON sai cấu trúc)."""


# ---------------------------------------------------------------------------
# Hình học & chi phí
# ---------------------------------------------------------------------------
VEHICLE_KMH = {"motorbike": 42.0, "car": 48.0, "coach": 40.0}
FUEL_PER_KM = {"motorbike": 700, "car": 2600, "coach": 1200}
MEAL_COST = 80000
BREAK_COST = 30000


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    radius = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    )
    return 2 * radius * math.asin(math.sqrt(a))


def travel_minutes(distance_km: float, vehicle: str) -> int:
    speed = VEHICLE_KMH.get(vehicle, 45.0)
    # Hệ số 1.25 bù đường thực tế quanh co so với đường chim bay
    return max(3, round(distance_km * 1.25 / speed * 60))


def parse_price(text: Optional[str]) -> int:
    """Đọc giá vé dạng '50.000đ', '120k', 'Miễn phí' → số nguyên VND."""
    if not text:
        return 0
    lowered = text.lower()
    if "miễn phí" in lowered or "free" in lowered:
        return 0
    digits = re.sub(r"[^\d]", "", text)
    if not digits:
        return 0
    value = int(digits)
    if "k" in lowered and value < 1000:
        value *= 1000
    return value


# ---------------------------------------------------------------------------
# Ứng viên
# ---------------------------------------------------------------------------
def build_candidates(db: Session, trip: Trip, limit: int = 60) -> List[Dict[str, Any]]:
    candidates: List[Dict[str, Any]] = []

    dest_query = select(Destination)
    if trip.province_id:
        dest_query = dest_query.where(Destination.province_id == trip.province_id)
    destinations = db.exec(dest_query.limit(30)).all()

    for d in destinations:
        candidates.append(
            {
                "id": f"d_{d.id}",
                "name": d.name,
                "kind": "sight",
                "lat": d.latitude,
                "lng": d.longitude,
                "rating": d.rating,
                "hours": d.opening_hours or "",
                "price": d.ticket_price_info or "",
                "address": d.address or "",
                "stay_hint": d.recommended_duration_mins or 90,
            }
        )

    rest_query = select(Restaurant)
    if trip.province_id:
        rest_query = rest_query.where(Restaurant.province_id == trip.province_id)
    restaurants = db.exec(rest_query.limit(30)).all()

    for r in restaurants:
        candidates.append(
            {
                "id": f"r_{r.id}",
                "name": r.name,
                "kind": "food",
                "lat": r.latitude,
                "lng": r.longitude,
                "rating": r.rating,
                "hours": r.opening_hours or "",
                "price": r.price_range or "",
                "address": r.address or "",
                "stay_hint": 60,
            }
        )

    return candidates[:limit]


# ---------------------------------------------------------------------------
# Prompt & schema
# ---------------------------------------------------------------------------
PLAN_SCHEMA: Dict[str, Any] = {
    "type": "OBJECT",
    "properties": {
        "summary": {"type": "STRING"},
        "days": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "day": {"type": "INTEGER"},
                    "title": {"type": "STRING"},
                    "stops": {
                        "type": "ARRAY",
                        "maxItems": 8,
                        "items": {
                            "type": "OBJECT",
                            "properties": {
                                "place_id": {"type": "STRING"},
                                "arrive": {"type": "STRING"},
                                "stay_min": {"type": "INTEGER"},
                                "reason": {"type": "STRING"},
                            },
                            "required": ["place_id"],
                            "propertyOrdering": ["place_id", "arrive", "stay_min", "reason"],
                        },
                    },
                },
                "required": ["day", "stops"],
                "propertyOrdering": ["day", "title", "stops"],
            },
        },
        "tips": {"type": "ARRAY", "items": {"type": "STRING"}, "maxItems": 4},
    },
    "required": ["days"],
    "propertyOrdering": ["summary", "days", "tips"],
}


def build_prompt(trip: Trip, candidates: List[Dict[str, Any]], feedback: Optional[str] = None) -> str:
    prefs = []
    try:
        prefs = json.loads(trip.preferences_json or "[]")
    except json.JSONDecodeError:
        prefs = []

    compact = [
        {
            "id": c["id"],
            "name": c["name"],
            "kind": c["kind"],
            "lat": round(c["lat"], 5),
            "lng": round(c["lng"], 5),
            "rating": c["rating"],
            "hours": c["hours"],
            "price": c["price"],
        }
        for c in candidates
    ]

    lines = [
        "Bạn là chuyên gia lập lịch trình du lịch Việt Nam.",
        f"Chuyến đi: {trip.origin_name} → {trip.destination_name or 'tự chọn'}.",
        f"Thời lượng: {trip.total_days} ngày, {trip.party_size} người, "
        f"phương tiện {trip.vehicle.value}, ngân sách mức {trip.budget_level.value}"
        + (f" ({trip.budget_amount} VND)" if trip.budget_amount else "")
        + ".",
        f"Sở thích: {', '.join(prefs) if prefs else 'tự do'}.",
        "",
        "DANH SÁCH ĐỊA ĐIỂM ĐƯỢC PHÉP CHỌN (chỉ chọn trong đây):",
        json.dumps(compact, ensure_ascii=False),
        "",
        "QUY TẮC BẮT BUỘC:",
        "1. Chỉ dùng place_id có trong danh sách. KHÔNG tạo địa điểm mới.",
        "2. KHÔNG bịa toạ độ, giờ mở cửa, giá vé, khoảng cách — backend tự tính.",
        "3. Mỗi ngày 3–6 điểm, có bữa ăn (kind=food) và điểm tham quan.",
        "4. Không lặp lại một địa điểm ở nhiều ngày.",
        "5. Ưu tiên điểm đúng sở thích và gần nhau để giảm di chuyển.",
        "6. 'reason' tối đa 20 từ, không chứa số liệu.",
        "7. Trả JSON đúng schema, không thêm chữ ngoài JSON.",
    ]
    if feedback:
        lines.append(f"8. Yêu cầu điều chỉnh của người dùng: {feedback}")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Validate
# ---------------------------------------------------------------------------
def validate_plan(plan: Dict[str, Any], candidates: List[Dict[str, Any]]) -> Tuple[List[Dict[str, Any]], List[str]]:
    allowed = {c["id"]: c for c in candidates}
    problems: List[str] = []
    days_out: List[Dict[str, Any]] = []
    seen: set[str] = set()

    for day in plan.get("days", []) or []:
        stops_out: List[Dict[str, Any]] = []
        for stop in day.get("stops", []) or []:
            place_id = str(stop.get("place_id", ""))
            if place_id not in allowed:
                problems.append(f"hallucinated place_id: {place_id}")
                continue
            if place_id in seen:
                problems.append(f"duplicate place_id: {place_id}")
                continue
            seen.add(place_id)
            stops_out.append({"raw": stop, "candidate": allowed[place_id]})
        if stops_out:
            days_out.append(
                {
                    "day": int(day.get("day") or len(days_out) + 1),
                    "title": day.get("title") or "",
                    "stops": stops_out,
                }
            )

    if not days_out:
        raise InvalidPlan("AI không chọn được địa điểm nào có thật")
    return days_out, problems


# ---------------------------------------------------------------------------
# Sinh lộ trình
# ---------------------------------------------------------------------------
async def generate_for_trip(
    db: Session,
    trip: Trip,
    feedback: Optional[str] = None,
    model: Optional[str] = None,
) -> Tuple[Trip, Dict[str, Any]]:
    candidates = build_candidates(db, trip)
    if not candidates:
        raise InvalidPlan("Tỉnh này chưa có dữ liệu địa điểm để lập lịch")

    prompt = build_prompt(trip, candidates, feedback)
    raw = await gemini_client.generate_json(prompt, PLAN_SCHEMA, model=model)
    meta = raw.pop("_meta", {})

    days, problems = validate_plan(raw, candidates)

    # Xoá các điểm do AI tạo trước đó, giữ điểm người dùng tự thêm
    for day in db.exec(select(TripDay).where(TripDay.trip_id == trip.id)).all():
        for stop in db.exec(
            select(TripStop).where(TripStop.trip_day_id == day.id, TripStop.source == "ai")
        ).all():
            db.delete(stop)
    db.commit()

    # Đảm bảo đủ TripDay
    existing_days = {
        d.day_number: d
        for d in db.exec(select(TripDay).where(TripDay.trip_id == trip.id)).all()
    }
    for index in range(1, trip.total_days + 1):
        if index not in existing_days:
            day = TripDay(
                trip_id=trip.id,
                day_number=index,
                date=(trip.start_date + timedelta(days=index - 1)) if trip.start_date else None,
                title=f"Ngày {index}",
            )
            db.add(day)
            db.commit()
            db.refresh(day)
            existing_days[index] = day

    fuel_rate = FUEL_PER_KM.get(trip.vehicle.value, 1500)
    start_hour = 7
    total_cost = 0

    for day_data in days:
        day_number = day_data["day"]
        day = existing_days.get(day_number) or existing_days[min(existing_days)]
        day.title = day_data["title"] or f"Ngày {day_number}"
        db.add(day)

        clock = datetime.combine(
            (trip.start_date + timedelta(days=day_number - 1)) if trip.start_date else datetime.now(timezone.utc).date(),
            datetime.min.time(),
        ).replace(tzinfo=timezone.utc) + timedelta(hours=start_hour)

        prev_lat, prev_lng = trip.origin_lat, trip.origin_lng
        for order, item in enumerate(day_data["stops"]):
            cand = item["candidate"]
            distance = haversine_km(prev_lat, prev_lng, cand["lat"], cand["lng"])
            travel = travel_minutes(distance, trip.vehicle.value)
            clock += timedelta(minutes=travel)

            stay = int(cand.get("stay_hint") or 60)
            raw_stay = item["raw"].get("stay_min")
            if isinstance(raw_stay, int) and 15 <= raw_stay <= 240:
                stay = raw_stay

            entry_fee = parse_price(cand.get("price"))
            food_cost = MEAL_COST if cand["kind"] == "food" else 0
            fuel_cost = round(distance * fuel_rate)
            est_cost = entry_fee + food_cost + fuel_cost
            total_cost += est_cost

            db.add(
                TripStop(
                    trip_day_id=day.id,
                    trip_id=trip.id,
                    stop_order=order,
                    kind="restaurant" if cand["kind"] == "food" else "destination",
                    place_id=cand["id"],
                    ref_table="restaurants" if cand["kind"] == "food" else "destinations",
                    ref_id=int(cand["id"].split("_")[1]),
                    name=cand["name"],
                    address=cand.get("address", ""),
                    lat=cand["lat"],
                    lng=cand["lng"],
                    arrive_at=clock,
                    stay_mins=stay,
                    travel_mins_from_prev=travel,
                    distance_km_from_prev=round(distance, 1),
                    est_cost=est_cost,
                    note=item["raw"].get("reason"),
                    source="ai",
                )
            )
            clock += timedelta(minutes=stay)
            prev_lat, prev_lng = cand["lat"], cand["lng"]

    trip.ai_generated = True
    trip.status = TripStatus.planned
    trip.updated_at = datetime.now(timezone.utc)
    trip.generation_meta_json = json.dumps(
        {
            "model": meta.get("model"),
            "tokens_in": meta.get("tokens_in"),
            "tokens_out": meta.get("tokens_out"),
            "latency_ms": meta.get("latency_ms"),
            "hallucinations_removed": len(problems),
            "estimated_cost": total_cost,
        },
        ensure_ascii=False,
    )
    db.add(trip)
    db.commit()
    db.refresh(trip)

    return trip, {"meta": meta, "problems": problems, "candidates": len(candidates)}
