import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from sqlmodel import Session

from app.integrations.cloudinary_service import cloudinary_service
from app.models.models import (
    AuditLog,
    Destination,
    Itinerary,
    LocalFood,
    Restaurant,
    User,
)


def log_admin_action(
    db: Session,
    actor: Optional[User],
    action: str,
    entity_type: str,
    entity_id: Optional[int],
    summary: str,
    changes: Optional[Dict[str, Any]] = None,
) -> AuditLog:
    """Tự động ghi nhật ký thao tác quản trị (Audit Logs)."""
    log_entry = AuditLog(
        actor_id=actor.id if actor else None,
        actor_email=actor.email if actor else "system@tripflow.vn",
        actor_role=actor.role if actor else "system",
        action=action.upper(),
        entity_type=entity_type,
        entity_id=entity_id,
        summary=summary,
        changes_json=json.dumps(changes or {}, ensure_ascii=False, default=str),
        created_at=datetime.now(timezone.utc),
    )
    db.add(log_entry)
    db.commit()
    db.refresh(log_entry)
    return log_entry


def serialize_destination(dest: Destination) -> Dict[str, Any]:
    """
    Chuẩn hóa đối tượng Destination kèm Category, Province và URL ảnh tối ưu qua Cloudinary CDN:
    - thumbnail_url: c_fill,w_400,h_300,q_auto,f_auto
    - detail_image_url: w_1200,q_auto,f_auto
    """
    raw_images = dest.images or []
    first_raw_url = (
        raw_images[0].image_url
        if raw_images
        else dest.detail_image_url
        or dest.thumbnail_url
        or "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80"
    )

    thumb_url = dest.thumbnail_url or cloudinary_service.build_thumbnail_url(first_raw_url)
    detail_url = dest.detail_image_url or cloudinary_service.build_detail_url(first_raw_url)

    serialized_images = []
    for img in raw_images:
        serialized_images.append(
            {
                "id": img.id,
                "destination_id": img.destination_id,
                "image_url": cloudinary_service.build_detail_url(img.image_url),
                "thumbnail_url": img.thumbnail_url
                or cloudinary_service.build_thumbnail_url(img.image_url),
                "caption": img.caption,
                "sort_order": img.sort_order,
                "license_type": img.license_type,
                "credit_author": img.credit_author,
            }
        )

    return {
        "id": dest.id,
        "province_id": dest.province_id,
        "province_name": dest.province.name if dest.province else None,
        "category_id": dest.category_id,
        "category_code": dest.category.code if dest.category else "heritage",
        "category_name": dest.category.name if dest.category else "Di tích & Danh thắng",
        "name": dest.name,
        "slug": dest.slug,
        "description": dest.description,
        "address": dest.address,
        "latitude": dest.latitude,
        "longitude": dest.longitude,
        "opening_hours": dest.opening_hours,
        "ticket_price_info": dest.ticket_price_info,
        "rating": dest.rating,
        "review_count": dest.review_count,
        "recommended_duration_mins": dest.recommended_duration_mins,
        "thumbnail_url": thumb_url,
        "detail_image_url": detail_url,
        "is_featured": dest.is_featured,
        "is_sponsored": dest.is_sponsored,
        "sponsor_label": dest.sponsor_label,
        "is_verified": getattr(dest, "is_verified", True),
        "source": getattr(dest, "source", "admin"),
        "source_url": getattr(dest, "source_url", None),
        "status": dest.status,
        "data_source": dest.data_source,
        "source_attribution": dest.source_attribution,
        "last_verified_at": dest.last_verified_at,
        "updated_at": dest.updated_at,
        "images": serialized_images,
    }


def serialize_local_food(db: Session, food: LocalFood) -> Dict[str, Any]:
    """Chuẩn hóa đối tượng LocalFood kèm danh sách nhà hàng gợi ý và URL Cloudinary."""
    try:
        rec_ids: List[int] = json.loads(food.recommended_restaurant_ids_json or "[]")
    except Exception:
        rec_ids = []

    rec_restaurants = []
    if rec_ids:
        restaurants = (
            db.query(Restaurant)
            .filter(Restaurant.id.in_(rec_ids), Restaurant.status == "published")
            .all()
        )
        for r in restaurants:
            rec_restaurants.append(
                {
                    "id": r.id,
                    "name": r.name,
                    "address": r.address,
                    "price_range": r.price_range,
                    "rating": r.rating,
                    "opening_hours": r.opening_hours,
                    "latitude": r.latitude,
                    "longitude": r.longitude,
                    "thumbnail_url": r.thumbnail_url
                    or cloudinary_service.build_thumbnail_url(r.image_url),
                    "is_sponsored": r.is_sponsored,
                    "sponsor_label": r.sponsor_label,
                }
            )

    thumb_url = food.thumbnail_url or cloudinary_service.build_thumbnail_url(food.image_url)
    detail_img = cloudinary_service.build_detail_url(food.image_url)

    return {
        "id": food.id,
        "province_id": food.province_id,
        "province_name": food.province.name if food.province else None,
        "name": food.name,
        "description": food.description,
        "story_origin": food.story_origin,
        "image_url": detail_img,
        "thumbnail_url": thumb_url,
        "best_season_or_time": food.best_season_or_time,
        "avg_price_range": food.avg_price_range,
        "recommended_restaurant_ids": rec_ids,
        "recommended_restaurants": rec_restaurants,
        "status": food.status,
        "data_source": food.data_source,
        "license_info": food.license_info,
        "updated_at": food.updated_at,
    }


def serialize_restaurant(rest: Restaurant) -> Dict[str, Any]:
    """Chuẩn hóa đối tượng Restaurant kèm URL ảnh Cloudinary, review thực tế và lời nhắc kiểm tra giờ mở cửa."""
    updated_str = (
        rest.last_updated_at.strftime("%d/%m/%Y")
        if rest.last_updated_at
        else datetime.now(timezone.utc).strftime("%d/%m/%Y")
    )
    thumb_url = rest.thumbnail_url or (
        cloudinary_service.build_thumbnail_url(rest.image_url) if rest.image_url else ""
    )
    detail_img = (
        cloudinary_service.build_detail_url(rest.image_url) if rest.image_url else ""
    )

    sample_reviews = []
    raw_reviews_json = getattr(rest, "sample_reviews_json", None)
    if raw_reviews_json:
        try:
            if isinstance(raw_reviews_json, list):
                sample_reviews = raw_reviews_json
            else:
                sample_reviews = json.loads(raw_reviews_json)
        except Exception:
            sample_reviews = []

    rev_cnt = getattr(rest, "reviews_count", None)
    if rev_cnt is None:
        rev_cnt = rest.review_count or 0
    is_high = getattr(rest, "is_high_rated", None)
    if is_high is None:
        is_high = bool(rest.rating >= 4.2 and rev_cnt >= 50)
    spec = getattr(rest, "specialties", None) or rest.specialty_dishes

    return {
        "id": rest.id,
        "province_id": rest.province_id,
        "province_name": rest.province.name if rest.province else None,
        "name": rest.name,
        "address": rest.address,
        "latitude": rest.latitude,
        "longitude": rest.longitude,
        "cuisine_type": rest.cuisine_type,
        "specialty_dishes": rest.specialty_dishes,
        "specialties": spec,
        "price_range": rest.price_range,
        "opening_hours": rest.opening_hours,
        "contact_phone": rest.contact_phone,
        "rating": rest.rating,
        "review_count": rest.review_count,
        "reviews_count": rev_cnt,
        "is_high_rated": is_high,
        "sample_reviews": sample_reviews,
        "image_url": detail_img,
        "thumbnail_url": thumb_url,
        "image_credit": getattr(rest, "image_credit", None),
        "image_license": getattr(rest, "image_license", None),
        "image_source_url": getattr(rest, "image_source_url", None),
        "is_sponsored": rest.is_sponsored,
        "sponsor_label": rest.sponsor_label,
        "is_verified": getattr(rest, "is_verified", False),
        "source": getattr(rest, "source", "admin"),
        "source_url": getattr(rest, "source_url", None),
        "status": rest.status,
        "data_source": rest.data_source,
        "last_updated_at": rest.last_updated_at,
        "hours_verification_notice": (
            f"Thông tin cập nhật lần cuối ngày {updated_str}. "
            f"Khuyến khích kiểm tra lại giờ hoạt động thực tế ({rest.opening_hours}) trước khi di chuyển."
        ),
    }


def serialize_itinerary(itin: Itinerary) -> Dict[str, Any]:
    """Chuẩn hóa đối tượng Itinerary và các điểm dừng theo thứ tự."""
    sorted_stops = sorted(
        itin.stops or [],
        key=lambda s: (s.day_number, s.stop_order, s.id or 0),
    )
    return {
        "id": itin.id,
        "user_id": itin.user_id,
        "province_id": itin.province_id,
        "province_name": itin.province.name if itin.province else None,
        "title": itin.title,
        "description": itin.description,
        "total_days": itin.total_days,
        "is_template": itin.is_template,
        "status": itin.status,
        "created_at": itin.created_at,
        "updated_at": itin.updated_at,
        "stops": [
            {
                "id": s.id,
                "itinerary_id": s.itinerary_id,
                "day_number": s.day_number,
                "stop_order": s.stop_order,
                "stop_type": s.stop_type,
                "reference_id": s.reference_id,
                "title": s.title,
                "address": s.address,
                "latitude": s.latitude,
                "longitude": s.longitude,
                "planned_time": s.planned_time,
                "duration_mins": s.duration_mins,
                "notes": s.notes,
            }
            for s in sorted_stops
        ],
    }
