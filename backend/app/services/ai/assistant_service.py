"""Module 4 — AI Travel Assistant.

Cùng nguyên tắc "không bịa" như Module 2:
- Đưa AI danh sách địa điểm **có thật** + lộ trình hiện tại.
- AI trả JSON: `reply` (tư vấn) + `actions` (thêm/xoá điểm dừng) có `place_id`.
- Backend validate `place_id`, rồi mới thực thi — AI không tự ghi DB.
"""

import json
from typing import Any, Dict, List, Optional

from sqlmodel import Session

from app.models.trip import Trip
from app.schemas.trip import TripStopIn
from app.services import trip_service
from app.services.ai.gemini_client import GeminiError, gemini_client
from app.services.ai.plan_service import build_candidates


class AssistantError(RuntimeError):
    pass


CHAT_SCHEMA: Dict[str, Any] = {
    "type": "OBJECT",
    "properties": {
        "reply": {"type": "STRING"},
        "actions": {
            "type": "ARRAY",
            "maxItems": 5,
            "items": {
                "type": "OBJECT",
                "properties": {
                    "type": {"type": "STRING", "enum": ["add_stop", "remove_stop", "advice"]},
                    "place_id": {"type": "STRING"},
                    "stop_id": {"type": "INTEGER"},
                    "day": {"type": "INTEGER"},
                    "stay_min": {"type": "INTEGER"},
                    "reason": {"type": "STRING"},
                },
                "required": ["type"],
                "propertyOrdering": ["type", "place_id", "stop_id", "day", "stay_min", "reason"],
            },
        },
        "tips": {"type": "ARRAY", "items": {"type": "STRING"}, "maxItems": 4},
    },
    "required": ["reply"],
    "propertyOrdering": ["reply", "actions", "tips"],
}


def build_context(db: Session, trip: Optional[Trip]) -> tuple[str, List[Dict[str, Any]]]:
    if trip is None:
        return "Người dùng chưa mở chuyến đi nào.", []

    candidates = build_candidates(db, trip)
    current = []
    for day in trip_service.get_days(db, trip.id):
        for stop in trip_service.get_stops(db, day.id):
            current.append(
                {
                    "stop_id": stop.id,
                    "day": day.day_number,
                    "name": stop.name,
                    "kind": stop.kind,
                    "lat": round(stop.lat, 4),
                    "lng": round(stop.lng, 4),
                    "stay_min": stop.stay_mins,
                }
            )

    context = {
        "trip": {
            "title": trip.title,
            "origin": trip.origin_name,
            "destination": trip.destination_name,
            "total_days": trip.total_days,
            "party_size": trip.party_size,
            "vehicle": trip.vehicle.value,
            "budget_level": trip.budget_level.value,
            "budget_amount": trip.budget_amount,
        },
        "current_stops": current,
        "allowed_places": [
            {"id": c["id"], "name": c["name"], "kind": c["kind"],
             "rating": c["rating"], "hours": c["hours"]}
            for c in candidates
        ],
    }
    return json.dumps(context, ensure_ascii=False), candidates


def build_prompt(user_message: str, context_json: str) -> str:
    return "\n".join(
        [
            "Bạn là trợ lý du lịch TripFlow. Trả lời tiếng Việt, ngắn gọn, thực tế.",
            "NGỮ CẢNH (JSON):",
            context_json,
            "",
            "QUY TẮC:",
            "1. Chỉ được dùng place_id có trong 'allowed_places'. Không bịa địa điểm.",
            "2. Không bịa toạ độ, giờ mở cửa, giá, khoảng cách.",
            "3. Muốn thêm điểm dừng: action type=add_stop + place_id + day + stay_min.",
            "4. Muốn bỏ điểm dừng: action type=remove_stop + stop_id (lấy từ current_stops).",
            "5. Chỉ tư vấn (thời tiết, hành lý, ngân sách): action type=advice, không đổi lịch.",
            "6. 'reply' tối đa 120 từ. Trả JSON đúng schema.",
            "",
            f"CÂU HỎI NGƯỜI DÙNG: {user_message}",
        ]
    )


async def chat(
    db: Session, trip: Optional[Trip], message: str, model: Optional[str] = None
) -> Dict[str, Any]:
    context_json, candidates = build_context(db, trip)
    allowed = {c["id"]: c for c in candidates}

    raw = await gemini_client.generate_json(
        build_prompt(message, context_json), CHAT_SCHEMA, model=model, max_output_tokens=2048
    )
    meta = raw.pop("_meta", {})

    applied: List[Dict[str, Any]] = []
    rejected: List[str] = []

    for action in raw.get("actions", []) or []:
        kind = action.get("type")
        if kind == "add_stop":
            if trip is None:
                rejected.append("Không có chuyến đi để thêm điểm dừng")
                continue
            place_id = str(action.get("place_id", ""))
            cand = allowed.get(place_id)
            if cand is None:
                rejected.append(f"place_id không tồn tại: {place_id}")
                continue
            day = int(action.get("day") or 1)
            stay = action.get("stay_min")
            stop = trip_service.add_stop(
                db,
                trip,
                day,
                TripStopIn(
                    name=cand["name"],
                    address=cand.get("address", ""),
                    lat=cand["lat"],
                    lng=cand["lng"],
                    kind="restaurant" if cand["kind"] == "food" else "destination",
                    place_id=place_id,
                    ref_table="restaurants" if cand["kind"] == "food" else "destinations",
                    ref_id=int(place_id.split("_")[1]),
                    stay_mins=int(stay) if isinstance(stay, int) and 15 <= stay <= 240 else 60,
                    note=action.get("reason"),
                ),
                source="ai",
            )
            applied.append({"type": "add_stop", "stop_id": stop.id, "name": cand["name"], "day": day})

        elif kind == "remove_stop":
            if trip is None:
                continue
            stop_id = action.get("stop_id")
            if not isinstance(stop_id, int):
                rejected.append("remove_stop thiếu stop_id")
                continue
            if trip_service.delete_stop(db, trip, stop_id):
                applied.append({"type": "remove_stop", "stop_id": stop_id})
            else:
                rejected.append(f"stop_id không thuộc chuyến: {stop_id}")

    return {
        "reply": (raw.get("reply") or "").strip(),
        "tips": raw.get("tips", []) or [],
        "actions_applied": applied,
        "actions_rejected": rejected,
        "meta": meta,
    }
