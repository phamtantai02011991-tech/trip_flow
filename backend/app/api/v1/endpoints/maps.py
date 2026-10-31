"""API Module 3 — chỉ đường thật."""

from typing import List

from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from app.db.session import get_db
from app.services import maps_service

router = APIRouter()


@router.get("/directions")
async def directions(
    origin_lat: float = Query(..., ge=-90, le=90),
    origin_lng: float = Query(..., ge=-180, le=180),
    dest_lat: float = Query(..., ge=-90, le=90),
    dest_lng: float = Query(..., ge=-180, le=180),
    waypoints: str = Query(default="", description="'lat,lng;lat,lng' — các điểm dừng"),
    vehicle: str = Query(default="motorbike", pattern="^(motorbike|car|coach)$"),
    db: Session = Depends(get_db),
):
    parsed: List[tuple] = []
    for chunk in waypoints.split(";"):
        chunk = chunk.strip()
        if not chunk or "," not in chunk:
            continue
        try:
            lat_str, lng_str = chunk.split(",", 1)
            parsed.append((float(lat_str), float(lng_str)))
        except ValueError:
            continue

    return await maps_service.get_route(
        db,
        origin=(origin_lat, origin_lng),
        destination=(dest_lat, dest_lng),
        waypoints=parsed,
        vehicle=vehicle,
    )
