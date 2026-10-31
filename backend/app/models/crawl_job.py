"""Model SQLModel quản lý tiến trình cào dữ liệu tự động (CrawlJob)."""

from datetime import datetime
from typing import Optional
from sqlalchemy import Column, Text
from sqlmodel import Field, SQLModel


class CrawlJob(SQLModel, table=True):
    """
    Bảng lưu trạng thái tiến trình cào dữ liệu ngầm (AI Data Ingestion).
    Trạng thái (status): PENDING, RUNNING, COMPLETED, FAILED.
    """

    __tablename__ = "crawl_jobs"

    id: Optional[int] = Field(default=None, primary_key=True)
    keyword: str = Field(index=True, max_length=250)
    lat: float
    lng: float
    status: str = Field(default="PENDING", index=True, max_length=30)
    total_scraped: int = Field(default=0)
    inserted_count: int = Field(default=0)
    duplicate_count: int = Field(default=0)
    error_message: Optional[str] = Field(default=None, sa_column=Column(Text))
    created_at: datetime = Field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = Field(default=None)
