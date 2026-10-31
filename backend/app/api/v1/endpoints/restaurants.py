from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import or_
from sqlmodel import Session

from app.core.config import settings
from app.core.rate_limit import enforce_corridor_rate_limit, limiter
from app.db.session import get_db
from app.integrations.maps_client import maps_proxy
from app.models.models import Restaurant
from app.repositories.repositories import serialize_restaurant
from app.schemas.schemas import (
    RestaurantOut,
    RouteCorridorRequest,
    RouteCorridorResponse,
)
from app.services.geo_service import (
    compute_route_bounding_box,
    filter_restaurants_by_bounding_box,
    find_restaurants_along_corridor_shapely,
    haversine_distance_km,
)

router = APIRouter()


@router.get("", response_model=List[RestaurantOut])
def list_restaurants(
    province_id: Optional[int] = Query(default=None, description="Lọc theo ID tỉnh/thành"),
    cuisine_type: Optional[str] = Query(default=None, description="Lọc theo loại hình ẩm thực"),
    sort_by: Optional[str] = Query(default="rating", description="rating | reviews_count | distance"),
    min_rating: Optional[float] = Query(default=None, description="Lọc rating tối thiểu, vd 4.5"),
    min_reviews: Optional[int] = Query(default=None, description="Lọc số lượt đánh giá tối thiểu, vd 100"),
    is_high_rated: Optional[bool] = Query(default=None, description="Chỉ lấy quán đánh giá cao"),
    q: Optional[str] = Query(default=None, description="Từ khóa tìm kiếm tên quán, món ăn, địa chỉ hoặc trong nội dung bình luận"),
    lat: Optional[float] = Query(default=None, description="Vĩ độ người dùng hiện tại"),
    lng: Optional[float] = Query(default=None, description="Kinh độ người dùng hiện tại"),
    radius_km: Optional[float] = Query(default=None, description="Bán kính lọc quanh vị trí (km)"),
    db: Session = Depends(get_db),
):
    """Lấy danh sách nhà hàng/quán ăn kèm lọc theo ẩm thực, rating, số lượng review, từ khóa (cả trong review) hoặc tọa độ lân cận."""
    query = db.query(Restaurant).filter(Restaurant.status == "published")

    if province_id is not None:
        query = query.filter(Restaurant.province_id == province_id)

    if cuisine_type and cuisine_type != "all":
        query = query.filter(Restaurant.cuisine_type.ilike(f"%{cuisine_type}%"))

    if min_rating is not None:
        query = query.filter(Restaurant.rating >= min_rating)

    if min_reviews is not None:
        query = query.filter(Restaurant.reviews_count >= min_reviews)

    if is_high_rated is not None:
        query = query.filter(Restaurant.is_high_rated == is_high_rated)

    if q and q.strip():
        kw = f"%{q.strip()}%"
        query = query.filter(
            or_(
                Restaurant.name.ilike(kw),
                Restaurant.specialty_dishes.ilike(kw),
                Restaurant.specialties.ilike(kw),
                Restaurant.address.ilike(kw),
                Restaurant.cuisine_type.ilike(kw),
                Restaurant.sample_reviews_json.ilike(kw),
            )
        )

    if sort_by == "reviews_count":
        items = query.order_by(
            Restaurant.reviews_count.desc(), Restaurant.rating.desc(), Restaurant.id.asc()
        ).all()
    else:
        items = query.order_by(
            Restaurant.rating.desc(), Restaurant.reviews_count.desc(), Restaurant.id.asc()
        ).all()

    serialized = [serialize_restaurant(r) for r in items]

    if lat is not None and lng is not None:
        max_r = radius_km or 10.0
        filtered = []
        for item in serialized:
            dist = haversine_distance_km(lat, lng, item["latitude"], item["longitude"])
            if radius_km is None or dist <= max_r:
                item["distance_km"] = round(dist, 2)
                filtered.append(item)
        if sort_by == "distance":
            filtered.sort(key=lambda x: x.get("distance_km", 999.0))
        return filtered

    return serialized


@router.post("/corridor-search", response_model=RouteCorridorResponse)
@limiter.limit("10/minute")
def search_restaurants_on_route_corridor(
    request: Request,
    payload: RouteCorridorRequest,
    db: Session = Depends(get_db),
):
    """
    Thực thi tính năng cốt lõi Tìm nhà hàng trên lộ trình (Corridor Search - Pitfall #1 & #6):
    1. Kiểm soát Rate Limit tối đa 10 lần/phút/IP bằng `slowapi` để bảo vệ hạn mức Goong Maps API.
    2. Gọi `GoongMapsService` lấy chuỗi `encoded_polyline` của tuyến đường từ A đến B và giải mã ra danh sách tọa độ.
    3. Tính hình chữ nhật bao quanh tuyến đường (**Bounding Box**) và lọc sơ bộ trên Database qua B-Tree Index `(latitude, longitude)`.
    4. Dùng thư viện hình học **`Shapely` (`LineString`, `Point`)** tính khoảng cách vuông góc chính xác từ từng nhà hàng tới tuyến đường (`<= corridor_radius_km`, mặc định `< 2km`).
    """
    enforce_corridor_rate_limit(request, max_calls=10, window_seconds=60)

    safe_radius = min(max(0.2, payload.corridor_radius_km), settings.MAX_CORRIDOR_RADIUS_KM)

    waypoints_tuples = None
    if payload.waypoints:
        waypoints_tuples = [(w.lat, w.lng) for w in payload.waypoints]

    (
        polyline_tuples,
        total_distance_km,
        encoded_polyline,
        provider_name,
    ) = maps_proxy.get_route_with_encoded_polyline(
        origin_lat=payload.origin_lat,
        origin_lng=payload.origin_lng,
        dest_lat=payload.destination_lat,
        dest_lng=payload.destination_lng,
        waypoints=waypoints_tuples,
    )

    # Bước 3: Tính Bounding Box quanh tuyến đường và lọc sơ bộ trên DB bằng B-Tree Index
    bbox = compute_route_bounding_box(polyline_tuples, safe_radius)
    bbox_candidates = filter_restaurants_by_bounding_box(
        db=db,
        bbox=bbox,
        province_id=payload.province_id,
    )

    # Bước 4: Dùng Shapely (LineString & Point) tính khoảng cách vuông góc chính xác
    matched_restaurants = find_restaurants_along_corridor_shapely(
        restaurants=bbox_candidates,
        polyline=polyline_tuples,
        corridor_radius_km=safe_radius,
        cuisine_filter=payload.cuisine_filter,
    )

    return {
        "origin_name": payload.origin_name or "Điểm xuất phát",
        "destination_name": payload.destination_name or "Điểm đến",
        "total_route_distance_km": total_distance_km,
        "corridor_radius_km": safe_radius,
        "encoded_polyline": encoded_polyline,
        "maps_provider": provider_name,
        "bounding_box": bbox,
        "candidates_in_bbox_count": len(bbox_candidates),
        "shapely_engine_used": True,
        "polyline": [{"lat": pt[0], "lng": pt[1]} for pt in polyline_tuples],
        "results_count": len(matched_restaurants),
        "restaurants": matched_restaurants,
    }


@router.get("/on-route", response_model=RouteCorridorResponse)
@limiter.limit("10/minute")
def get_restaurants_on_route_query(
    request: Request,
    origin_lat: float = Query(..., description="Vĩ độ điểm xuất phát"),
    origin_lng: float = Query(..., description="Kinh độ điểm xuất phát"),
    destination_lat: float = Query(..., description="Vĩ độ điểm đến"),
    destination_lng: float = Query(..., description="Kinh độ điểm đến"),
    corridor_radius_km: float = Query(default=2.0, ge=0.2, le=10.0),
    province_id: Optional[int] = Query(default=1),
    cuisine_filter: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
):
    """GET wrapper tiện lợi cho tính năng tìm nhà hàng dọc lộ trình (có bảo vệ Rate Limit 10/minute)."""
    req = RouteCorridorRequest(
        province_id=province_id,
        origin_lat=origin_lat,
        origin_lng=origin_lng,
        destination_lat=destination_lat,
        destination_lng=destination_lng,
        corridor_radius_km=corridor_radius_km,
        cuisine_filter=cuisine_filter,
    )
    return search_restaurants_on_route_corridor(request=request, payload=req, db=db)


@router.get("/{restaurant_id}", response_model=RestaurantOut)
def get_restaurant_detail(restaurant_id: int, db: Session = Depends(get_db)):
    """Xem thông tin chi tiết một nhà hàng (luôn kèm thời điểm cập nhật lần cuối và lời nhắc kiểm tra giờ mở cửa)."""
    rest = (
        db.query(Restaurant)
        .filter(Restaurant.id == restaurant_id, Restaurant.status != "hidden")
        .first()
    )
    if not rest:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy nhà hàng yêu cầu.",
        )
    return serialize_restaurant(rest)
