"""Smoke test API TripFlow sau khi deploy.

Chạy:
    python tools/smoke_test.py --base-url https://api.tripflow.vn
    python tools/smoke_test.py --base-url http://127.0.0.1:8128

Trả mã 0 nếu tất cả PASS, 1 nếu có mục FAIL.
"""

from __future__ import annotations

import argparse
import sys
from typing import Any, Callable, List, Tuple

import httpx


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="http://127.0.0.1:8128")
    parser.add_argument("--timeout", type=float, default=20.0)
    args = parser.parse_args()

    base = args.base_url.rstrip("/")
    client = httpx.Client(base_url=base, timeout=args.timeout)
    results: List[Tuple[str, bool, str]] = []

    def check(name: str, fn: Callable[[], str]) -> None:
        try:
            detail = fn()
            results.append((name, True, detail))
        except Exception as exc:  # noqa: BLE001 - báo lỗi cho người vận hành
            results.append((name, False, f"{type(exc).__name__}: {exc}"))

    def get(path: str, **kwargs: Any) -> httpx.Response:
        resp = client.get(path, **kwargs)
        resp.raise_for_status()
        return resp

    def health() -> str:
        body = get("/health").json()
        assert body.get("status") in {"healthy", "ok"}, body
        return f"status={body.get('status')}"

    def ready() -> str:
        body = get("/health/ready").json()
        assert body.get("database") in {"ok", "healthy"}, body
        return f"database={body.get('database')}"

    def destinations() -> str:
        body = get("/api/v1/destinations", params={"page_size": 100}).json()
        assert body["total"] >= 100, body["total"]
        assert len(body["items"]) > 0
        return f"total={body['total']}"

    def restaurants() -> str:
        body = get("/api/v1/restaurants", params={"page_size": 100}).json()
        count = len(body) if isinstance(body, list) else body.get("total", 0)
        assert count >= 60, count
        return f"count={count}"

    def nearby_gas() -> str:
        body = get(
            "/api/v1/places/nearby",
            params={
                "lat": 21.0288,
                "lng": 105.8525,
                "radius_km": 6,
                "kinds": "gas",
            },
        ).json()
        assert body["total"] >= 1, body
        return f"gas={body['total']}"

    def along_route() -> str:
        resp = client.post(
            "/api/v1/places/along-route",
            json={
                "origin_lat": 21.0288,
                "origin_lng": 105.8525,
                "dest_lat": 21.0288,
                "dest_lng": 105.8359,
                "corridor_radius_km": 2.0,
                "kinds": "rest,gas,ev,cafe",
            },
        )
        resp.raise_for_status()
        body = resp.json()
        assert body["count"] >= 1, body
        return f"stops={body['count']}"

    def suggest() -> str:
        body = get("/api/v1/places/suggest", params={"q": "hoi an"}).json()
        assert isinstance(body, list) and len(body) >= 1, body
        return f"items={len(body)}"

    check("GET /health", health)
    check("GET /health/ready", ready)
    check("GET /destinations (>=100)", destinations)
    check("GET /restaurants (>=60)", restaurants)
    check("GET /places/nearby?kinds=gas", nearby_gas)
    check("POST /places/along-route", along_route)
    check("GET /places/suggest?q=hoi an", suggest)

    failed = 0
    for name, ok, detail in results:
        icon = "PASS" if ok else "FAIL"
        print(f"[{icon}] {name} — {detail}")
        if not ok:
            failed += 1

    print(f"\n{len(results) - failed}/{len(results)} mục PASS")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
