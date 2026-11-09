"""Tiện ích thời gian dùng chung.

SQLModel 0.0.48 yêu cầu mọi giá trị `datetime` ghi xuống DB phải có timezone.
Toàn bộ hệ thống lưu theo UTC; helper này chuẩn hoá dữ liệu do client gửi lên.
"""

from datetime import datetime, timezone


def utcnow() -> datetime:
    """Thời điểm hiện tại theo UTC, có timezone."""
    return datetime.now(timezone.utc)


def as_utc(value: datetime | None) -> datetime | None:
    """Gắn UTC cho datetime naive; giữ nguyên nếu đã có timezone."""
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)
