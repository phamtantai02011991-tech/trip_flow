"""Module 4 mở rộng — đánh giá của người dùng TripFlow (không phải dữ liệu mẫu)."""

from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


class PlaceReview(SQLModel, table=True):
    __tablename__ = "place_reviews"

    id: Optional[int] = Field(default=None, primary_key=True)
    # Khoá địa điểm: "r_8" (quán ăn) | "d_12" (địa điểm) | "p_<place_id>" (Places)
    place_key: str = Field(index=True, max_length=120)
    user_id: Optional[int] = Field(default=None, foreign_key="users.id", index=True)
    author_name: str = Field(default="Khách", max_length=80)
    rating: int = Field(ge=1, le=5)
    comment: str = Field(default="", max_length=1000)
    visited_on: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_hidden: bool = Field(default=False)
