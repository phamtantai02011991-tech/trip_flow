"""Nghiên cứu catalog TripFlow từ nguồn mở.

- Toạ độ: OpenStreetMap Nominatim (fallback Wikidata P625).
- Mô tả: Wikipedia tiếng Việt (đoạn mở đầu).
- Ảnh: Wikidata P18 / Wikipedia page image / Wikimedia Commons (có giấy phép).
- Chỉ nhận ảnh khi tiêu đề tệp khớp tên địa điểm (tránh ảnh không liên quan).

Chạy: python tools/research_catalog.py --out .tmp/research.json
"""

from __future__ import annotations

import argparse
import json
import re
import time
import unicodedata
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import httpx

from catalog_input import ALL_ITEMS

UA = {
    "User-Agent": "TripFlowCatalogBot/1.0 (https://tripflow.vn; dev@tripflow.vn)"
}
client = httpx.Client(headers=UA, timeout=30.0, follow_redirects=True)

NOMINATIM = "https://nominatim.openstreetmap.org/search"
COMMONS_API = "https://commons.wikimedia.org/w/api.php"
WIKIDATA_API = "https://www.wikidata.org/w/api.php"
WIKI_API = "https://{lang}.wikipedia.org/w/api.php"

BAD_FILE_TOKENS = (
    "map",
    "bản đồ",
    "logo",
    "icon",
    "diagram",
    "plan",
    "pdf",
    "svg",
    "coat of arms",
    "seal",
    "banknote",
    "stamp",
)

# Từ chung của ngành hàng/quán ăn: không đủ để xác định một địa điểm cụ thể.
GENERIC_TOKENS = {
    "bun", "cha", "pho", "banh", "mi", "com", "chao", "cafe", "phe", "ca",
    "quan", "nha", "hang", "restaurant", "hotel", "khach", "san", "resort",
    "coffee", "bar", "pub", "grill", "an", "uong", "dac", "mon", "ngon",
    "food", "street", "house", "homestay", "spa", "buffet", "lau", "nuong",
    "che", "kem", "bo", "ga", "thit", "trung", "hai", "san", "quay", "xeo",
    "cuon", "goi", "xoi", "canh", "rieu", "oc", "mien", "luon", "banh",
}

CITY_BBOX = {
    "Hà Nội": (20.50, 21.50, 105.20, 106.20),
    "Đà Nẵng": (15.90, 16.25, 107.75, 108.45),
    "TP. Hồ Chí Minh": (10.30, 11.25, 106.30, 107.10),
    "Quảng Ninh": (20.60, 21.60, 106.30, 108.20),
    "Lào Cai": (21.80, 22.90, 102.90, 104.60),
    "Thừa Thiên Huế": (15.90, 16.90, 106.90, 108.30),
    "Quảng Nam": (14.90, 16.20, 107.20, 108.70),
    "Khánh Hòa": (11.60, 12.70, 108.50, 109.60),
    "Lâm Đồng": (11.20, 12.50, 107.20, 109.00),
    "Kiên Giang": (9.70, 10.70, 103.30, 104.60),
}

CITY_ALIASES = {
    "Hà Nội": ("ha noi", "hanoi"),
    "Đà Nẵng": ("da nang", "danang"),
    "TP. Hồ Chí Minh": ("ho chi minh", "hcm", "sai gon", "saigon"),
    "Quảng Ninh": ("quang ninh", "ha long", "halong"),
    "Lào Cai": ("lao cai", "sa pa", "sapa"),
    "Thừa Thiên Huế": ("thua thien hue", "hue"),
    "Quảng Nam": ("quang nam", "hoi an"),
    "Khánh Hòa": ("khanh hoa", "nha trang"),
    "Lâm Đồng": ("lam dong", "da lat"),
    "Kiên Giang": ("kien giang", "phu quoc"),
}


def _get_json(url: str, params: Dict[str, Any], retries: int = 3) -> Optional[Dict[str, Any]]:
    for attempt in range(retries):
        try:
            resp = client.get(url, params=params)
            if resp.status_code == 200:
                return resp.json()
        except Exception:
            pass
        time.sleep(1.2 * (attempt + 1))
    return None


def normalize(text: str) -> str:
    text = (text or "").replace("đ", "d").replace("Đ", "D")
    text = unicodedata.normalize("NFD", text)
    text = "".join(ch for ch in text if unicodedata.category(ch) != "Mn")
    text = text.lower()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def strip_html(text: str) -> str:
    return re.sub(r"<[^>]+>", "", text or "").strip()


def tokens_of(name: str) -> List[str]:
    stop = {"ha", "noi", "ho", "chi", "minh", "da", "nang", "city", "vietnam", "tp", "hcm"}
    all_tokens = [
        t
        for t in normalize(name).split()
        if (len(t) >= 3 or t.isdigit()) and t not in stop
    ]
    distinctive = [t for t in all_tokens if t not in GENERIC_TOKENS]
    return distinctive or all_tokens


def _city_matches(display_name: str, city: str) -> bool:
    normalized = normalize(display_name)
    aliases = CITY_ALIASES.get(city, (normalize(city),))
    return any(alias in normalized for alias in aliases)


def geocode(name: str, city: str, address: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """Ưu tiên địa chỉ cụ thể nếu có, sau đó tên POI; lọc đúng thành phố."""
    queries: List[str] = []
    if address:
        queries.append(address)
    queries.append(name)
    queries.append(f"{name}, {city}, Việt Nam")

    for query in queries:
        data = _get_json(
            NOMINATIM,
            {
                "q": query,
                "format": "jsonv2",
                "addressdetails": 1,
                "countrycodes": "vn",
                "limit": 6,
            },
            retries=2,
        )
        if not data:
            time.sleep(1.1)
            continue
        in_city = [row for row in data if _city_matches(row.get("display_name", ""), city)]
        pool = in_city or (data if address and query == address else [])
        if pool:
            best = pool[0]
            return {
                "lat": float(best["lat"]),
                "lng": float(best["lon"]),
                "display_name": best.get("display_name", ""),
                "osm_type": best.get("osm_type"),
                "osm_id": best.get("osm_id"),
            }
        time.sleep(1.1)
    return None


def wikidata_lookup(name: str) -> Optional[Dict[str, Any]]:
    search = _get_json(
        WIKIDATA_API,
        {
            "action": "wbsearchentities",
            "search": name,
            "language": "vi",
            "uselang": "vi",
            "format": "json",
            "limit": 5,
        },
        retries=2,
    )
    if not search:
        return None
    for hit in search.get("search", []):
        qid = hit.get("id")
        if not qid:
            continue
        ent = _get_json(
            WIKIDATA_API,
            {
                "action": "wbgetentities",
                "ids": qid,
                "props": "claims|descriptions|sitelinks|labels",
                "languages": "vi|en",
                "format": "json",
            },
            retries=2,
        )
        if not ent:
            continue
        entity = (ent.get("entities") or {}).get(qid) or {}
        claims = entity.get("claims") or {}
        label = (
            ((entity.get("labels") or {}).get("vi") or {}).get("value")
            or ((entity.get("labels") or {}).get("en") or {}).get("value")
            or hit.get("label")
            or ""
        )
        if normalize(label) != normalize(name) and normalize(name) not in normalize(label):
            continue

        image = None
        p18 = claims.get("P18") or []
        if p18:
            value = (((p18[0].get("mainsnak") or {}).get("datavalue") or {}).get("value"))
            if isinstance(value, str):
                image = f"File:{value}"

        lat = lng = None
        p625 = claims.get("P625") or []
        if p625:
            value = (((p625[0].get("mainsnak") or {}).get("datavalue") or {}).get("value")) or {}
            if "latitude" in value and "longitude" in value:
                lat, lng = float(value["latitude"]), float(value["longitude"])

        sitelinks = entity.get("sitelinks") or {}
        vi_title = ((sitelinks.get("viwiki") or {}).get("title")) or None
        en_title = ((sitelinks.get("enwiki") or {}).get("title")) or None
        return {
            "qid": qid,
            "label": label,
            "image": image,
            "lat": lat,
            "lng": lng,
            "vi_title": vi_title,
            "en_title": en_title,
        }
    return None


def wikipedia_page(lang: str, title: Optional[str], name: str) -> Optional[Dict[str, Any]]:
    page_title = title
    if not page_title:
        search = _get_json(
            WIKI_API.format(lang=lang),
            {
                "action": "query",
                "list": "search",
                "srsearch": name,
                "format": "json",
                "srlimit": 3,
            },
            retries=2,
        )
        hits = (search or {}).get("query", {}).get("search", [])
        if hits:
            page_title = hits[0]["title"]
    if not page_title:
        return None

    data = _get_json(
        WIKI_API.format(lang=lang),
        {
            "action": "query",
            "titles": page_title,
            "prop": "pageimages|extracts",
            "piprop": "name|thumbnail",
            "pithumbsize": 1200,
            "explaintext": 1,
            "exintro": 1,
            "exsentences": 3,
            "format": "json",
            "redirects": 1,
        },
        retries=2,
    )
    if not data:
        return None
    pages = (data.get("query") or {}).get("pages") or {}
    for page in pages.values():
        if "missing" in page:
            continue
        extract = (page.get("extract") or "").strip()
        file_title = page.get("pageimage")
        thumb = (page.get("thumbnail") or {}).get("source")
        return {
            "title": page.get("title"),
            "extract": extract,
            "image": f"File:{file_title}" if file_title else None,
            "thumb": thumb,
        }
    return None


def _in_bbox(lat: float, lng: float, city: str) -> bool:
    box = CITY_BBOX.get(city)
    if not box:
        return True
    min_lat, max_lat, min_lng, max_lng = box
    return min_lat <= lat <= max_lat and min_lng <= lng <= max_lng


def image_context_ok(item: Dict[str, Any], file_title: str) -> bool:
    """Ảnh tìm trên Commons phải khớp cả ngữ cảnh loại hình lẫn tên riêng."""
    title = normalize(file_title.replace("File:", " "))
    typ = item.get("type")
    if typ in ("restaurant", "cafe"):
        contexts = ("quan", "nha hang", "restaurant", "cafe", "coffee", "ca phe",
                    "banh mi", "pho", "bun", "che", "kem", "lau", "nuong")
        if not any(word in title for word in contexts):
            return False
    elif typ == "hotel":
        if not any(word in title for word in ("hotel", "khach san", "resort")):
            return False
    return all(
        re.search(r"\b" + re.escape(token) + r"\b", title)
        for token in tokens_of(item["name"])
    )


def is_bad_file(file_title: str) -> bool:
    normalized = normalize(file_title.replace("File:", " "))
    if any(bad in normalized for bad in BAD_FILE_TOKENS):
        return True
    return not normalized.endswith(("jpg", "jpeg", "png", "webp"))


def commons_image_info(file_title: str) -> Optional[Dict[str, Any]]:
    if not file_title or is_bad_file(file_title):
        return None
    data = _get_json(
        COMMONS_API,
        {
            "action": "query",
            "titles": file_title,
            "prop": "imageinfo",
            "iiprop": "url|extmetadata",
            "iiurlwidth": 1200,
            "format": "json",
        },
        retries=2,
    )
    if not data:
        return None
    pages = (data.get("query") or {}).get("pages") or {}
    for page in pages.values():
        info = (page.get("imageinfo") or [{}])[0]
        if not info:
            return None
        meta = info.get("extmetadata") or {}
        license_name = ((meta.get("LicenseShortName") or {}).get("value")) or ""
        artist = strip_html(((meta.get("Artist") or {}).get("value")) or "")
        credit = strip_html(((meta.get("Credit") or {}).get("value")) or "")
        description_url = info.get("descriptionurl") or ""
        thumb = info.get("thumburl") or info.get("url")
        return {
            "file": page.get("title"),
            "url": info.get("url"),
            "thumb_url": thumb,
            "license": license_name,
            "author": artist or credit,
            "source_url": description_url,
        }
    return None


def commons_search(item: Dict[str, Any], city: str) -> Optional[Dict[str, Any]]:
    name = item["name"]
    wanted = tokens_of(name)
    if not wanted:
        return None
    candidates: List[Tuple[int, Dict[str, Any]]] = []
    for query in (f"{name} {city}", name):
        data = _get_json(
            COMMONS_API,
            {
                "action": "query",
                "generator": "search",
                "gsrsearch": query,
                "gsrnamespace": 6,
                "gsrlimit": 10,
                "prop": "imageinfo",
                "iiprop": "url|extmetadata",
                "iiurlwidth": 1200,
                "format": "json",
            },
            retries=2,
        )
        if not data:
            continue
        pages = (data.get("query") or {}).get("pages") or {}
        for page in pages.values():
            title = page.get("title") or ""
            normalized_title = normalize(title)
            if any(bad in normalized_title for bad in BAD_FILE_TOKENS):
                continue
            if not normalized_title.endswith(("jpg", "jpeg", "png", "webp")):
                continue
            if not image_context_ok(item, title):
                continue
            info = (page.get("imageinfo") or [{}])[0]
            if not info:
                continue
            hits = sum(1 for token in wanted if token in normalized_title)
            if hits == 0:
                continue
            score = hits * 10 + (5 if all(t in normalized_title for t in wanted) else 0)
            meta = info.get("extmetadata") or {}
            candidates.append(
                (
                    score,
                    {
                        "file": title,
                        "url": info.get("url"),
                        "thumb_url": info.get("thumburl") or info.get("url"),
                        "license": ((meta.get("LicenseShortName") or {}).get("value")) or "",
                        "author": strip_html(((meta.get("Artist") or {}).get("value")) or ""),
                        "source_url": info.get("descriptionurl") or "",
                    },
                )
            )
        if candidates:
            break
        time.sleep(1.0)
    if not candidates:
        return None
    candidates.sort(key=lambda item: item[0], reverse=True)
    return candidates[0][1]


def thumb_400(image: Dict[str, Any]) -> str:
    """Trả URL thumbnail 1280px đã kiểm chứng tải được.

    Wikimedia hiện chỉ phục vụ tốt các kích thước đã có sẵn (1280px); các mức
    320/400/640/1024 có thể trả 400. Vì vậy dùng 1280px và bỏ query tracking.
    """
    url = (image.get("thumb_url") or "").split("?")[0]
    return url.replace("/400px-", "/1280px-")


def wikipedia_exact(lang: str, title: str) -> Optional[Dict[str, Any]]:
    """Lấy đúng trang Wikipedia theo tiêu đề (không qua tìm kiếm mờ)."""
    data = _get_json(
        WIKI_API.format(lang=lang),
        {
            "action": "query",
            "titles": title,
            "prop": "pageimages|extracts|pageprops",
            "piprop": "name|thumbnail",
            "pithumbsize": 1200,
            "explaintext": 1,
            "exintro": 1,
            "exsentences": 3,
            "format": "json",
            "redirects": 1,
        },
        retries=2,
    )
    if not data:
        return None
    pages = (data.get("query") or {}).get("pages") or {}
    for page in pages.values():
        if "missing" in page:
            continue
        file_title = page.get("pageimage")
        return {
            "title": page.get("title"),
            "extract": (page.get("extract") or "").strip(),
            "image": f"File:{file_title}" if file_title else None,
            "thumb": (page.get("thumbnail") or {}).get("source"),
            "qid": ((page.get("pageprops") or {}).get("wikibase_item")),
        }
    return None


def is_relevant_title(title: str, name: str) -> bool:
    normalized = normalize(title)
    tokens = tokens_of(name)
    return bool(tokens) and all(
        re.search(r"\b" + re.escape(token) + r"\b", normalized) for token in tokens
    )


def build_record(item: Dict[str, Any]) -> Dict[str, Any]:
    name, city = item["name"], item["city"]
    geo = geocode(name, city, item.get("address"))
    if geo and not _in_bbox(geo["lat"], geo["lng"], city):
        geo = None
    wiki: Dict[str, Any] = {}
    if item.get("wiki"):
        wiki = (
            wikipedia_exact("vi", item["wiki"])
            or wikipedia_exact("en", item["wiki"])
            or {}
        )
    if not wiki:
        candidate = wikipedia_page("vi", None, name) or wikipedia_page("en", None, name)
        # Chỉ nhận trang Wikipedia nếu tiêu đề thật sự nói về địa điểm này.
        if candidate and is_relevant_title(candidate.get("title") or "", name):
            wiki = candidate

    wd: Dict[str, Any] = {}
    if not item.get("wiki"):
        wd = wikidata_lookup(name) or {}

    lat = item.get("lat")
    lng = item.get("lng")
    if lat is None:
        lat = geo["lat"] if geo else wd.get("lat")
    if lng is None:
        lng = geo["lng"] if geo else wd.get("lng")
    if lat is None or lng is None:
        lat, lng = wd.get("lat"), wd.get("lng")

    image = None
    if not item.get("no_image"):
        if item.get("image_file"):
            image = commons_image_info(item["image_file"])
        if not image and wiki.get("image"):
            candidate = commons_image_info(wiki["image"])
            if candidate:
                image = candidate
        if not image:
            # Trang Wikipedia có thể dùng ảnh bản đồ làm ảnh đại diện → thử Wikidata P18.
            if not wd:
                wd = wikidata_lookup(name) or {}
            if wd.get("image"):
                candidate = commons_image_info(wd["image"])
                if candidate and (
                    item.get("type") == "destination"
                    or image_context_ok(item, candidate["file"])
                ):
                    image = candidate
        if not image:
            image = commons_search(item, city)

    description = (wiki.get("extract") or "").strip()
    if not description or not (is_relevant_title(wiki.get("title") or "", name) or item.get("wiki")):
        description = item.get("note", "") or ""
    if len(description) > 420:
        description = description[:417].rsplit(" ", 1)[0] + "..."

    record = {
        **item,
        "lat": round(float(lat), 6) if lat is not None else None,
        "lng": round(float(lng), 6) if lng is not None else None,
        "address": item.get("address") or (geo or {}).get("display_name", ""),
        "address_osm": (geo or {}).get("display_name", ""),
        "wikidata": wd.get("qid") or wiki.get("qid"),
        "wikipedia": wiki.get("title"),
        "description": description,
        "image": None,
        "photo_status": "missing",
    }
    if image and image.get("url"):
        record["image"] = {
            **image,
            "thumb_url": thumb_400(image),
        }
        record["photo_status"] = "ok"
    return record


SAMPLES = [
    {"name": "Hồ Hoàn Kiếm", "city": "Hà Nội", "province_code": "HN", "type": "destination",
     "wiki": "Hồ Hoàn Kiếm"},
    {"name": "Văn Miếu Quốc Tử Giám", "city": "Hà Nội", "province_code": "HN", "type": "destination",
     "wiki": "Văn Miếu – Quốc Tử Giám"},
    {"name": "Chùa Một Cột", "city": "Hà Nội", "province_code": "HN", "type": "destination",
     "wiki": "Chùa Một Cột"},
    {"name": "Bún chả Hương Liên", "city": "Hà Nội", "province_code": "HN", "type": "restaurant",
     "address": "24 Lê Văn Hưu, Hai Bà Trưng, Hà Nội",
     "note": "Quán bún chả nổi tiếng từng đón Tổng thống Barack Obama và đầu bếp Anthony Bourdain năm 2016."},
    {"name": "Sofitel Legend Metropole Hanoi", "city": "Hà Nội", "province_code": "HN", "type": "hotel",
     "wiki": "Khách sạn Sofitel Metropole"},
    {"name": "Cà phê Giảng", "city": "Hà Nội", "province_code": "HN", "type": "cafe",
     "wiki": "Cà phê Giảng"},
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=".tmp/research.json")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--city", default="")
    parser.add_argument("--types", default="")
    parser.add_argument("--keys", default="")
    args = parser.parse_args()

    items = list(ALL_ITEMS)
    if args.city:
        items = [item for item in items if item["city"] == args.city]
    if args.types:
        wanted = {t.strip() for t in args.types.split(",")}
        items = [item for item in items if item.get("type") in wanted]
    if args.keys:
        wanted_keys = {k.strip() for k in args.keys.split(",")}
        items = [item for item in items if item.get("key") in wanted_keys]
    if args.limit:
        items = items[: args.limit]
    records = []
    for index, item in enumerate(items, start=1):
        print(f"[{index}/{len(items)}] {item['name']} ...", flush=True)
        try:
            record = build_record(item)
        except Exception as exc:  # pragma: no cover - network
            record = {**item, "error": f"{type(exc).__name__}: {exc}", "photo_status": "error"}
        records.append(record)
        print(
            f"    coords={record.get('lat')},{record.get('lng')} "
            f"photo={record.get('photo_status')} "
            f"license={((record.get('image') or {}).get('license'))}",
            flush=True,
        )
        time.sleep(1.1)

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved {len(records)} records -> {out}")


if __name__ == "__main__":
    main()
