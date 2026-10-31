import json
from datetime import datetime
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import Session

from app.core.security import (
    check_province_permission,
    get_role_permissions,
    require_permissions,
    require_roles,
)
from app.db.session import get_db
from app.integrations.cloudinary_service import cloudinary_service
from app.integrations.maps_client import maps_proxy
from app.models.models import (
    AdminRole,
    AuditLog,
    ContentReport,
    Destination,
    DestinationImage,
    Itinerary,
    LocalFood,
    Permission,
    Province,
    Restaurant,
    Role,
    User,
)
from app.repositories.repositories import (
    log_admin_action,
    serialize_destination,
    serialize_itinerary,
    serialize_local_food,
    serialize_restaurant,
)
from app.schemas.schemas import (
    AdminDashboardStats,
    AuditLogOut,
    CloudinaryUploadRequest,
    CloudinaryUploadResponse,
    ContentReportOut,
    ContentReportResolve,
    DestinationCreate,
    DestinationOut,
    DestinationUpdate,
    ItineraryCreate,
    ItineraryOut,
    ItineraryUpdate,
    LocalFoodCreate,
    LocalFoodOut,
    LocalFoodUpdate,
    ProvinceCreate,
    ProvinceOut,
    ProvinceUpdate,
    RestaurantCreate,
    RestaurantOut,
    RestaurantUpdate,
    UserOut,
    UserRoleUpdate,
)
from app.services.itinerary_service import (
    create_itinerary_with_stops,
    update_itinerary_and_stops,
)

router = APIRouter()

ALL_ADMIN_STAFF_ROLES = ["super_admin", "content_admin", "province_editor", "moderator"]
CONTENT_WRITE_ROLES = ["super_admin", "content_admin", "province_editor"]
TOP_LEVEL_ADMIN_ROLES = ["super_admin", "content_admin"]


# ============================================================================
# 1. DASHBOARD KPI, GOONG MAPS QUOTA & CLOUDINARY OVERVIEW
# ============================================================================

@router.get("/dashboard", response_model=AdminDashboardStats)
def get_admin_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    """Lấy thống kê tổng quan cho Website Admin kèm trạng thái Goong Maps & Rate Limit."""
    total_provinces = db.query(Province).count()
    total_destinations = db.query(Destination).count()
    total_local_foods = db.query(LocalFood).count()
    total_restaurants = db.query(Restaurant).count()
    total_templates = db.query(Itinerary).filter(Itinerary.is_template == True).count()
    total_users = db.query(User).count()
    pending_reports = db.query(ContentReport).filter(ContentReport.status == "pending").count()

    sponsored_dests = db.query(Destination).filter(Destination.is_sponsored == True).count()
    sponsored_rests = db.query(Restaurant).filter(Restaurant.is_sponsored == True).count()

    internal_cnt = (
        db.query(Destination).filter(Destination.data_source == "internal").count()
        + db.query(Restaurant).filter(Restaurant.data_source == "internal").count()
    )
    partner_cnt = (
        db.query(Destination).filter(Destination.data_source == "partner").count()
        + db.query(Restaurant).filter(Restaurant.data_source == "partner").count()
    )
    api_cnt = (
        db.query(Destination).filter(Destination.data_source == "api_provider").count()
        + db.query(Restaurant).filter(Restaurant.data_source == "api_provider").count()
    )

    recent_logs = (
        db.query(AuditLog)
        .order_by(AuditLog.created_at.desc(), AuditLog.id.desc())
        .limit(12)
        .all()
    )

    return {
        "total_provinces": total_provinces,
        "total_destinations": total_destinations,
        "total_local_foods": total_local_foods,
        "total_restaurants": total_restaurants,
        "total_templates": total_templates,
        "total_users": total_users,
        "pending_reports": pending_reports,
        "sponsored_items_count": sponsored_dests + sponsored_rests,
        "data_source_breakdown": {
            "internal": internal_cnt,
            "partner": partner_cnt,
            "api_provider": api_cnt,
        },
        "maps_api_quota": maps_proxy.get_quota_status(),
        "recent_audit_logs": recent_logs,
    }


# ============================================================================
# 1B. UPLOAD & TỐI ƯU ẢNH CLOUDINARY CDN (Thay đổi cốt lõi #5)
# ============================================================================

@router.post("/upload-image", response_model=CloudinaryUploadResponse)
def admin_upload_image_to_cloudinary(
    payload: CloudinaryUploadRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["destination:write"])),
):
    """
    Upload ảnh hoặc chuẩn hóa URL ảnh qua Cloudinary CDN.
    Tự động sinh URL thumbnail `c_fill,w_400,h_300,q_auto,f_auto` và ảnh chi tiết `w_1200,q_auto,f_auto`.
    """
    res = cloudinary_service.upload_image(
        image_url=payload.image_url,
        filename=payload.filename or "tripflow_upload.jpg",
        folder=payload.folder or "tripflow/destinations",
    )
    log_admin_action(
        db=db,
        actor=current_user,
        action="UPLOAD",
        entity_type="cloudinary_image",
        entity_id=None,
        summary=f"Tối ưu hóa ảnh qua Cloudinary CDN: {res['public_id']}",
        changes={"thumbnail_url": res["thumbnail_url"]},
    )
    return res


# ============================================================================
# 2. QUẢN LÝ TỈNH / THÀNH PHỐ (PROVINCES)
# ============================================================================

@router.get("/provinces", response_model=List[ProvinceOut])
def admin_list_provinces(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    provinces = db.query(Province).order_by(Province.id.asc()).all()
    out = []
    for p in provinces:
        out.append(
            {
                "id": p.id,
                "code": p.code,
                "name": p.name,
                "region": p.region,
                "description": p.description,
                "hero_image": p.hero_image,
                "center_lat": p.center_lat,
                "center_lng": p.center_lng,
                "is_active": p.is_active,
                "data_source": p.data_source,
                "updated_at": p.updated_at,
                "destination_count": db.query(Destination).filter(Destination.province_id == p.id).count(),
                "food_count": db.query(LocalFood).filter(LocalFood.province_id == p.id).count(),
                "restaurant_count": db.query(Restaurant).filter(Restaurant.province_id == p.id).count(),
            }
        )
    return out


@router.post("/provinces", response_model=ProvinceOut, status_code=status.HTTP_201_CREATED)
def admin_create_province(
    payload: ProvinceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(TOP_LEVEL_ADMIN_ROLES)),
):
    existing = db.query(Province).filter(Province.code == payload.code.upper()).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Mã tỉnh/thành '{payload.code}' đã tồn tại.",
        )
    prov = Province(
        code=payload.code.upper().strip(),
        name=payload.name.strip(),
        region=payload.region,
        description=payload.description,
        hero_image=payload.hero_image,
        center_lat=payload.center_lat,
        center_lng=payload.center_lng,
        is_active=payload.is_active,
        data_source=payload.data_source,
        updated_at=datetime.utcnow(),
    )
    db.add(prov)
    db.commit()
    db.refresh(prov)

    log_admin_action(
        db=db,
        actor=current_user,
        action="CREATE",
        entity_type="province",
        entity_id=prov.id,
        summary=f"Thêm tỉnh/thành phố mới: {prov.name} ({prov.code})",
        changes=payload.model_dump(),
    )
    return prov


@router.put("/provinces/{province_id}", response_model=ProvinceOut)
def admin_update_province(
    province_id: int,
    payload: ProvinceUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(TOP_LEVEL_ADMIN_ROLES)),
):
    prov = db.query(Province).filter(Province.id == province_id).first()
    if not prov:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy tỉnh/thành.")

    update_data = payload.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(prov, k, v)
    prov.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(prov)

    log_admin_action(
        db=db,
        actor=current_user,
        action="UPDATE",
        entity_type="province",
        entity_id=prov.id,
        summary=f"Cập nhật tỉnh/thành phố: {prov.name} ({prov.code})",
        changes=update_data,
    )
    return prov


# ============================================================================
# 3. QUẢN LÝ ĐỊA ĐIỂM DU LỊCH (DESTINATIONS + CLOUDINARY URLS)
# ============================================================================

@router.get("/destinations", response_model=List[DestinationOut])
def admin_list_destinations(
    province_id: Optional[int] = Query(default=None),
    status_filter: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    query = db.query(Destination)
    if province_id is not None:
        query = query.filter(Destination.province_id == province_id)
    if status_filter:
        query = query.filter(Destination.status == status_filter)
    items = query.order_by(Destination.id.asc()).all()
    return [serialize_destination(d) for d in items]


@router.post("/destinations", response_model=DestinationOut, status_code=status.HTTP_201_CREATED)
def admin_create_destination(
    payload: DestinationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["destination:write"])),
):
    check_province_permission(current_user, payload.province_id)

    now = datetime.utcnow()
    slug = payload.slug or payload.name.lower().replace(" ", "-")
    primary_raw_img = (
        payload.images[0].image_url
        if payload.images
        else payload.detail_image_url
        or payload.thumbnail_url
        or "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80"
    )

    dest = Destination(
        province_id=payload.province_id,
        category_id=payload.category_id or 1,
        name=payload.name.strip(),
        slug=slug,
        description=payload.description,
        address=payload.address,
        latitude=payload.latitude,
        longitude=payload.longitude,
        opening_hours=payload.opening_hours,
        ticket_price_info=payload.ticket_price_info,
        rating=payload.rating,
        review_count=payload.review_count,
        recommended_duration_mins=payload.recommended_duration_mins,
        thumbnail_url=cloudinary_service.build_thumbnail_url(primary_raw_img),
        detail_image_url=cloudinary_service.build_detail_url(primary_raw_img),
        is_featured=payload.is_featured,
        is_sponsored=payload.is_sponsored,
        sponsor_label=payload.sponsor_label,
        is_verified=True,
        source=payload.source or "admin",
        source_url=payload.source_url,
        status=payload.status,
        data_source=payload.data_source,
        source_attribution=payload.source_attribution,
        last_verified_at=now,
        updated_at=now,
    )
    db.add(dest)
    db.flush()

    if payload.images:
        for idx, img in enumerate(payload.images, start=1):
            db.add(
                DestinationImage(
                    destination_id=dest.id,
                    image_url=cloudinary_service.build_detail_url(img.image_url),
                    thumbnail_url=cloudinary_service.build_thumbnail_url(img.image_url),
                    caption=img.caption,
                    sort_order=img.sort_order or idx,
                    license_type=img.license_type,
                    credit_author=img.credit_author,
                )
            )
    else:
        db.add(
            DestinationImage(
                destination_id=dest.id,
                image_url=dest.detail_image_url,
                thumbnail_url=dest.thumbnail_url,
                caption=dest.name,
                sort_order=1,
                license_type="owned",
                credit_author="TripFlow Studio",
            )
        )

    db.commit()
    db.refresh(dest)

    log_admin_action(
        db=db,
        actor=current_user,
        action="CREATE",
        entity_type="destination",
        entity_id=dest.id,
        summary=f"Thêm địa điểm du lịch mới: {dest.name} (province_id={dest.province_id})",
        changes={"name": dest.name, "province_id": dest.province_id, "data_source": dest.data_source},
    )
    return serialize_destination(dest)


@router.put("/destinations/{destination_id}", response_model=DestinationOut)
def admin_update_destination(
    destination_id: int,
    payload: DestinationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["destination:write"])),
):
    dest = db.query(Destination).filter(Destination.id == destination_id).first()
    if not dest:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy địa điểm.")

    check_province_permission(current_user, dest.province_id)
    if payload.province_id is not None:
        check_province_permission(current_user, payload.province_id)

    update_data = payload.model_dump(exclude_unset=True, exclude={"images"})
    for k, v in update_data.items():
        setattr(dest, k, v)
    dest.updated_at = datetime.utcnow()
    dest.last_verified_at = datetime.utcnow()

    if payload.images is not None:
        db.query(DestinationImage).filter(DestinationImage.destination_id == dest.id).delete()
        if payload.images:
            first_url = payload.images[0].image_url
            dest.thumbnail_url = cloudinary_service.build_thumbnail_url(first_url)
            dest.detail_image_url = cloudinary_service.build_detail_url(first_url)
        for idx, img in enumerate(payload.images, start=1):
            db.add(
                DestinationImage(
                    destination_id=dest.id,
                    image_url=cloudinary_service.build_detail_url(img.image_url),
                    thumbnail_url=cloudinary_service.build_thumbnail_url(img.image_url),
                    caption=img.caption,
                    sort_order=img.sort_order or idx,
                    license_type=img.license_type,
                    credit_author=img.credit_author,
                )
            )

    db.commit()
    db.refresh(dest)

    log_admin_action(
        db=db,
        actor=current_user,
        action="UPDATE",
        entity_type="destination",
        entity_id=dest.id,
        summary=f"Cập nhật địa điểm du lịch: {dest.name}",
        changes=update_data,
    )
    return serialize_destination(dest)


@router.delete("/destinations/{destination_id}", status_code=status.HTTP_204_NO_CONTENT)
def admin_delete_destination(
    destination_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["destination:delete"])),
):
    dest = db.query(Destination).filter(Destination.id == destination_id).first()
    if not dest:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy địa điểm.")
    deleted_name = dest.name
    db.delete(dest)
    db.commit()

    log_admin_action(
        db=db,
        actor=current_user,
        action="DELETE",
        entity_type="destination",
        entity_id=destination_id,
        summary=f"Xóa địa điểm du lịch: {deleted_name}",
        changes={"deleted_id": destination_id},
    )
    return None


# ============================================================================
# 4. QUẢN LÝ ĐẶC SẢN / MÓN ĂN (LOCAL FOODS)
# ============================================================================

@router.get("/local-foods", response_model=List[LocalFoodOut])
def admin_list_local_foods(
    province_id: Optional[int] = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    query = db.query(LocalFood)
    if province_id is not None:
        query = query.filter(LocalFood.province_id == province_id)
    foods = query.order_by(LocalFood.id.asc()).all()
    return [serialize_local_food(db, f) for f in foods]


@router.post("/local-foods", response_model=LocalFoodOut, status_code=status.HTTP_201_CREATED)
def admin_create_local_food(
    payload: LocalFoodCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["food:write"])),
):
    check_province_permission(current_user, payload.province_id)

    food = LocalFood(
        province_id=payload.province_id,
        name=payload.name.strip(),
        description=payload.description,
        story_origin=payload.story_origin,
        image_url=cloudinary_service.build_detail_url(payload.image_url),
        thumbnail_url=cloudinary_service.build_thumbnail_url(payload.image_url),
        best_season_or_time=payload.best_season_or_time,
        avg_price_range=payload.avg_price_range,
        recommended_restaurant_ids_json=json.dumps(payload.recommended_restaurant_ids or []),
        status=payload.status,
        data_source=payload.data_source,
        license_info=payload.license_info,
        updated_at=datetime.utcnow(),
    )
    db.add(food)
    db.commit()
    db.refresh(food)

    log_admin_action(
        db=db,
        actor=current_user,
        action="CREATE",
        entity_type="local_food",
        entity_id=food.id,
        summary=f"Thêm đặc sản/món ăn mới: {food.name}",
        changes={"name": food.name, "province_id": food.province_id},
    )
    return serialize_local_food(db, food)


@router.put("/local-foods/{food_id}", response_model=LocalFoodOut)
def admin_update_local_food(
    food_id: int,
    payload: LocalFoodUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["food:write"])),
):
    food = db.query(LocalFood).filter(LocalFood.id == food_id).first()
    if not food:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy món ăn.")

    check_province_permission(current_user, food.province_id)
    if payload.province_id is not None:
        check_province_permission(current_user, payload.province_id)

    update_data = payload.model_dump(exclude_unset=True, exclude={"recommended_restaurant_ids"})
    for k, v in update_data.items():
        setattr(food, k, v)
    if payload.image_url:
        food.image_url = cloudinary_service.build_detail_url(payload.image_url)
        food.thumbnail_url = cloudinary_service.build_thumbnail_url(payload.image_url)
    if payload.recommended_restaurant_ids is not None:
        food.recommended_restaurant_ids_json = json.dumps(payload.recommended_restaurant_ids)
    food.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(food)

    log_admin_action(
        db=db,
        actor=current_user,
        action="UPDATE",
        entity_type="local_food",
        entity_id=food.id,
        summary=f"Cập nhật đặc sản/món ăn: {food.name}",
        changes=update_data,
    )
    return serialize_local_food(db, food)


@router.delete("/local-foods/{food_id}", status_code=status.HTTP_204_NO_CONTENT)
def admin_delete_local_food(
    food_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(TOP_LEVEL_ADMIN_ROLES)),
):
    food = db.query(LocalFood).filter(LocalFood.id == food_id).first()
    if not food:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy món ăn.")
    name = food.name
    db.delete(food)
    db.commit()

    log_admin_action(
        db=db,
        actor=current_user,
        action="DELETE",
        entity_type="local_food",
        entity_id=food_id,
        summary=f"Xóa đặc sản/món ăn: {name}",
        changes={"deleted_id": food_id},
    )
    return None


# ============================================================================
# 5. QUẢN LÝ NHÀ HÀNG / QUÁN ĂN (RESTAURANTS)
# ============================================================================

@router.get("/restaurants", response_model=List[RestaurantOut])
def admin_list_restaurants(
    province_id: Optional[int] = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    query = db.query(Restaurant)
    if province_id is not None:
        query = query.filter(Restaurant.province_id == province_id)
    rests = query.order_by(Restaurant.id.asc()).all()
    return [serialize_restaurant(r) for r in rests]


@router.post("/restaurants", response_model=RestaurantOut, status_code=status.HTTP_201_CREATED)
def admin_create_restaurant(
    payload: RestaurantCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["restaurant:write"])),
):
    check_province_permission(current_user, payload.province_id)

    rest = Restaurant(
        province_id=payload.province_id,
        name=payload.name.strip(),
        address=payload.address,
        latitude=payload.latitude,
        longitude=payload.longitude,
        cuisine_type=payload.cuisine_type,
        specialty_dishes=payload.specialty_dishes,
        price_range=payload.price_range,
        opening_hours=payload.opening_hours,
        contact_phone=payload.contact_phone,
        rating=payload.rating,
        review_count=payload.review_count,
        image_url=cloudinary_service.build_detail_url(payload.image_url),
        thumbnail_url=cloudinary_service.build_thumbnail_url(payload.image_url),
        is_sponsored=payload.is_sponsored,
        sponsor_label=payload.sponsor_label,
        is_verified=True if payload.source == "admin" else payload.is_verified,
        source=payload.source or "admin",
        source_url=payload.source_url,
        status=payload.status,
        data_source=payload.data_source,
        last_updated_at=datetime.utcnow(),
    )
    db.add(rest)
    db.commit()
    db.refresh(rest)

    log_admin_action(
        db=db,
        actor=current_user,
        action="CREATE",
        entity_type="restaurant",
        entity_id=rest.id,
        summary=f"Thêm nhà hàng mới: {rest.name} ({rest.address})",
        changes={"name": rest.name, "province_id": rest.province_id, "is_sponsored": rest.is_sponsored},
    )
    return serialize_restaurant(rest)


@router.put("/restaurants/{restaurant_id}", response_model=RestaurantOut)
def admin_update_restaurant(
    restaurant_id: int,
    payload: RestaurantUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["restaurant:write"])),
):
    rest = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not rest:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy nhà hàng.")

    check_province_permission(current_user, rest.province_id)
    if payload.province_id is not None:
        check_province_permission(current_user, payload.province_id)

    update_data = payload.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(rest, k, v)
    if payload.image_url:
        rest.image_url = cloudinary_service.build_detail_url(payload.image_url)
        rest.thumbnail_url = cloudinary_service.build_thumbnail_url(payload.image_url)
    rest.last_updated_at = datetime.utcnow()

    db.commit()
    db.refresh(rest)

    log_admin_action(
        db=db,
        actor=current_user,
        action="UPDATE",
        entity_type="restaurant",
        entity_id=rest.id,
        summary=f"Cập nhật thông tin nhà hàng: {rest.name}",
        changes=update_data,
    )
    return serialize_restaurant(rest)


@router.delete("/restaurants/{restaurant_id}", status_code=status.HTTP_204_NO_CONTENT)
def admin_delete_restaurant(
    restaurant_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(TOP_LEVEL_ADMIN_ROLES)),
):
    rest = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not rest:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy nhà hàng.")
    name = rest.name
    db.delete(rest)
    db.commit()

    log_admin_action(
        db=db,
        actor=current_user,
        action="DELETE",
        entity_type="restaurant",
        entity_id=restaurant_id,
        summary=f"Xóa nhà hàng: {name}",
        changes={"deleted_id": restaurant_id},
    )
    return None


# ============================================================================
# 6. QUẢN LÝ LỊCH TRÌNH MẪU (SAMPLE ITINERARIES)
# ============================================================================

@router.post("/itineraries", response_model=ItineraryOut, status_code=status.HTTP_201_CREATED)
def admin_create_sample_itinerary(
    payload: ItineraryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["itinerary:write"])),
):
    check_province_permission(current_user, payload.province_id)
    payload.is_template = True
    itin = create_itinerary_with_stops(db=db, payload=payload, current_user=current_user)

    log_admin_action(
        db=db,
        actor=current_user,
        action="CREATE",
        entity_type="itinerary",
        entity_id=itin.id,
        summary=f"Tạo lịch trình mẫu mới: {itin.title}",
        changes={"title": itin.title, "stops_count": len(itin.stops or [])},
    )
    return serialize_itinerary(itin)


@router.put("/itineraries/{itinerary_id}", response_model=ItineraryOut)
def admin_update_sample_itinerary(
    itinerary_id: int,
    payload: ItineraryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["itinerary:write"])),
):
    itin = db.query(Itinerary).filter(Itinerary.id == itinerary_id).first()
    if not itin:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy lịch trình mẫu.")

    check_province_permission(current_user, itin.province_id)
    updated = update_itinerary_and_stops(db=db, itinerary=itin, payload=payload)

    log_admin_action(
        db=db,
        actor=current_user,
        action="UPDATE",
        entity_type="itinerary",
        entity_id=updated.id,
        summary=f"Cập nhật lịch trình mẫu: {updated.title}",
        changes={"title": updated.title, "stops_count": len(updated.stops or [])},
    )
    return serialize_itinerary(updated)


@router.delete("/itineraries/{itinerary_id}", status_code=status.HTTP_204_NO_CONTENT)
def admin_delete_sample_itinerary(
    itinerary_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(TOP_LEVEL_ADMIN_ROLES)),
):
    itin = db.query(Itinerary).filter(Itinerary.id == itinerary_id).first()
    if not itin:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy lịch trình.")
    title = itin.title
    db.delete(itin)
    db.commit()

    log_admin_action(
        db=db,
        actor=current_user,
        action="DELETE",
        entity_type="itinerary",
        entity_id=itinerary_id,
        summary=f"Xóa lịch trình mẫu: {title}",
        changes={"deleted_id": itinerary_id},
    )
    return None


# ============================================================================
# 7. QUẢN LÝ NGƯỜNG DÙNG & PHÂN QUYỀN RBAC (USERS, ROLES & PERMISSIONS)
# ============================================================================

@router.get("/users", response_model=List[UserOut])
def admin_list_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    users = db.query(User).order_by(User.id.asc()).all()
    return [
        UserOut(
            id=u.id,
            email=u.email,
            full_name=u.full_name,
            role=u.role,
            role_id=u.role_id,
            assigned_province_id=u.assigned_province_id,
            is_active=u.is_active,
            permissions=get_role_permissions(db, u.role),
            created_at=u.created_at,
        )
        for u in users
    ]


@router.put("/users/{user_id}/role", response_model=UserOut)
def admin_update_user_role(
    user_id: int,
    payload: UserRoleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["user:manage"])),
):
    """Chỉ tài khoản có quyền `user:manage` (Super Admin) mới được đổi vai trò RBAC."""
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy tài khoản.")

    old_role = target_user.role
    target_user.role = payload.role
    role_obj = db.query(Role).filter(Role.code == payload.role).first()
    if role_obj:
        target_user.role_id = role_obj.id
    target_user.assigned_province_id = payload.assigned_province_id
    if payload.is_active is not None:
        target_user.is_active = payload.is_active

    db.commit()
    db.refresh(target_user)

    log_admin_action(
        db=db,
        actor=current_user,
        action="UPDATE",
        entity_type="user",
        entity_id=target_user.id,
        summary=f"Cập nhật quyền tài khoản {target_user.email}: {old_role} -> {target_user.role}",
        changes=payload.model_dump(),
    )
    return UserOut(
        id=target_user.id,
        email=target_user.email,
        full_name=target_user.full_name,
        role=target_user.role,
        role_id=target_user.role_id,
        assigned_province_id=target_user.assigned_province_id,
        is_active=target_user.is_active,
        permissions=get_role_permissions(db, target_user.role),
        created_at=target_user.created_at,
    )


# ============================================================================
# 8. KIỂM DUYỆT ĐÁNH GIÁ & BÁO CÁO SAI THÔNG TIN (CONTENT REPORTS)
# ============================================================================

@router.get("/reports", response_model=List[ContentReportOut])
def admin_list_reports(
    status_filter: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    query = db.query(ContentReport)
    if status_filter:
        query = query.filter(ContentReport.status == status_filter)
    return query.order_by(ContentReport.created_at.desc(), ContentReport.id.desc()).all()


@router.put("/reports/{report_id}", response_model=ContentReportOut)
def admin_resolve_report(
    report_id: int,
    payload: ContentReportResolve,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(["report:moderate"])),
):
    report = db.query(ContentReport).filter(ContentReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy báo cáo.")

    report.status = payload.status
    report.moderator_note = payload.moderator_note
    report.resolved_at = datetime.utcnow()
    db.commit()
    db.refresh(report)

    action_label = "APPROVE" if payload.status == "resolved" else "REJECT"
    log_admin_action(
        db=db,
        actor=current_user,
        action=action_label,
        entity_type="report",
        entity_id=report.id,
        summary=f"Xử lý báo cáo #{report.id} ({report.target_name}): {payload.status}",
        changes=payload.model_dump(),
    )
    return report


# ============================================================================
# 9. NHẬT KÝ THAO TÁC HỆ THỐNG (AUDIT LOGS) & BẢNG ROLES / PERMISSIONS
# ============================================================================

@router.get("/audit-logs", response_model=List[AuditLogOut])
def admin_list_audit_logs(
    action: Optional[str] = Query(default=None),
    entity_type: Optional[str] = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    query = db.query(AuditLog)
    if action:
        query = query.filter(AuditLog.action == action.upper())
    if entity_type:
        query = query.filter(AuditLog.entity_type == entity_type)
    return query.order_by(AuditLog.created_at.desc(), AuditLog.id.desc()).limit(limit).all()


@router.get("/roles", response_model=List[Dict[str, Any]])
def admin_list_roles(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    roles = db.query(Role).order_by(Role.id.asc()).all()
    if roles:
        return [
            {
                "id": r.id,
                "role_code": r.code,
                "role_name": r.name,
                "permissions": get_role_permissions(db, r.code),
                "description": r.description,
            }
            for r in roles
        ]
    legacy = db.query(AdminRole).order_by(AdminRole.id.asc()).all()
    return [
        {
            "id": r.id,
            "role_code": r.role_code,
            "role_name": r.role_name,
            "permissions": json.loads(r.permissions_json or "[]"),
            "description": r.description,
        }
        for r in legacy
    ]


@router.get("/roles-permissions", response_model=Dict[str, Any])
def admin_get_roles_and_permissions_tables(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(ALL_ADMIN_STAFF_ROLES)),
):
    """
    Trả về chi tiết bảng `roles` và bảng `permissions` trong SQLModel (Pitfall #2).
    """
    roles = db.query(Role).order_by(Role.id.asc()).all()
    perms = db.query(Permission).order_by(Permission.id.asc()).all()
    return {
        "roles": [
            {
                "id": r.id,
                "code": r.code,
                "name": r.name,
                "description": r.description,
                "permissions": get_role_permissions(db, r.code),
            }
            for r in roles
        ],
        "permissions": [
            {
                "id": p.id,
                "code": p.code,
                "name": p.name,
                "module": p.module,
                "description": p.description,
            }
            for p in perms
        ],
    }
