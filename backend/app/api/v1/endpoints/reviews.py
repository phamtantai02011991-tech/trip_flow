"""API đánh giá địa điểm — review thật do người dùng TripFlow viết.

Khác với `rating` trong bảng catalog (dữ liệu seed/admin), bảng này là nguồn
đánh giá do người dùng tạo, tách riêng để không lẫn hai loại dữ liệu.
"""

from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import Field
from sqlmodel import Session, SQLModel, select

from app.core.security import get_current_user, get_current_user_optional
from app.db.session import get_db
from app.models.models import User
from app.models.review import PlaceReview

router = APIRouter()


class ReviewCreate(SQLModel):
    rating: int = Field(ge=1, le=5)
    comment: str = Field(default="", max_length=1000)
    author_name: Optional[str] = Field(default=None, max_length=80)
    visited_on: Optional[datetime] = None


class ReviewOut(SQLModel):
    id: int
    place_key: str
    author_name: str
    rating: int
    comment: str
    created_at: datetime
    is_mine: bool = False


class ReviewSummary(SQLModel):
    place_key: str
    avg_rating: Optional[float] = None
    review_count: int = 0
    distribution: dict[str, int] = Field(default_factory=dict)
    hidden_gem: bool = False


@router.get("/{place_key}", response_model=list[ReviewOut])
def list_reviews(
    place_key: str,
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    rows = db.exec(
        select(PlaceReview)
        .where(PlaceReview.place_key == place_key, PlaceReview.is_hidden == False)  # noqa: E712
        .order_by(PlaceReview.created_at.desc())
        .limit(limit)
    ).all()
    return [
        ReviewOut(
            id=r.id,
            place_key=r.place_key,
            author_name=r.author_name,
            rating=r.rating,
            comment=r.comment,
            created_at=r.created_at,
            is_mine=bool(current_user and r.user_id == current_user.id),
        )
        for r in rows
    ]


@router.get("/{place_key}/summary", response_model=ReviewSummary)
def review_summary(place_key: str, db: Session = Depends(get_db)):
    rows = db.exec(
        select(PlaceReview).where(
            PlaceReview.place_key == place_key, PlaceReview.is_hidden == False  # noqa: E712
        )
    ).all()
    if not rows:
        return ReviewSummary(place_key=place_key)

    distribution = {str(star): 0 for star in range(1, 6)}
    for row in rows:
        distribution[str(row.rating)] = distribution.get(str(row.rating), 0) + 1

    avg = round(sum(r.rating for r in rows) / len(rows), 2)
    # "Quán ruột": điểm trung bình cao nhưng chưa quá nhiều review
    hidden_gem = avg >= 4.5 and 3 <= len(rows) <= 200
    return ReviewSummary(
        place_key=place_key,
        avg_rating=avg,
        review_count=len(rows),
        distribution=distribution,
        hidden_gem=hidden_gem,
    )


@router.post("/{place_key}", response_model=ReviewOut, status_code=201)
def create_review(
    place_key: str,
    payload: ReviewCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Cho phép khách đánh giá (không cần đăng nhập) — dùng `author_name` thay tên tài khoản.

    Khi đã đăng nhập: mỗi người chỉ 1 đánh giá/địa điểm, gửi lại thì cập nhật.
    """
    user_id = current_user.id if current_user else None

    existing = None
    if user_id is not None:
        existing = db.exec(
            select(PlaceReview).where(
                PlaceReview.place_key == place_key, PlaceReview.user_id == user_id
            )
        ).first()

    if existing:
        existing.rating = payload.rating
        existing.comment = payload.comment
        existing.visited_on = payload.visited_on
        db.add(existing)
        db.commit()
        db.refresh(existing)
        return ReviewOut(
            id=existing.id,
            place_key=existing.place_key,
            author_name=existing.author_name,
            rating=existing.rating,
            comment=existing.comment,
            created_at=existing.created_at,
            is_mine=True,
        )

    row = PlaceReview(
        place_key=place_key,
        user_id=user_id,
        author_name=payload.author_name
        or (getattr(current_user, "full_name", None) if current_user else None)
        or "Khách TripFlow",
        rating=payload.rating,
        comment=payload.comment,
        visited_on=payload.visited_on,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return ReviewOut(
        id=row.id,
        place_key=row.place_key,
        author_name=row.author_name,
        rating=row.rating,
        comment=row.comment,
        created_at=row.created_at,
        is_mine=True,
    )


@router.delete("/{place_key}/{review_id}", status_code=204)
def delete_review(
    place_key: str,
    review_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    row = db.get(PlaceReview, review_id)
    if row is None or row.place_key != place_key or row.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Không tìm thấy đánh giá")
    db.delete(row)
    db.commit()
    return None
