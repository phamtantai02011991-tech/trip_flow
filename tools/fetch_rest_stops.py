"""Lấy điểm nghỉ chân thật từ OpenStreetMap (cây xăng, sạc EV, trạm dừng nghỉ).

Chỉ lấy POI có tên, nằm trong lõi đô thị của 3 thành phố; xuất JSON để seed.
"""

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path
from typing import Any, Dict, List

import httpx

UA = {"User-Agent": "TripFlowCatalogBot/1.0 (https://tripflow.vn; dev@tripflow.vn)"}
ENDPOINT = "https://overpass-api.de/api/interpreter"

CITIES = {
    "HN": {
        "name": "Hà Nội",
        "bbox": (20.9685, 105.7942, 21.0885, 105.9142),
    },
    "DN": {
        "name": "Đà Nẵng",
        "bbox": (15.9944, 108.1422, 16.1144, 108.2622),
    },
    "HCM": {
        "name": "TP. Hồ Chí Minh",
        "bbox": (10.7169, 106.6409, 10.8369, 106.7609),
    },
}

CATEGORY_QUERIES = {
    "fuel": 'node["amenity"="fuel"]["name"]{bbox};',
    "ev": 'node["amenity"="charging_station"]["name"]{bbox};',
    "rest": 'node["highway"="rest_area"]["name"]{bbox};',
}

CATEGORY_LABEL = {"fuel": "Cây xăng", "ev": "Trạm sạc EV", "rest": "Trạm dừng nghỉ"}
CATEGORY_LIMIT = {"fuel": 14, "ev": 6, "rest": 4}


def overpass(query: str) -> Dict[str, Any]:
    for attempt in range(2):
        try:
            resp = httpx.post(
                ENDPOINT,
                data={"data": query},
                headers=UA,
                timeout=45.0,
            )
            if resp.status_code == 200:
                return resp.json()
            print(f"  HTTP {resp.status_code}, retry {attempt + 1}")
        except Exception as exc:  # pragma: no cover - network
            print(f"  {type(exc).__name__}, retry {attempt + 1}")
        time.sleep(2)
    return {}


def address_of(tags: Dict[str, str], city: str) -> str:
    parts = [
        " ".join(
            filter(None, [tags.get("addr:housenumber"), tags.get("addr:street")])
        ).strip(),
        tags.get("addr:district") or tags.get("addr:suburb") or "",
        tags.get("addr:city") or city,
    ]
    text = ", ".join(p for p in parts if p)
    return text or city


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=".tmp/rest_stops.json")
    args = parser.parse_args()

    records: List[Dict[str, Any]] = []
    for code, city in CITIES.items():
        south, west, north, east = city["bbox"]
        bbox = f"{south},{west},{north},{east}"
        for category, template in CATEGORY_QUERIES.items():
            query = (
                f"[out:json][timeout:30];({template.format(bbox=bbox)});"
                "out 60;"
            )
            print(f"[{code}] {category} ...", flush=True)
            data = overpass(query)
            elements = data.get("elements") or []
            seen = set()
            count = 0
            for element in elements:
                tags = element.get("tags") or {}
                name = (tags.get("name") or "").strip()
                if not name:
                    continue
                lat = element.get("lat") or (element.get("center") or {}).get("lat")
                lng = element.get("lon") or (element.get("center") or {}).get("lon")
                if lat is None or lng is None:
                    continue
                dedupe = (name.lower(), round(float(lat), 4), round(float(lng), 4))
                if dedupe in seen:
                    continue
                seen.add(dedupe)
                records.append(
                    {
                        "key": f"{code.lower()}-{category}-{element.get('type')}-{element.get('id')}",
                        "type": "rest_stop",
                        "category": category,
                        "province_code": code,
                        "name": name,
                        "address": address_of(tags, city["name"]),
                        "latitude": round(float(lat), 6),
                        "longitude": round(float(lng), 6),
                        "opening_hours": tags.get("opening_hours") or "",
                        "phone": tags.get("phone") or tags.get("contact:phone") or "",
                        "description": (
                            tags.get("description")
                            or f"{CATEGORY_LABEL[category]} tại {city['name']}."
                        ),
                        "brand": tags.get("brand") or tags.get("operator") or "",
                        "source": "osm",
                        "source_url": f"https://www.openstreetmap.org/{element.get('type')}/{element.get('id')}",
                        "no_image": True,
                    }
                )
                count += 1
                if count >= CATEGORY_LIMIT[category]:
                    break
            print(f"  +{count}", flush=True)
            time.sleep(5.0)

    output = Path(args.out)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved {len(records)} rest stops -> {output}")


if __name__ == "__main__":
    main()
