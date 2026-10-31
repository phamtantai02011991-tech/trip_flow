from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlmodel import Session

from app.core.security import get_current_user_optional
from app.db.session import get_db
from app.models.models import Itinerary, User
from app.repositories.repositories import serialize_itinerary
from app.schemas.schemas import (
    ItineraryCreate,
    ItineraryOut,
    ItineraryStopIn,
    ItinerarySyncRequest,
    ItineraryUpdate,
    SmartMealStopRequest,
    SmartMealStopResponse,
)
from app.services.itinerary_service import (
    add_stop_to_itinerary,
    create_itinerary_with_stops,
    suggest_and_insert_smart_meal_stop,
    sync_itinerary_from_offline,
    update_itinerary_and_stops,
)

router = APIRouter()


@router.get("", response_model=List[ItineraryOut])
def list_itineraries(
    province_id: Optional[int] = Query(default=None, description="Lọc theo tỉnh/thành"),
    templates_only: bool = Query(default=False, description="Chỉ lấy các lịch trình mẫu của Admin"),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Lấy danh sách lịch trình mẫu gợi ý và lịch trình cá nhân đã lưu."""
    query = db.query(Itinerary).filter(Itinerary.status != "archived")

    if province_id is not None:
        query = query.filter(Itinerary.province_id == province_id)

    if templates_only:
        query = query.filter(Itinerary.is_template == True)
    elif current_user:
        query = query.filter(
            or_(
                Itinerary.is_template == True,
                Itinerary.user_id == current_user.id,
                Itinerary.user_id == None,
            )
        )

    items = query.order_by(Itinerary.is_template.desc(), Itinerary.updated_at.desc()).all()
    return [serialize_itinerary(i) for i in items]


@router.post("", response_model=ItineraryOut, status_code=status.HTTP_201_CREATED)
def create_itinerary(
    payload: ItineraryCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Tạo lịch trình tham quan mới (hỗ trợ cả người dùng đã đăng nhập và chế độ Khách)."""
    itin = create_itinerary_with_stops(db=db, payload=payload, current_user=current_user)
    return serialize_itinerary(itin)


@router.post("/sync", response_model=ItineraryOut)
def sync_offline_itinerary(
    payload: ItinerarySyncRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """
    Đồng bộ lịch trình đã lưu local trong Hive từ ứng dụng Flutter lên Server khi có mạng trở lại (Pitfall #5).
    """
    itin = sync_itinerary_from_offline(db=db, payload=payload, current_user=current_user)
    return serialize_itinerary(itin)


@router.get("/{itinerary_id}", response_model=ItineraryOut)
def get_itinerary_detail(itinerary_id: int, db: Session = Depends(get_db)):
    """Xem chi tiết một lịch trình tham quan kèm danh sách các điểm dừng theo thứ tự."""
    itin = db.query(Itinerary).filter(Itinerary.id == itinerary_id).first()
    if not itin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch trình yêu cầu.",
        )
    return serialize_itinerary(itin)


@router.put("/{itinerary_id}", response_model=ItineraryOut)
def update_itinerary(
    itinerary_id: int,
    payload: ItineraryUpdate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Cập nhật thông tin lịch trình, thêm/xóa hoặc sắp xếp lại thứ tự điểm dừng."""
    itin = db.query(Itinerary).filter(Itinerary.id == itinerary_id).first()
    if not itin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch trình cần cập nhật.",
        )

    updated = update_itinerary_and_stops(db=db, itinerary=itin, payload=payload)
    return serialize_itinerary(updated)


@router.post("/{itinerary_id}/stops", response_model=ItineraryOut)
def add_stop_endpoint(
    itinerary_id: int,
    payload: ItineraryStopIn,
    db: Session = Depends(get_db),
):
    """Thêm nhanh một điểm dừng (địa điểm, nhà hàng hoặc điểm trên lộ trình) vào lịch trình."""
    itin = db.query(Itinerary).filter(Itinerary.id == itinerary_id).first()
    if not itin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch trình.",
        )

    updated = add_stop_to_itinerary(db=db, itinerary=itin, stop_in=payload)
    return serialize_itinerary(updated)


@router.delete("/{itinerary_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_itinerary(itinerary_id: int, db: Session = Depends(get_db)):
    """Xóa một lịch trình."""
    itin = db.query(Itinerary).filter(Itinerary.id == itinerary_id).first()
    if not itin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch trình cần xóa.",
        )
    db.delete(itin)
    db.commit()
    return None


@router.post("/{itinerary_id}/smart-meal-stops", response_model=SmartMealStopResponse)
def insert_smart_meal_stop_endpoint(
    itinerary_id: int,
    payload: SmartMealStopRequest,
    db: Session = Depends(get_db),
):
    """
    Tự động phân tích khoảng cách di chuyển giữa các điểm tham quan trong ngày,
    tìm kiếm nhà hàng có điểm Smart Food Corridor Score (SFCS) cao nhất và tự động chèn điểm dừng ăn uống.
    """
    return suggest_and_insert_smart_meal_stop(
        db=db,
        itinerary_id=itinerary_id,
        day_number=payload.day_number,
        preferred_time=payload.preferred_time or "12:00",
        corridor_radius_km=payload.corridor_radius_km,
        cuisine_filter=payload.cuisine_filter,
    )
