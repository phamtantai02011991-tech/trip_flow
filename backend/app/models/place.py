"""Bảng phụ trợ Module 5: cache POI và lịch sử tìm kiếm."""

from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class PlaceCache(SQLModel, table=True):
    """Cache phản hồi Places/Nearby 24h — tránh đốt quota (Goong tính tiền theo request)."""

    __tablename__ = "place_cache"

    id: Optional[int] = Field(default=None, primary_key=True)
    provider: str = Field(max_length=16, index=True)  # goong | google | catalog
    cache_key: str = Field(max_length=200, index=True)
    payload_json: str
    fetched_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    expires_at: datetime


class SearchHistory(SQLModel, table=True):
    __tablename__ = "search_history"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = Field(default=None, foreign_key="users.id", index=True)
    query: str = Field(max_length=200)
    kind: str = Field(default="text", max_length=24)  # text | category | place
    place_id: Optional[str] = Field(default=None, max_length=200)
    lat: Optional[float] = None
    lng: Optional[float] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
