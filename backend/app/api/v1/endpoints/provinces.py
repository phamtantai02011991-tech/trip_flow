from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.models import Category, Destination, LocalFood, Province, Restaurant
from app.schemas.schemas import CategoryOut, ProvinceOut, RegionSummaryOut

router = APIRouter()

REGIONS_ORDER = ["Bắc Bộ", "Trung Bộ", "Tây Nguyên", "Nam Bộ"]


def _serialize_province_with_counts(db: Session, prov: Province) -> dict:
    dest_count = (
        db.query(Destination)
        .filter(Destination.province_id == prov.id, Destination.status == "published")
        .count()
    )
    food_count = (
        db.query(LocalFood)
        .filter(LocalFood.province_id == prov.id, LocalFood.status == "published")
        .count()
    )
    rest_count = (
        db.query(Restaurant)
        .filter(Restaurant.province_id == prov.id, Restaurant.status == "published")
        .count()
    )
    return {
        "id": prov.id,
        "code": prov.code,
        "name": prov.name,
        "region": prov.region,
        "description": prov.description,
        "hero_image": prov.hero_image,
        "center_lat": prov.center_lat,
        "center_lng": prov.center_lng,
        "is_active": prov.is_active,
        "data_source": prov.data_source,
        "updated_at": prov.updated_at,
        "destination_count": dest_count,
        "food_count": food_count,
        "restaurant_count": rest_count,
    }


@router.get("", response_model=List[ProvinceOut])
def list_provinces(
    active_only: bool = Query(default=True, description="Chỉ lấy các tỉnh/thành đang hiển thị"),
    region: Optional[str] = Query(
        default=None,
        description="Lọc theo vùng miền: Bắc Bộ, Trung Bộ, Tây Nguyên, Nam Bộ",
    ),
    q: Optional[str] = Query(
        default=None,
        description="Tìm kiếm theo tên tỉnh, mã tỉnh hoặc mô tả",
    ),
    db: Session = Depends(get_db),
):
    """Lấy danh sách 10 tỉnh/thành phố kèm số lượng địa điểm, món ăn và nhà hàng."""
    query = db.query(Province)
    if active_only:
        query = query.filter(Province.is_active == True)
    if region and region.strip() and region.strip().lower() not in ("all", "tất cả"):
        query = query.filter(Province.region.ilike(f"%{region.strip()}%"))
    if q and q.strip():
        kw = f"%{q.strip()}%"
        query = query.filter(
            or_(
                Province.name.ilike(kw),
                Province.code.ilike(kw),
                Province.region.ilike(kw),
                Province.description.ilike(kw),
            )
        )
    provinces = query.order_by(Province.id.asc()).all()
    return [_serialize_province_with_counts(db, p) for p in provinces]


@router.get("/regions/summary", response_model=List[RegionSummaryOut])
def get_regions_summary(
    active_only: bool = Query(default=True, description="Chỉ thống kê các tỉnh/thành đang hoạt động"),
    db: Session = Depends(get_db),
):
    """Thống kê số lượng tỉnh/thành, địa điểm, đặc sản và nhà hàng theo 4 vùng miền Việt Nam."""
    query = db.query(Province)
    if active_only:
        query = query.filter(Province.is_active == True)
    all_provs = query.order_by(Province.id.asc()).all()
    serialized = [_serialize_province_with_counts(db, p) for p in all_provs]

    region_map = {
        reg: {
            "region": reg,
            "province_count": 0,
            "destination_count": 0,
            "food_count": 0,
            "restaurant_count": 0,
            "provinces": [],
        }
        for reg in REGIONS_ORDER
    }

    for p in serialized:
        reg = p["region"]
        if reg not in region_map:
            region_map[reg] = {
                "region": reg,
                "province_count": 0,
                "destination_count": 0,
                "food_count": 0,
                "restaurant_count": 0,
                "provinces": [],
            }
        entry = region_map[reg]
        entry["province_count"] += 1
        entry["destination_count"] += p["destination_count"]
        entry["food_count"] += p["food_count"]
        entry["restaurant_count"] += p["restaurant_count"]
        entry["provinces"].append(p["name"])

    return list(region_map.values())


@router.get("/categories", response_model=List[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    """Lấy danh sách các danh mục địa điểm du lịch."""
    return db.query(Category).order_by(Category.id.asc()).all()


@router.get("/{province_id}", response_model=ProvinceOut)
def get_province_detail(province_id: int, db: Session = Depends(get_db)):
    """Xem thông tin chi tiết một tỉnh/thành phố."""
    prov = db.query(Province).filter(Province.id == province_id).first()
    if not prov:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy tỉnh/thành phố yêu cầu.",
        )
    return _serialize_province_with_counts(db, prov)
