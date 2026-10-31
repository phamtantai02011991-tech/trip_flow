#!/usr/bin/env python3
"""
CLI Script kiểm thử độc lập Engine Cào Dữ Liệu Google Maps (`GoogleMapsCrawler` + `normalizer`).
Cách chạy tại thư mục `backend/`:
    python scripts/run_crawler_cli.py "quán ăn ngon" 10.762622 106.660172

Script này chạy hoàn toàn độc lập, KHÔNG cần kết nối Database hay bật server FastAPI,
và in ra màn hình danh sách JSON >= 15 địa điểm/quán ăn đã được làm sạch và kiểm tra tọa độ Việt Nam.
"""

import asyncio
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

# Đảm bảo import được package `app.*` khi chạy từ `backend/` hoặc thư mục gốc
BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

# Bật cấu hình UTF-8 cho stdout trên Windows để hiển thị tiếng Việt có dấu chuẩn xác
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

from app.services.crawler.google_maps import GoogleMapsCrawler  # noqa: E402
from app.services.crawler.normalizer import (  # noqa: E402
    clean_scraped_place,
    is_valid_vn_location,
)


async def run_cli_crawl(
    keyword: str = "quán ăn ngon",
    lat: float = 10.762622,
    lng: float = 106.660172,
    max_results: int = 15,
) -> List[Dict[str, Any]]:
    """Thực thi cào dữ liệu bất đồng bộ và làm sạch kết quả mà không cần kết nối DB."""
    crawler = GoogleMapsCrawler(headless=True)
    raw_places = await crawler.search(
        keyword=keyword,
        lat=lat,
        lng=lng,
        max_results=max_results,
    )

    cleaned_places: List[Dict[str, Any]] = []
    for raw in raw_places:
        cleaned = clean_scraped_place(raw)
        if cleaned["name"] and is_valid_vn_location(cleaned["lat"], cleaned["lng"]):
            cleaned_places.append(cleaned)

    return cleaned_places


def main() -> int:
    keyword = sys.argv[1] if len(sys.argv) > 1 else "quán ăn ngon"
    try:
        lat = float(sys.argv[2]) if len(sys.argv) > 2 else 10.762622
        lng = float(sys.argv[3]) if len(sys.argv) > 3 else 106.660172
    except ValueError:
        print(
            json.dumps(
                {"error": "Tham số vĩ độ (lat) và kinh độ (lng) phải là số thực hợp lệ."},
                ensure_ascii=False,
            )
        )
        return 1

    results = asyncio.run(run_cli_crawl(keyword=keyword, lat=lat, lng=lng, max_results=15))
    print(json.dumps(results, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
