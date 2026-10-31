"""Nghiệp vụ chuyến đi (Module 1, 6): CRUD, sắp xếp điểm dừng, tổng hợp chi phí.

Mọi hàm nhận `db: Session` và **đã được kiểm tra quyền sở hữu ở tầng endpoint**
(`get_owned_trip`), service không tự xác thực người dùng.
"""

import json
import secrets
from datetime import datetime, timedelta
from typing import List, Optional

from sqlalchemy import func
from sqlmodel import Session, select

from app.models.trip import Expense, Trip, TripDay, TripStop
from app.schemas.trip import TripCreate, TripOut, TripStopIn, TripUpdate


# --------------------------------------------------------------------------
# Truy vấn
# --------------------------------------------------------------------------
def get_trip(db: Session, trip_id: int) -> Optional[Trip]:
    return db.get(Trip, trip_id)


def list_trips(db: Session, user_id: Optional[int], status: Optional[str] = None) -> List[Trip]:
    stmt = select(Trip)
    if user_id is None:
        # Khách chưa đăng nhập: trả các chuyến do khách tạo (user_id NULL).
        # Đây là hành vi cho bản demo; production nên bắt buộc đăng nhập.
        stmt = stmt.where(Trip.user_id.is_(None))
    else:
        stmt = stmt.where(Trip.user_id == user_id)
    if status:
        stmt = stmt.where(Trip.status == status)
    return list(db.exec(stmt.order_by(Trip.updated_at.desc())).all())


def get_days(db: Session, trip_id: int) -> List[TripDay]:
    return list(
        db.exec(select(TripDay).where(TripDay.trip_id == trip_id).order_by(TripDay.day_number)).all()
    )


def get_stops(db: Session, day_id: int) -> List[TripStop]:
    return list(
        db.exec(select(TripStop).where(TripStop.trip_day_id == day_id).order_by(TripStop.stop_order)).all()
    )


# --------------------------------------------------------------------------
# Tạo / cập nhật
# --------------------------------------------------------------------------
def create_trip(db: Session, payload: TripCreate, user_id: Optional[int]) -> Trip:
    trip = Trip(
        user_id=user_id,
        title=payload.title,
        province_id=payload.province_id,
        origin_name=payload.origin_name,
        origin_lat=payload.origin_lat,
        origin_lng=payload.origin_lng,
        destination_name=payload.destination_name,
        destination_lat=payload.destination_lat,
        destination_lng=payload.destination_lng,
        start_date=payload.start_date,
        total_days=payload.total_days,
        party_size=payload.party_size,
        vehicle=payload.vehicle,
        budget_level=payload.budget_level,
        budget_amount=payload.budget_amount,
        preferences_json=json.dumps(payload.preferences, ensure_ascii=False),
    )
    db.add(trip)
    db.commit()
    db.refresh(trip)

    # Sinh sẵn các ngày rỗng để UI có timeline ngay khi tạo
    for n in range(1, trip.total_days + 1):
        day = TripDay(
            trip_id=trip.id,
            day_number=n,
            date=(payload.start_date + timedelta(days=n - 1)) if payload.start_date else None,
            title=f"Ngày {n}",
        )
        db.add(day)
    db.commit()
    return trip


def update_trip(db: Session, trip: Trip, payload: TripUpdate) -> Trip:
    data = payload.model_dump(exclude_unset=True)
    prefs = data.pop("preferences", None)
    if prefs is not None:
        trip.preferences_json = json.dumps(prefs, ensure_ascii=False)
    for key, value in data.items():
        if value is not None:
            setattr(trip, key, value)
    trip.updated_at = datetime.utcnow()
    db.add(trip)
    db.commit()
    db.refresh(trip)
    return trip


def delete_trip(db: Session, trip: Trip) -> None:
    for day in get_days(db, trip.id):
        for stop in get_stops(db, day.id):
            db.delete(stop)
        db.delete(day)
    for expense in db.exec(select(Expense).where(Expense.trip_id == trip.id)).all():
        db.delete(expense)
    db.delete(trip)
    db.commit()


def share_trip(db: Session, trip: Trip) -> str:
    if not trip.share_token:
        trip.share_token = secrets.token_urlsafe(12)
        trip.updated_at = datetime.utcnow()
        db.add(trip)
        db.commit()
        db.refresh(trip)
    return trip.share_token


def duplicate_trip(db: Session, trip: Trip) -> Trip:
    clone = Trip(
        user_id=trip.user_id,
        title=f"{trip.title} (bản sao)",
        province_id=trip.province_id,
        origin_name=trip.origin_name,
        origin_lat=trip.origin_lat,
        origin_lng=trip.origin_lng,
        destination_name=trip.destination_name,
        destination_lat=trip.destination_lat,
        destination_lng=trip.destination_lng,
        start_date=trip.start_date,
        total_days=trip.total_days,
        party_size=trip.party_size,
        vehicle=trip.vehicle,
        budget_level=trip.budget_level,
        budget_amount=trip.budget_amount,
        preferences_json=trip.preferences_json,
        status=trip.status,
    )
    db.add(clone)
    db.commit()
    db.refresh(clone)

    for day in get_days(db, trip.id):
        new_day = TripDay(
            trip_id=clone.id, day_number=day.day_number, date=day.date, title=day.title, note=day.note
        )
        db.add(new_day)
        db.commit()
        db.refresh(new_day)
        for stop in get_stops(db, day.id):
            db.add(
                TripStop(
                    trip_day_id=new_day.id,
                    trip_id=clone.id,
                    stop_order=stop.stop_order,
                    kind=stop.kind,
                    place_id=stop.place_id,
                    ref_table=stop.ref_table,
                    ref_id=stop.ref_id,
                    name=stop.name,
                    address=stop.address,
                    lat=stop.lat,
                    lng=stop.lng,
                    arrive_at=stop.arrive_at,
                    stay_mins=stop.stay_mins,
                    est_cost=stop.est_cost,
                    source=stop.source,
                )
            )
    db.commit()
    return clone


# --------------------------------------------------------------------------
# Điểm dừng
# --------------------------------------------------------------------------
def add_stop(db: Session, trip: Trip, day_number: int, payload: TripStopIn, source: str = "manual") -> TripStop:
    day = db.exec(
        select(TripDay).where(TripDay.trip_id == trip.id, TripDay.day_number == day_number)
    ).first()
    if day is None:
        day = TripDay(trip_id=trip.id, day_number=day_number, title=f"Ngày {day_number}")
        db.add(day)
        db.commit()
        db.refresh(day)

    existing = get_stops(db, day.id)
    stop = TripStop(
        trip_day_id=day.id,
        trip_id=trip.id,
        stop_order=len(existing),
        kind=payload.kind,
        place_id=payload.place_id,
        ref_table=payload.ref_table,
        ref_id=payload.ref_id,
        name=payload.name,
        address=payload.address or "",
        lat=payload.lat,
        lng=payload.lng,
        arrive_at=payload.arrive_at,
        stay_mins=payload.stay_mins,
        est_cost=payload.est_cost,
        note=payload.note,
        source=source,
    )
    db.add(stop)
    db.commit()
    db.refresh(stop)
    return stop


def delete_stop(db: Session, trip: Trip, stop_id: int) -> bool:
    stop = db.get(TripStop, stop_id)
    if stop is None or stop.trip_id != trip.id:
        return False
    day_id = stop.trip_day_id
    db.delete(stop)
    db.commit()
    _resequence(db, day_id)
    return True


def reorder_stops(db: Session, trip: Trip, day_number: int, ordered_ids: List[int]) -> List[TripStop]:
    day = db.exec(
        select(TripDay).where(TripDay.trip_id == trip.id, TripDay.day_number == day_number)
    ).first()
    if day is None:
        return []
    stops = {s.id: s for s in get_stops(db, day.id)}
    position = 0
    for stop_id in ordered_ids:
        stop = stops.get(stop_id)
        if stop is None:
            continue
        stop.stop_order = position
        position += 1
        db.add(stop)
    db.commit()
    return get_stops(db, day.id)


def _resequence(db: Session, day_id: int) -> None:
    for index, stop in enumerate(get_stops(db, day_id)):
        if stop.stop_order != index:
            stop.stop_order = index
            db.add(stop)
    db.commit()


# --------------------------------------------------------------------------
# Tổng hợp
# --------------------------------------------------------------------------
def totals(db: Session, trip: Trip) -> dict:
    distance = 0.0
    travel = 0
    est = 0
    stops_total = 0
    for day in get_days(db, trip.id):
        for stop in get_stops(db, day.id):
            stops_total += 1
            distance += stop.distance_km_from_prev or 0.0
            travel += stop.travel_mins_from_prev or 0
            est += stop.est_cost or 0

    spent = (
        db.exec(
            select(func.coalesce(func.sum(Expense.amount), 0)).where(
                Expense.trip_id == trip.id, Expense.planned == False  # noqa: E712
            )
        ).first()
        or 0
    )
    return {
        "distance_km": round(distance, 1),
        "travel_mins": travel,
        "est_cost": est,
        "spent": int(spent),
        "stop_count": stops_total,
    }


def serialize_trip(db: Session, trip: Trip) -> TripOut:
    from app.schemas.trip import TripDayOut, TripOut, TripStopOut, TripTotals

    days_out = []
    for day in get_days(db, trip.id):
        days_out.append(
            TripDayOut(
                id=day.id,
                day_number=day.day_number,
                date=day.date,
                title=day.title,
                stops=[
                    TripStopOut(
                        id=s.id,
                        day_number=day.day_number,
                        order=s.stop_order,
                        kind=s.kind,
                        place_id=s.place_id,
                        name=s.name,
                        address=s.address,
                        lat=s.lat,
                        lng=s.lng,
                        arrive_at=s.arrive_at,
                        stay_mins=s.stay_mins,
                        travel_mins_from_prev=s.travel_mins_from_prev,
                        distance_km_from_prev=s.distance_km_from_prev,
                        est_cost=s.est_cost,
                        source=s.source,
                    )
                    for s in get_stops(db, day.id)
                ],
            )
        )

    try:
        prefs = json.loads(trip.preferences_json or "[]")
    except json.JSONDecodeError:
        prefs = []

    return TripOut(
        id=trip.id,
        title=trip.title,
        status=trip.status,
        origin_name=trip.origin_name,
        origin_lat=trip.origin_lat,
        origin_lng=trip.origin_lng,
        destination_name=trip.destination_name,
        destination_lat=trip.destination_lat,
        destination_lng=trip.destination_lng,
        start_date=trip.start_date,
        total_days=trip.total_days,
        party_size=trip.party_size,
        vehicle=trip.vehicle,
        budget_level=trip.budget_level,
        budget_amount=trip.budget_amount,
        preferences=prefs,
        days=days_out,
        totals=TripTotals(**totals(db, trip)),
        ai_generated=trip.ai_generated,
        share_token=trip.share_token,
        created_at=trip.created_at,
        updated_at=trip.updated_at,
    )
