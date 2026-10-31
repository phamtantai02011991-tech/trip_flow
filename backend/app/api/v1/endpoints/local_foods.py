from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.models import LocalFood
from app.repositories.repositories import serialize_local_food
from app.schemas.schemas import LocalFoodOut

router = APIRouter()


@router.get("", response_model=List[LocalFoodOut])
def list_local_foods(
    province_id: Optional[int] = Query(default=None, description="Lọc theo ID tỉnh/thành"),
    q: Optional[str] = Query(default=None, description="Từ khóa tên món ăn hoặc mô tả"),
    db: Session = Depends(get_db),
):
    """Lấy danh sách đặc sản / món ăn địa phương kèm danh sách nhà hàng gợi ý thưởng thức."""
    query = db.query(LocalFood).filter(LocalFood.status == "published")
    if province_id is not None:
        query = query.filter(LocalFood.province_id == province_id)
    if q and q.strip():
        kw = f"%{q.strip()}%"
        query = query.filter(
            or_(
                LocalFood.name.ilike(kw),
                LocalFood.description.ilike(kw),
                LocalFood.story_origin.ilike(kw),
            )
        )
    foods = query.order_by(LocalFood.id.asc()).all()
    return [serialize_local_food(db, f) for f in foods]


@router.get("/{food_id}", response_model=LocalFoodOut)
def get_local_food_detail(food_id: int, db: Session = Depends(get_db)):
    """Xem thông tin chi tiết một món ăn đặc sản địa phương."""
    food = (
        db.query(LocalFood)
        .filter(LocalFood.id == food_id, LocalFood.status != "hidden")
        .first()
    )
    if not food:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy món ăn/đặc sản yêu cầu.",
        )
    return serialize_local_food(db, food)
