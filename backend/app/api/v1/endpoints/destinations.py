from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.security import get_current_user_optional
from app.db.session import get_db
from app.models.models import Category, ContentReport, Destination, Restaurant, User
from app.repositories.repositories import (
    serialize_destination,
    serialize_restaurant,
)
from app.schemas.schemas import (
    ContentReportCreate,
    ContentReportOut,
    DestinationOut,
    PaginatedDestinations,
)
from app.services.geo_service import haversine_distance_km

router = APIRouter()


@router.get("", response_model=PaginatedDestinations)
def list_destinations(
    province_id: Optional[int] = Query(default=None, description="Lọc theo ID tỉnh/thành"),
    category_code: Optional[str] = Query(default=None, description="Mã danh mục (heritage, architecture, museum, market, street_walk)"),
    q: Optional[str] = Query(default=None, description="Từ khóa tìm kiếm tên, mô tả hoặc địa chỉ"),
    featured_only: bool = Query(default=False, description="Chỉ lấy địa điểm nổi bật"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """Tìm kiếm, lọc và phân trang danh sách địa điểm du lịch đang công bố (published)."""
    query = db.query(Destination).filter(Destination.status == "published")

    if province_id is not None:
        query = query.filter(Destination.province_id == province_id)

    if category_code and category_code != "all":
        cat = db.query(Category).filter(Category.code == category_code).first()
        if cat:
            query = query.filter(Destination.category_id == cat.id)
        else:
            return {"items": [], "total": 0, "page": page, "page_size": page_size}

    if featured_only:
        query = query.filter(Destination.is_featured == True)

    if q and q.strip():
        kw = f"%{q.strip()}%"
        query = query.filter(
            or_(
                Destination.name.ilike(kw),
                Destination.description.ilike(kw),
                Destination.address.ilike(kw),
            )
        )

    total = query.count()
    items = (
        query.order_by(Destination.is_featured.desc(), Destination.rating.desc(), Destination.id.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    return {
        "items": [serialize_destination(d) for d in items],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.get("/{destination_id}", response_model=Dict[str, Any])
def get_destination_detail(destination_id: int, db: Session = Depends(get_db)):
    """
    Xem chi tiết địa điểm du lịch kèm:
    - Bộ sưu tập ảnh và bản quyền ảnh
    - Thông tin nguồn dữ liệu & thời điểm cập nhật lần cuối
    - Các địa điểm liên quan và nhà hàng gần đó trong bán kính 2.5 km.
    """
    dest = (
        db.query(Destination)
        .filter(Destination.id == destination_id, Destination.status != "hidden")
        .first()
    )
    if not dest:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy địa điểm du lịch yêu cầu.",
        )

    data = serialize_destination(dest)

    # Tìm địa điểm liên quan cùng tỉnh
    other_dests = (
        db.query(Destination)
        .filter(
            Destination.province_id == dest.province_id,
            Destination.id != dest.id,
            Destination.status == "published",
        )
        .all()
    )
    related_destinations = []
    for od in other_dests:
        dist = haversine_distance_km(dest.latitude, dest.longitude, od.latitude, od.longitude)
        item = serialize_destination(od)
        item["distance_km"] = round(dist, 2)
        related_destinations.append(item)
    related_destinations.sort(key=lambda x: x["distance_km"])

    # Tìm nhà hàng gần địa điểm này
    prov_restaurants = (
        db.query(Restaurant)
        .filter(
            Restaurant.province_id == dest.province_id,
            Restaurant.status == "published",
        )
        .all()
    )
    nearby_restaurants = []
    for r in prov_restaurants:
        dist = haversine_distance_km(dest.latitude, dest.longitude, r.latitude, r.longitude)
        if dist <= 3.5:
            r_item = serialize_restaurant(r)
            r_item["distance_km"] = round(dist, 2)
            nearby_restaurants.append(r_item)
    nearby_restaurants.sort(key=lambda x: x["distance_km"])

    data["related_destinations"] = related_destinations[:4]
    data["nearby_restaurants"] = nearby_restaurants[:4]
    return data


@router.post(
    "/{destination_id}/report",
    response_model=ContentReportOut,
    status_code=status.HTTP_201_CREATED,
)
def report_destination_issue(
    destination_id: int,
    payload: ContentReportCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Người dùng gửi báo cáo sai thông tin hoặc đánh giá về địa điểm/nhà hàng (Mục 11)."""
    report = ContentReport(
        user_id=current_user.id if current_user else None,
        target_type=payload.target_type or "destination",
        target_id=payload.target_id or destination_id,
        target_name=payload.target_name,
        issue_type=payload.issue_type,
        description=payload.description,
        rating=payload.rating,
        status="pending",
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return report
