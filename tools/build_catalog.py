"""Chuẩn hoá kết quả nghiên cứu thành catalog cho backend TripFlow."""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from pathlib import Path
from typing import Any, Dict, List

TYPE_TO_DEST_CATEGORY = {
    "heritage": "heritage",
    "religious": "heritage",
    "museum": "museum",
    "market": "market",
    "nature": "street_walk",
    "viewpoint": "street_walk",
    "craft": "market",
    "architecture": "architecture",
}

CITY_ORDER = {"Hà Nội": 1, "Đà Nẵng": 2, "TP. Hồ Chí Minh": 3}


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFD", text or "")
    text = "".join(ch for ch in text if unicodedata.category(ch) != "Mn")
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


def normalize_record(record: Dict[str, Any]) -> Dict[str, Any]:
    image = record.get("image") or {}
    out = {
        "key": record.get("key") or slugify(f"{record['province_code']}-{record['name']}"),
        "type": record.get("type"),
        "province_code": record["province_code"],
        "name": record["name"],
        "slug": slugify(record["name"]),
        "description": record.get("description") or record.get("note") or "",
        "address": record.get("address") or record.get("address_osm") or "",
        "lat": record.get("lat"),
        "lng": record.get("lng"),
        "category": record.get("category") or "heritage",
        "cuisine": record.get("cuisine") or "",
        "specialties": record.get("specialties") or record.get("cuisine") or "",
        "price_range": record.get("price_range") or "",
        "opening_hours": record.get("open_hours") or "",
        "phone": record.get("phone") or "",
        "stars": record.get("stars"),
        "tags": record.get("tags") or [],
        "wikidata": record.get("wikidata"),
        "wikipedia": record.get("wikipedia"),
        "photo_status": record.get("photo_status"),
        "image": None,
    }
    if image.get("url"):
        raw_url = (image.get("url") or "").split("?")[0]
        thumb_url = (image.get("thumb_url") or raw_url).split("?")[0]
        thumb_url = thumb_url.replace("/400px-", "/1280px-")
        out["image"] = {
            "url": raw_url,
            "thumb_url": thumb_url,
            "license": image.get("license") or "",
            "author": image.get("author") or "",
            "source_url": image.get("source_url") or "",
        }
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputs", nargs="+", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    records: List[Dict[str, Any]] = []
    for path in args.inputs:
        loaded = json.loads(Path(path).read_text(encoding="utf-8"))
        if isinstance(loaded, dict):
            loaded = loaded.get("records") or []
        for record in loaded:
            normalized = normalize_record(record)
            if normalized.get("lat") is None or normalized.get("lng") is None:
                print(f"SKIP (no coords): {normalized['name']}")
                continue
            records.append(normalized)

    # Loại trùng theo (province, name), giữ bản ghi đầu tiên.
    seen = set()
    deduped: List[Dict[str, Any]] = []
    for record in records:
        key = (record["province_code"], record["name"].strip().lower())
        if key in seen:
            print(f"SKIP (duplicate): {record['name']}")
            continue
        seen.add(key)
        deduped.append(record)

    deduped.sort(
        key=lambda r: (
            CITY_ORDER.get(
                {"HN": "Hà Nội", "DN": "Đà Nẵng", "HCM": "TP. Hồ Chí Minh"}.get(
                    r["province_code"], ""
                ),
                99,
            ),
            {"destination": 0, "restaurant": 1, "cafe": 2, "hotel": 3}.get(r["type"], 9),
            r["name"],
        )
    )

    with_images = sum(1 for r in deduped if r.get("image"))
    payload = {
        "version": 1,
        "source": "OpenStreetMap + Wikipedia + Wikimedia Commons",
        "generated_at": "2026-11-06",
        "record_count": len(deduped),
        "with_image": with_images,
        "records": deduped,
    }

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved {len(deduped)} records ({with_images} ảnh) -> {out}")


if __name__ == "__main__":
    main()
