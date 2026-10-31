"""API Module 5 — tìm quanh đây, gợi ý tìm kiếm, lịch sử tìm kiếm."""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import Field
from sqlmodel import Session, select
from sqlmodel import SQLModel

from app.core.security import get_current_user, get_current_user_optional
from app.db.session import get_db
from app.models.models import User
from app.models.place import SearchHistory
from app.services import places_service

router = APIRouter()


class HistoryCreate(SQLModel):
    query: str = Field(min_length=1, max_length=200)
    kind: str = Field(default="text", max_length=24)
    place_id: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None


@router.get("/nearby")
def nearby(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(default=3.0, ge=0.5, le=10.0),
    kinds: str = Query(default="food", description="food,cafe,hotel,gas,ev,rest,sight"),
    min_rating: float = Query(default=0.0, ge=0.0, le=5.0),
    open_now: bool = Query(default=False),
    sort_by: str = Query(default="distance", pattern="^(distance|rating|price|quality)$"),
    vehicle: str = Query(default="motorbike", pattern="^(motorbike|car|coach)$"),
    max_price: int = Query(default=0, ge=0, description="Giá tối đa (VND), 0 = không lọc"),
    limit: int = Query(default=40, ge=1, le=100),
    db: Session = Depends(get_db),
):
    kind_list = [k.strip() for k in kinds.split(",") if k.strip()]
    return places_service.nearby(
        db, lat, lng, radius_km, kind_list, min_rating, open_now, sort_by, vehicle, limit, max_price
    )


@router.get("/suggest")
def suggest(q: str = Query(..., min_length=2, max_length=100), db: Session = Depends(get_db)):
    return places_service.suggest(db, q)


@router.get("/history")
def list_history(
    limit: int = Query(default=10, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    if current_user is None:
        return []
    rows = db.exec(
        select(SearchHistory)
        .where(SearchHistory.user_id == current_user.id)
        .order_by(SearchHistory.created_at.desc())
        .limit(limit)
    ).all()
    return [
        {"id": r.id, "query": r.query, "kind": r.kind, "place_id": r.place_id, "created_at": r.created_at}
        for r in rows
    ]


@router.post("/history", status_code=201)
def add_history(
    payload: HistoryCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    if current_user is None:
        return {"status": "ignored"}  # khách: lịch sử lưu cục bộ ở app

    # Tránh trùng lặp liên tiếp cùng một truy vấn
    last = db.exec(
        select(SearchHistory)
        .where(SearchHistory.user_id == current_user.id)
        .order_by(SearchHistory.created_at.desc())
        .limit(1)
    ).first()
    if last and last.query == payload.query and last.kind == payload.kind:
        return {"status": "duplicate", "id": last.id}

    row = SearchHistory(
        user_id=current_user.id,
        query=payload.query,
        kind=payload.kind,
        place_id=payload.place_id,
        lat=payload.lat,
        lng=payload.lng,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return {"status": "created", "id": row.id}


@router.delete("/history/{item_id}", status_code=204)
def delete_history(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    row = db.get(SearchHistory, item_id)
    if row is None or row.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Không tìm thấy mục lịch sử")
    db.delete(row)
    db.commit()
    return None


@router.delete("/history", status_code=204)
def clear_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    for row in db.exec(select(SearchHistory).where(SearchHistory.user_id == current_user.id)).all():
        db.delete(row)
    db.commit()
    return None
