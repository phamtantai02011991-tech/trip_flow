"""Lấy điểm nghỉ chân (cây xăng, sạc EV, trạm dừng nghỉ) qua Nominatim viewbox.

Nominatim ổn định hơn Overpass cho truy vấn theo thương hiệu trong một khung đô thị.
"""

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path
from typing import Any, Dict, List

import httpx

UA = {"User-Agent": "TripFlowCatalogBot/1.0 (https://tripflow.vn; dev@tripflow.vn)"}
ENDPOINT = "https://nominatim.openstreetmap.org/search"

CITIES = {
    "HN": {
        "name": "Hà Nội",
        # left, top, right, bottom
        "viewbox": (105.75, 21.10, 105.92, 20.96),
    },
    "DN": {
        "name": "Đà Nẵng",
        "viewbox": (108.14, 16.12, 108.27, 15.98),
    },
    "HCM": {
        "name": "TP. Hồ Chí Minh",
        "viewbox": (106.64, 10.84, 106.78, 10.70),
    },
}

QUERIES = [
    ("fuel", "Petrolimex", 8),
    ("fuel", "cây xăng", 4),
    ("ev", "VinFast", 5),
    ("ev", "trạm sạc", 3),
    ("rest", "trạm dừng nghỉ", 3),
]

LABEL = {"fuel": "Cây xăng", "ev": "Trạm sạc EV", "rest": "Trạm dừng nghỉ"}


def search(query: str, viewbox: tuple) -> List[Dict[str, Any]]:
    left, top, right, bottom = viewbox
    for attempt in range(3):
        try:
            resp = httpx.get(
                ENDPOINT,
                params={
                    "q": query,
                    "format": "jsonv2",
                    "addressdetails": 1,
                    "viewbox": f"{left},{top},{right},{bottom}",
                    "bounded": 1,
                    "limit": 20,
                },
                headers=UA,
                timeout=30.0,
            )
            if resp.status_code == 200:
                return resp.json()
        except Exception:
            pass
        time.sleep(2)
    return []


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=".tmp/rest_stops.json")
    args = parser.parse_args()

    records: List[Dict[str, Any]] = []
    for code, city in CITIES.items():
        for category, query, limit in QUERIES:
            print(f"[{code}] {query} ...", flush=True)
            rows = search(query, city["viewbox"])
            count = 0
            seen = set()
            for row in rows:
                name = (row.get("name") or row.get("display_name", "").split(",")[0]).strip()
                if not name:
                    continue
                lat = float(row["lat"])
                lng = float(row["lon"])
                dedupe = (name.lower(), round(lat, 4), round(lng, 4))
                if dedupe in seen:
                    continue
                seen.add(dedupe)
                address = row.get("display_name") or city["name"]
                records.append(
                    {
                        "key": f"{code.lower()}-{category}-{row.get('osm_type')}-{row.get('osm_id')}",
                        "type": "rest_stop",
                        "category": category,
                        "province_code": code,
                        "name": name,
                        "address": address,
                        "latitude": round(lat, 6),
                        "longitude": round(lng, 6),
                        "opening_hours": "",
                        "phone": "",
                        "description": f"{LABEL[category]} tại {city['name']}.",
                        "brand": name.split()[0] if name else "",
                        "source": "osm",
                        "source_url": f"https://www.openstreetmap.org/{row.get('osm_type')}/{row.get('osm_id')}",
                        "no_image": True,
                    }
                )
                count += 1
                if count >= limit:
                    break
            print(f"  +{count}", flush=True)
            time.sleep(1.2)

    output = Path(args.out)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved {len(records)} rest stops -> {output}")


if __name__ == "__main__":
    main()
