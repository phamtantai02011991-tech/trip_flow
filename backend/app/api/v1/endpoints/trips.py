"""API chuyến đi: CRUD (Module 1, 6) + tạo lộ trình AI (Module 2)."""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import Session

from app.core.security import get_current_user, get_current_user_optional
from app.db.session import get_db
from app.models.models import User
from app.models.trip import Trip, TripStatus
from app.schemas.trip import (
    GenerateRequest,
    TripCreate,
    TripOut,
    TripStopIn,
    TripUpdate,
)
from app.services import trip_service
from app.services.ai.plan_service import InvalidPlan, generate_for_trip
from app.services.ai.gemini_client import GeminiError

router = APIRouter()


# --------------------------------------------------------------------------
# Quyền sở hữu
# --------------------------------------------------------------------------
def get_owned_trip(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
) -> Trip:
    """Trả 404 (không phải 403) khi không phải chủ, để không lộ sự tồn tại."""
    trip = trip_service.get_trip(db, trip_id)
    if trip is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy chuyến đi")
    if trip.user_id is None:
        return trip  # chuyến công khai / do khách tạo
    if current_user is None or trip.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Không tìm thấy chuyến đi")
    return trip


# --------------------------------------------------------------------------
# CRUD
# --------------------------------------------------------------------------
@router.get("", response_model=List[TripOut])
def list_trips(
    status_filter: Optional[str] = Query(default=None, alias="status"),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    trips = trip_service.list_trips(db, current_user.id if current_user else None, status_filter)
    return [trip_service.serialize_trip(db, t) for t in trips]


@router.post("", response_model=TripOut, status_code=status.HTTP_201_CREATED)
def create_trip(
    payload: TripCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    trip = trip_service.create_trip(db, payload, current_user.id if current_user else None)
    return trip_service.serialize_trip(db, trip)


@router.get("/{trip_id}", response_model=TripOut)
def get_trip(trip: Trip = Depends(get_owned_trip), db: Session = Depends(get_db)):
    return trip_service.serialize_trip(db, trip)


@router.put("/{trip_id}", response_model=TripOut)
def update_trip(
    payload: TripUpdate,
    trip: Trip = Depends(get_owned_trip),
    db: Session = Depends(get_db),
):
    updated = trip_service.update_trip(db, trip, payload)
    return trip_service.serialize_trip(db, updated)


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_trip(trip: Trip = Depends(get_owned_trip), db: Session = Depends(get_db)):
    trip_service.delete_trip(db, trip)
    return None


@router.post("/{trip_id}/duplicate", response_model=TripOut, status_code=201)
def duplicate_trip(
    trip: Trip = Depends(get_owned_trip),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    clone = trip_service.duplicate_trip(db, trip)
    return trip_service.serialize_trip(db, clone)


@router.post("/{trip_id}/share", response_model=TripOut)
def share_trip(trip: Trip = Depends(get_owned_trip), db: Session = Depends(get_db)):
    trip_service.share_trip(db, trip)
    return trip_service.serialize_trip(db, trip)


# --------------------------------------------------------------------------
# Điểm dừng
# --------------------------------------------------------------------------
@router.post("/{trip_id}/days/{day_number}/stops", response_model=TripOut, status_code=201)
def add_stop(
    day_number: int,
    payload: TripStopIn,
    trip: Trip = Depends(get_owned_trip),
    db: Session = Depends(get_db),
):
    trip_service.add_stop(db, trip, day_number, payload)
    return trip_service.serialize_trip(db, trip)


@router.delete("/{trip_id}/stops/{stop_id}", response_model=TripOut)
def delete_stop(
    stop_id: int,
    trip: Trip = Depends(get_owned_trip),
    db: Session = Depends(get_db),
):
    if not trip_service.delete_stop(db, trip, stop_id):
        raise HTTPException(status_code=404, detail="Không tìm thấy điểm dừng")
    return trip_service.serialize_trip(db, trip)


@router.put("/{trip_id}/days/{day_number}/reorder", response_model=TripOut)
def reorder_stops(
    day_number: int,
    ordered_ids: List[int],
    trip: Trip = Depends(get_owned_trip),
    db: Session = Depends(get_db),
):
    trip_service.reorder_stops(db, trip, day_number, ordered_ids)
    return trip_service.serialize_trip(db, trip)


# --------------------------------------------------------------------------
# Module 2 — AI tạo lộ trình
# --------------------------------------------------------------------------
@router.post("/{trip_id}/generate", response_model=TripOut)
async def generate_itinerary(
    payload: Optional[GenerateRequest] = None,
    trip: Trip = Depends(get_owned_trip),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Tạo lộ trình grounded: AI chỉ chọn trong danh sách địa điểm có thật."""
    feedback = payload.feedback if payload else None
    try:
        trip, info = await generate_for_trip(db, trip, feedback=feedback)
    except InvalidPlan as exc:
        raise HTTPException(
            status_code=422,
            detail={"code": "AI_INVALID_PLAN", "message": str(exc)},
        ) from exc
    except GeminiError as exc:
        raise HTTPException(
            status_code=exc.status,
            detail={"code": exc.code, "message": str(exc)},
        ) from exc

    result = trip_service.serialize_trip(db, trip)
    result.ai_generated = True
    return result


@router.get("/{trip_id}/ai-status")
def ai_status(trip: Trip = Depends(get_owned_trip)):
    """Thông tin phiên bản AI đã dùng để tạo lộ trình (model, token, chi phí ước tính)."""
    import json

    try:
        meta = json.loads(trip.generation_meta_json or "{}")
    except json.JSONDecodeError:
        meta = {}
    return {"trip_id": trip.id, "ai_generated": trip.ai_generated, "meta": meta}
