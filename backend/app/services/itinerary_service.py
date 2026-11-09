from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status
from sqlmodel import Session

from app.core.config import settings
from app.integrations.maps_client import maps_proxy
from app.models.models import Itinerary, ItineraryStop, Restaurant, User
from app.repositories.repositories import serialize_restaurant
from app.schemas.schemas import (
    ItineraryCreate,
    ItineraryStopIn,
    ItinerarySyncRequest,
    ItineraryUpdate,
)
from app.services.geo_service import (
    calculate_smart_corridor_score,
    compute_route_bounding_box,
    filter_restaurants_by_bounding_box,
    find_restaurants_along_corridor_shapely,
    haversine_distance_km,
)


def _normalize_stops_Input(stops_in: List[ItineraryStopIn]) -> List[ItineraryStopIn]:
    """Kiểm tra giới hạn số điểm dừng và tự động chuẩn hóa lại stop_order liên tiếp."""
    if len(stops_in) > settings.MAX_ITINERARY_STOPS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Mỗi lịch trình chỉ được phép tối đa {settings.MAX_ITINERARY_STOPS} điểm dừng để tối ưu chi phí bản đồ.",
        )
    by_day = {}
    for stop in stops_in:
        day = max(1, stop.day_number or 1)
        by_day.setdefault(day, []).append(stop)

    normalized: List[ItineraryStopIn] = []
    for day in sorted(by_day.keys()):
        day_stops = by_day[day]
        for idx, st in enumerate(day_stops, start=1):
            st.day_number = day
            st.stop_order = idx
            normalized.append(st)
    return normalized


def create_itinerary_with_stops(
    db: Session,
    payload: ItineraryCreate,
    current_user: Optional[User] = None,
) -> Itinerary:
    """Tạo lịch trình tham quan mới kèm danh sách các điểm dừng."""
    normalized_stops = _normalize_stops_Input(payload.stops or [])
    now = datetime.now(timezone.utc)
    itinerary = Itinerary(
        user_id=current_user.id if current_user else None,
        province_id=payload.province_id,
        title=payload.title,
        description=payload.description,
        total_days=max(1, payload.total_days),
        is_template=payload.is_template if (current_user and current_user.role != "user") else False,
        status=payload.status or "active",
        created_at=now,
        updated_at=now,
    )
    db.add(itinerary)
    db.flush()

    for st in normalized_stops:
        stop_row = ItineraryStop(
            itinerary_id=itinerary.id,
            day_number=st.day_number,
            stop_order=st.stop_order,
            stop_type=st.stop_type,
            reference_id=st.reference_id,
            title=st.title,
            address=st.address,
            latitude=st.latitude,
            longitude=st.longitude,
            planned_time=st.planned_time,
            duration_mins=st.duration_mins,
            notes=st.notes,
        )
        db.add(stop_row)

    db.commit()
    db.refresh(itinerary)
    return itinerary


def update_itinerary_and_stops(
    db: Session,
    itinerary: Itinerary,
    payload: ItineraryUpdate,
) -> Itinerary:
    """Cập nhật thông tin lịch trình và thay thế/sắp xếp lại danh sách điểm dừng."""
    if payload.province_id is not None:
        itinerary.province_id = payload.province_id
    if payload.title is not None:
        itinerary.title = payload.title
    if payload.description is not None:
        itinerary.description = payload.description
    if payload.total_days is not None:
        itinerary.total_days = max(1, payload.total_days)
    if payload.status is not None:
        itinerary.status = payload.status
    if payload.is_template is not None:
        itinerary.is_template = payload.is_template
    itinerary.updated_at = datetime.now(timezone.utc)

    if payload.stops is not None:
        normalized_stops = _normalize_stops_Input(payload.stops)
        db.query(ItineraryStop).filter(ItineraryStop.itinerary_id == itinerary.id).delete()
        for st in normalized_stops:
            db.add(
                ItineraryStop(
                    itinerary_id=itinerary.id,
                    day_number=st.day_number,
                    stop_order=st.stop_order,
                    stop_type=st.stop_type,
                    reference_id=st.reference_id,
                    title=st.title,
                    address=st.address,
                    latitude=st.latitude,
                    longitude=st.longitude,
                    planned_time=st.planned_time,
                    duration_mins=st.duration_mins,
                    notes=st.notes,
                )
            )

    db.commit()
    db.refresh(itinerary)
    return itinerary


def add_stop_to_itinerary(
    db: Session,
    itinerary: Itinerary,
    stop_in: ItineraryStopIn,
) -> Itinerary:
    """Thêm nhanh một điểm dừng (địa điểm hoặc nhà hàng trên lộ trình) vào lịch trình."""
    existing_count = len(itinerary.stops or [])
    if existing_count >= settings.MAX_ITINERARY_STOPS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Lịch trình đã đạt giới hạn tối đa {settings.MAX_ITINERARY_STOPS} điểm dừng.",
        )

    day_stops = [s for s in (itinerary.stops or []) if s.day_number == stop_in.day_number]
    next_order = len(day_stops) + 1

    new_stop = ItineraryStop(
        itinerary_id=itinerary.id,
        day_number=max(1, stop_in.day_number),
        stop_order=next_order,
        stop_type=stop_in.stop_type,
        reference_id=stop_in.reference_id,
        title=stop_in.title,
        address=stop_in.address,
        latitude=stop_in.latitude,
        longitude=stop_in.longitude,
        planned_time=stop_in.planned_time,
        duration_mins=stop_in.duration_mins,
        notes=stop_in.notes,
    )
    db.add(new_stop)
    itinerary.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(itinerary)
    return itinerary


def sync_itinerary_from_offline(
    db: Session,
    payload: ItinerarySyncRequest,
    current_user: Optional[User] = None,
) -> Itinerary:
    """
    Đồng bộ lịch trình đã lưu local trong Hive từ ứng dụng Flutter lên Backend khi có mạng lại (Pitfall #5).
    """
    if payload.server_id:
        existing = db.query(Itinerary).filter(Itinerary.id == payload.server_id).first()
        # Chỉ cập nhật khi lịch trình đúng là của người dùng hiện tại; ngược lại
        # tạo bản ghi mới để không cho phép ghi đè lịch trình của người khác.
        if existing and current_user and existing.user_id == current_user.id:
            return update_itinerary_and_stops(
                db=db,
                itinerary=existing,
                payload=ItineraryUpdate(
                    province_id=payload.province_id,
                    title=payload.title,
                    description=payload.description,
                    total_days=payload.total_days,
                    stops=payload.stops,
                ),
            )

    return create_itinerary_with_stops(
        db=db,
        payload=ItineraryCreate(
            province_id=payload.province_id,
            title=payload.title,
            description=payload.description,
            total_days=payload.total_days,
            is_template=False,
            stops=payload.stops,
        ),
        current_user=current_user,
    )


def suggest_and_insert_smart_meal_stop(
    db: Session,
    itinerary_id: int,
    day_number: int = 1,
    preferred_time: str = "12:00",
    corridor_radius_km: float = 2.0,
    cuisine_filter: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Tự động phân tích khoảng cách và lộ trình di chuyển giữa các điểm tham quan trong ngày,
    tìm kiếm nhà hàng có điểm Smart Food Corridor Score (SFCS) cao nhất và tự động chèn điểm dừng ăn uống.
    """
    itinerary = db.query(Itinerary).filter(Itinerary.id == itinerary_id).first()
    if not itinerary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy lịch trình có ID {itinerary_id}.",
        )

    all_stops = list(itinerary.stops or [])
    day_stops = sorted(
        [s for s in all_stops if s.day_number == day_number],
        key=lambda s: s.stop_order,
    )

    destination_stops = [s for s in day_stops if s.stop_type != "meal"]
    candidates: List[Dict[str, Any]] = []

    # Kịch bản 1: Có từ 2 điểm tham quan trở lên -> Tìm nhà hàng dọc hành lang nối 2 điểm
    if len(destination_stops) >= 2:
        p1 = destination_stops[0]
        p2 = destination_stops[1]
        try:
            polyline_tuples, _, _, _ = maps_proxy.get_route_with_encoded_polyline(
                origin_lat=p1.latitude,
                origin_lng=p1.longitude,
                dest_lat=p2.latitude,
                dest_lng=p2.longitude,
            )
            bbox = compute_route_bounding_box(polyline_tuples, corridor_radius_km)
            raw_rests = filter_restaurants_by_bounding_box(
                db, bbox, province_id=itinerary.province_id
            )
            candidates = find_restaurants_along_corridor_shapely(
                restaurants=raw_rests,
                polyline=polyline_tuples,
                corridor_radius_km=corridor_radius_km,
                cuisine_filter=cuisine_filter,
            )
        except Exception:
            candidates = []

    # Kịch bản 2: Không tìm thấy trên hành lang hoặc ngày chỉ có 1 điểm tham quan -> Tìm quanh điểm tham quan
    if not candidates:
        if destination_stops:
            center_lat = destination_stops[0].latitude
            center_lng = destination_stops[0].longitude
        elif day_stops:
            center_lat = day_stops[0].latitude
            center_lng = day_stops[0].longitude
        else:
            center_lat, center_lng = (10.7769, 106.7009)

        prov_rests = (
            db.query(Restaurant)
            .filter(
                Restaurant.province_id == itinerary.province_id,
                Restaurant.status == "published",
            )
            .all()
        )
        if not prov_rests:
            prov_rests = db.query(Restaurant).filter(Restaurant.status == "published").all()

        for r in prov_rests:
            dist = haversine_distance_km(center_lat, center_lng, r.latitude, r.longitude)
            r_rev_cnt = getattr(r, "reviews_count", None) or r.review_count or 120
            r_is_high = getattr(r, "is_high_rated", None)
            if r_is_high is None:
                r_is_high = bool(r.rating >= 4.2 and r_rev_cnt >= 50)
            score = calculate_smart_corridor_score(
                distance_km=dist,
                corridor_radius_km=max(corridor_radius_km, 3.0),
                rating=r.rating,
                reviews_count=r_rev_cnt,
                is_high_rated=r_is_high,
            )
            serialized = serialize_restaurant(r)
            serialized.update(
                {
                    "distance_from_route_km": round(dist, 2),
                    "detour_distance_km": round(dist * 2.0, 2),
                    "estimated_detour_mins": max(2, int(round((dist * 2.0) / 0.4)) + 1),
                    "nearest_route_point_lat": center_lat,
                    "nearest_route_point_lng": center_lng,
                    "route_progress_pct": 50.0,
                    "corridor_score": score,
                }
            )
            candidates.append(serialized)

        candidates.sort(key=lambda x: (-x.get("corridor_score", 0.0), x["distance_from_route_km"]))

    if not candidates:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy quán ăn phù hợp quanh khu vực này.",
        )

    best_rest = candidates[0]

    # Xác định vị trí chèn điểm dừng
    if len(day_stops) >= 1:
        insert_order = 2  # Chèn vào giữa điểm 1 và điểm 2 (thời điểm trưa)
    else:
        insert_order = 1

    # Dịch chuyển các điểm dừng phía sau nếu cần
    for st in day_stops:
        if st.stop_order >= insert_order:
            st.stop_order += 1
            db.add(st)

    time_label = preferred_time or "12:00"
    if ":" in time_label:
        try:
            hh = int(time_label.split(":")[0])
            planned_range = f"{hh:02d}:00 - {hh+1:02d}:00"
        except Exception:
            planned_range = "12:00 - 13:00"
    else:
        planned_range = "12:00 - 13:00"

    meal_title = (
        f"Dừng ăn trưa: {best_rest['name']}"
        if "11:" in time_label or "12:" in time_label or "13:" in time_label
        else f"Dừng ăn uống: {best_rest['name']}"
    )

    new_stop = ItineraryStop(
        itinerary_id=itinerary.id,
        day_number=day_number,
        stop_order=insert_order,
        stop_type="meal",
        reference_id=best_rest["id"],
        title=meal_title,
        address=best_rest.get("address"),
        latitude=best_rest["latitude"],
        longitude=best_rest["longitude"],
        planned_time=planned_range,
        duration_mins=60,
        notes=(
            f"Gợi ý Smart Food Corridor (SFCS: {best_rest.get('corridor_score', 95.0)}đ). "
            f"Đặc trưng: {best_rest.get('specialties') or best_rest.get('specialty_dishes') or 'Món ngon địa phương'}."
        ),
    )
    db.add(new_stop)
    itinerary.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(new_stop)

    smart_score = float(best_rest.get("corridor_score", 95.0))
    dist_km = best_rest.get("distance_from_route_km", 0.3)
    detour_mins = best_rest.get("estimated_detour_mins", 3)
    reviews_count = best_rest.get("reviews_count", 120)

    reasoning = (
        f"Quán {best_rest['name']} đạt {best_rest.get('rating', 4.8)} sao với hơn "
        f"{reviews_count:,} lượt đánh giá thực tế từ thực khách. "
        f"Vị trí chỉ cách tuyến đường {dist_km}km (khoảng {detour_mins} phút rẽ), "
        f"rất lý tưởng dừng chân thưởng thức món đặc trưng."
    )

    return {
        "itinerary_id": itinerary.id,
        "day_number": day_number,
        "inserted_stop": {
            "id": new_stop.id,
            "itinerary_id": itinerary.id,
            "day_number": new_stop.day_number,
            "stop_order": new_stop.stop_order,
            "stop_type": new_stop.stop_type,
            "reference_id": new_stop.reference_id,
            "title": new_stop.title,
            "address": new_stop.address,
            "latitude": new_stop.latitude,
            "longitude": new_stop.longitude,
            "planned_time": new_stop.planned_time,
            "duration_mins": new_stop.duration_mins,
            "notes": new_stop.notes,
        },
        "recommended_restaurant": best_rest,
        "smart_score": smart_score,
        "reasoning": reasoning,
    }
