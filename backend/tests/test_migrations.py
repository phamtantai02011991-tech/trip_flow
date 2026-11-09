"""Kiểm tra Alembic baseline tạo đủ schema (chạy trên SQLite tạm)."""

from __future__ import annotations

import os
from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

BACKEND_DIR = Path(__file__).resolve().parents[1]


def test_alembic_baseline_creates_full_schema(tmp_path):
    db_path = tmp_path / "migration_test.db"
    url = f"sqlite:///{db_path.as_posix()}"
    os.environ["ALEMBIC_DATABASE_URL"] = url
    try:
        cfg = Config(str(BACKEND_DIR / "alembic.ini"))
        cfg.set_main_option("script_location", str(BACKEND_DIR / "alembic"))
        cfg.set_main_option("sqlalchemy.url", url)
        command.upgrade(cfg, "head")
    finally:
        os.environ.pop("ALEMBIC_DATABASE_URL", None)

    engine = create_engine(url)
    tables = set(inspect(engine).get_table_names())
    engine.dispose()

    expected = {
        "users",
        "destinations",
        "restaurants",
        "rest_stops",
        "local_foods",
        "itineraries",
        "itinerary_stops",
        "trips",
        "trip_days",
        "trip_stops",
        "expenses",
        "favorites",
        "place_reviews",
        "content_reports",
        "search_history",
        "sms_otp_verifications",
        "alembic_version",
    }
    assert expected <= tables, expected - tables
