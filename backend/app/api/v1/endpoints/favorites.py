from typing import Any, Dict, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.models import Destination, Favorite, LocalFood, Restaurant, User
from app.repositories.repositories import (
    serialize_destination,
    serialize_local_food,
    serialize_restaurant,
)
from app.schemas.schemas import FavoriteCreate, FavoriteOut

router = APIRouter()


def _resolve_favorite_target(db: Session, fav: Favorite) -> Dict[str, Any]:
    if fav.target_type == "destination":
        d = db.query(Destination).filter(Destination.id == fav.target_id).first()
        return serialize_destination(d) if d else {}
    if fav.target_type == "restaurant":
        r = db.query(Restaurant).filter(Restaurant.id == fav.target_id).first()
        return serialize_restaurant(r) if r else {}
    if fav.target_type == "local_food":
        f = db.query(LocalFood).filter(LocalFood.id == fav.target_id).first()
        return serialize_local_food(db, f) if f else {}
    return {}


@router.get("", response_model=List[FavoriteOut])
def list_my_favorites(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Lấy danh sách địa điểm, món ăn và nhà hàng yêu thích của người dùng."""
    favs = (
        db.query(Favorite)
        .filter(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
        .all()
    )
    out = []
    for f in favs:
        out.append(
            {
                "id": f.id,
                "user_id": f.user_id,
                "target_type": f.target_type,
                "target_id": f.target_id,
                "target_details": _resolve_favorite_target(db, f),
                "created_at": f.created_at,
            }
        )
    return out


@router.post("", response_model=Dict[str, Any])
def toggle_favorite(
    payload: FavoriteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Thêm hoặc bỏ (toggle) một mục khỏi danh sách yêu thích."""
    existing = (
        db.query(Favorite)
        .filter(
            Favorite.user_id == current_user.id,
            Favorite.target_type == payload.target_type,
            Favorite.target_id == payload.target_id,
        )
        .first()
    )
    if existing:
        db.delete(existing)
        db.commit()
        return {
            "status": "removed",
            "target_type": payload.target_type,
            "target_id": payload.target_id,
        }

    new_fav = Favorite(
        user_id=current_user.id,
        target_type=payload.target_type,
        target_id=payload.target_id,
    )
    db.add(new_fav)
    db.commit()
    db.refresh(new_fav)
    return {
        "status": "added",
        "id": new_fav.id,
        "target_type": new_fav.target_type,
        "target_id": new_fav.target_id,
    }


@router.delete("/{favorite_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_favorite(
    favorite_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Xóa một mục yêu thích theo ID."""
    fav = (
        db.query(Favorite)
        .filter(Favorite.id == favorite_id, Favorite.user_id == current_user.id)
        .first()
    )
    if not fav:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy mục yêu thích.",
        )
    db.delete(fav)
    db.commit()
    return None
