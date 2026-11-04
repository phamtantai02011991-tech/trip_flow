"""
Bộ làm sạch dữ liệu (Data Normalizer), kiểm tra tọa độ lãnh thổ Việt Nam
và chống trùng lặp bằng truy vấn ILIKE cho Module AI Data Ingestion.
"""

import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, Optional, Type

# Đảm bảo thư mục backend luôn nằm trong sys.path để hỗ trợ cả 2 cách import
_BACKEND_DIR = str(Path(__file__).resolve().parents[3])
if _BACKEND_DIR not in sys.path:
    sys.path.insert(0, _BACKEND_DIR)

from sqlalchemy import or_
# pyrefly: ignore[missing-import]
from sqlmodel import SQLModel, Session, select

try:
    from app.models.models import Restaurant
except ImportError:
    from backend.app.models.models import Restaurant  # type: ignore

# Khung tọa độ địa lý hợp lệ của lãnh thổ Việt Nam (Đất liền & Hải đảo)
VN_MIN_LAT = 8.18
VN_MAX_LAT = 23.39
VN_MIN_LNG = 102.14
VN_MAX_LNG = 109.46

# Biểu thức chính quy loại bỏ ký tự icon Private Use Area của Google Maps và ký tự điều khiển
_GMAPS_ICON_RE = re.compile(r"[\ue000-\uf8ff\u200b-\u200f\ufeff]+")
_BULLET_PREFIX_RE = re.compile(r"^[\s•·⋅|\-:]+|[\s•·⋅|\-:]+$")
_LABEL_PREFIX_RE = re.compile(
    r"^(địa\s*chỉ|address|điện\s*thoại|phone|tel)\s*[:\-]\s*",
    flags=re.IGNORECASE,
)
_MULTI_SPACE_RE = re.compile(r"\s{2,}")
_PHONE_CLEAN_RE = re.compile(r"[^\d+\s.\-]")


def is_valid_vn_location(lat: float, lng: float) -> bool:
    """
    Kiểm tra tọa độ (lat, lng) có nằm trong lãnh thổ Việt Nam hay không:
    - Vĩ độ (lat): từ 8.18 đến 23.39
    - Kinh độ (lng): từ 102.14 đến 109.46
    """
    try:
        lat_val = float(lat)
        lng_val = float(lng)
    except (TypeError, ValueError):
        return False

    return (VN_MIN_LAT <= lat_val <= VN_MAX_LAT) and (VN_MIN_LNG <= lng_val <= VN_MAX_LNG)


def _clean_text(value: Any) -> str:
    """Làm sạch chuỗi văn bản, xóa icon rác của Google Maps và khoảng trắng thừa."""
    if value is None:
        return ""
    text = str(value)
    text = _GMAPS_ICON_RE.sub(" ", text)
    text = _LABEL_PREFIX_RE.sub("", text.strip())
    text = _BULLET_PREFIX_RE.sub("", text)
    text = _MULTI_SPACE_RE.sub(" ", text).strip()
    return text


def _clean_phone(value: Any) -> Optional[str]:
    """Chuẩn hóa số điện thoại Việt Nam từ chuỗi thô của Google Maps."""
    cleaned = _clean_text(value)
    if not cleaned:
        return None
    phone = _PHONE_CLEAN_RE.sub("", cleaned)
    phone = _MULTI_SPACE_RE.sub(" ", phone).strip()
    digits_only = re.sub(r"\D", "", phone)
    if len(digits_only) < 8 or len(digits_only) > 15:
        return None
    return phone


def _clean_rating(value: Any, default: float = 4.5) -> float:
    """Chuẩn hóa điểm đánh giá (rating) về số thực trong khoảng [1.0, 5.0]."""
    if value is None:
        return default
    if isinstance(value, (int, float)):
        r = float(value)
    else:
        raw_str = str(value).strip().replace(",", ".")
        match = re.search(r"(\d+(?:\.\d+)?)", raw_str)
        if not match:
            return default
        try:
            r = float(match.group(1))
        except ValueError:
            return default
    return round(min(max(r, 1.0), 5.0), 1)


def _clean_reviews_count(value: Any, default: int = 120) -> int:
    """
    Chuẩn hóa số lượng đánh giá thực tế từ Google Maps:
    Hỗ trợ các định dạng: 450, "450", "(1.240)", "1,5k reviews", "3.2k đánh giá", "5k+".
    """
    if value is None:
        return default
    if isinstance(value, (int, float)):
        return max(0, int(value))
    raw_str = str(value).strip().lower()
    if not raw_str:
        return default

    has_k = "k" in raw_str
    # Xóa dấu chấm phân tách hàng nghìn nếu không có k (ví dụ: 1.240 -> 1240)
    cleaned_num_str = raw_str
    if not has_k and re.search(r"\d+\.\d{3}", cleaned_num_str):
        cleaned_num_str = cleaned_num_str.replace(".", "")
    elif not has_k and re.search(r"\d+,\d{3}", cleaned_num_str):
        cleaned_num_str = cleaned_num_str.replace(",", "")

    match = re.search(r"(\d+(?:[.,]\d+)?)", cleaned_num_str)
    if not match:
        return default
    num_part = match.group(1).replace(",", ".")
    try:
        val = float(num_part)
        if has_k:
            val = val * 1000.0
        return max(0, int(round(val)))
    except Exception:
        return default


def clean_scraped_place(raw: Dict[str, Any]) -> Dict[str, Any]:
    """
    Làm sạch và chuẩn hóa một bản ghi địa điểm/quán ăn thu thập từ Google Maps:
    - Xóa ký tự rác/icon đặc biệt trong `name` và `address`
    - Chuẩn hóa `phone`, `rating`, `reviews_count`, `lat`, `lng`
    - Bóc tách danh sách trích đoạn đánh giá thực tế `sample_reviews`
    - Tính toán cờ boolean `is_high_rated` và trích xuất `specialties`
    - Giữ nguyên URL ảnh trực tiếp `image_url` và `source_url` (tuyệt đối không tải file ảnh về ổ cứng).
    """
    name = _clean_text(raw.get("name"))
    address = _clean_text(raw.get("address"))
    if "·" in address:
        parts = [p.strip() for p in address.split("·") if p.strip()]
        if parts:
            address = parts[-1]

    phone = _clean_phone(raw.get("phone") or raw.get("contact_phone"))
    rating = _clean_rating(raw.get("rating"), default=4.5)
    reviews_count = _clean_reviews_count(
        raw.get("reviews_count") or raw.get("review_count"), default=120
    )

    try:
        lat = round(float(raw.get("lat", raw.get("latitude", 0.0))), 6)
    except (TypeError, ValueError):
        lat = 0.0

    try:
        lng = round(float(raw.get("lng", raw.get("longitude", 0.0))), 6)
    except (TypeError, ValueError):
        lng = 0.0

    image_url = _clean_text(raw.get("image_url")) or (
        "https://lh3.googleusercontent.com/p/AF1QipN_TripFlow_Default_Place=w600-h400-k-no"
    )
    source_url = _clean_text(raw.get("source_url")) or (
        f"https://www.google.com/maps/search/?api=1&query={lat},{lng}"
    )
    cuisine_type = _clean_text(
        raw.get("cuisine_type") or raw.get("category") or "Ẩm thực địa phương"
    )
    specialties = _clean_text(
        raw.get("specialties") or raw.get("specialty_dishes") or raw.get("signature_dish") or ""
    )

    # Xử lý trích đoạn bình luận thực tế
    raw_reviews = raw.get("sample_reviews", [])
    if isinstance(raw_reviews, str):
        try:
            import json
            raw_reviews = json.loads(raw_reviews)
        except Exception:
            raw_reviews = []
    
    clean_reviews = []
    if isinstance(raw_reviews, list):
        for item in raw_reviews:
            if isinstance(item, dict):
                r_text = _clean_text(item.get("text"))
                if r_text:
                    clean_reviews.append(
                        {
                            "author": _clean_text(item.get("author") or "Thực khách Google Maps"),
                            "rating": _clean_rating(item.get("rating"), default=5.0),
                            "text": r_text,
                            "relative_time": _clean_text(item.get("relative_time") or "Gần đây"),
                        }
                    )

    is_high_rated = bool(rating >= 4.2 and reviews_count >= 50)

    return {
        "name": name,
        "address": address or "TP. Hồ Chí Minh, Việt Nam",
        "phone": phone,
        "rating": rating,
        "reviews_count": reviews_count,
        "sample_reviews": clean_reviews,
        "is_high_rated": is_high_rated,
        "specialties": specialties,
        "lat": lat,
        "lng": lng,
        "image_url": image_url,
        "source_url": source_url,
        "cuisine_type": cuisine_type,
    }


def check_duplicate(
    db: Session,
    name: str,
    address: Optional[str] = None,
    model_cls: Type[SQLModel] = Restaurant,
) -> bool:
    """
    Kiểm tra trùng lặp trong Database bằng toán tử ILIKE không phân biệt hoa thường.
    Trả về True nếu đã tồn tại địa điểm cùng tên và cùng địa chỉ (hoặc trùng tên hoàn toàn).
    """
    cleaned_name = _clean_text(name)
    if not cleaned_name:
        return False

    cleaned_address = _clean_text(address) if address else ""

    name_col = getattr(model_cls, "name")
    addr_col = getattr(model_cls, "address", None)

    if cleaned_address and addr_col is not None:
        short_addr = cleaned_address.split(",")[0].strip()
        stmt = select(model_cls).where(
            name_col.ilike(cleaned_name),
            or_(
                addr_col.ilike(cleaned_address),
                addr_col.ilike(f"%{short_addr}%"),
            ),
        )
        existing = db.exec(stmt).first()
        if existing is not None:
            return True

    # Kiểm tra trùng khớp chính xác tên địa điểm không phân biệt hoa thường bằng ILIKE
    stmt_name_only = select(model_cls).where(name_col.ilike(cleaned_name))
    existing_by_name = db.exec(stmt_name_only).first()
    return existing_by_name is not None
