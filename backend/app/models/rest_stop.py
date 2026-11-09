"""Điểm nghỉ chân dọc đường: cây xăng, sạc EV, trạm dừng nghỉ, điểm ngắm cảnh."""

from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Column, Text
from sqlmodel import Field, SQLModel


class RestStop(SQLModel, table=True):
    """POI phục vụ nghỉ chân trên tuyến đường (không phải quán ăn/địa điểm tham quan)."""

    __tablename__ = "rest_stops"

    id: Optional[int] = Field(default=None, primary_key=True)
    province_id: int = Field(foreign_key="provinces.id", index=True)

    # fuel | ev | rest | viewpoint | park | mechanic | toilet | cafe
    category: str = Field(default="rest", index=True, max_length=30)
    name: str = Field(index=True, max_length=220)
    address: str = Field(default="", max_length=350)
    latitude: float = Field(index=True)
    longitude: float = Field(index=True)

    opening_hours: str = Field(default="", max_length=150)
    phone: Optional[str] = Field(default=None, max_length=50)
    description: Optional[str] = Field(default=None, sa_column=Column(Text))
    brand: Optional[str] = Field(default=None, max_length=150)

    image_url: Optional[str] = Field(default=None, max_length=550)
    thumbnail_url: Optional[str] = Field(default=None, max_length=550)
    image_credit: Optional[str] = Field(default=None, max_length=250)
    image_license: Optional[str] = Field(default=None, max_length=120)
    image_source_url: Optional[str] = Field(default=None, max_length=550)

    rating: float = Field(default=0.0)
    review_count: int = Field(default=0)
    is_verified: bool = Field(default=False, index=True)

    source: str = Field(default="osm", max_length=60)
    source_url: Optional[str] = Field(default=None, max_length=550)
    status: str = Field(default="published", index=True, max_length=30)
    data_source: str = Field(default="osm", max_length=60)
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
