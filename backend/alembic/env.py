"""Alembic environment cho TripFlow.

Ưu tiên `ALEMBIC_DATABASE_URL` (dùng trong test/CI), sau đó `DATABASE_URL`,
cuối cùng là URL trong alembic.ini.
"""

from __future__ import annotations

import os
import sys
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool
from sqlmodel import SQLModel

# Đảm bảo import được package `app` khi chạy `alembic` từ backend/.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings  # noqa: E402
import app.db.seed_db  # noqa: E402,F401  (nạp model lõi vào metadata)
import app.models  # noqa: E402,F401
import app.models.place  # noqa: E402,F401
import app.models.review  # noqa: E402,F401
import app.models.trip  # noqa: E402,F401

config = context.config

if config.config_file_name is not None and config.config_file_name.endswith(".ini"):
    try:
        fileConfig(config.config_file_name)
    except Exception:
        pass

database_url = os.getenv("ALEMBIC_DATABASE_URL") or settings.DATABASE_URL
config.set_main_option("sqlalchemy.url", database_url.replace("%", "%%"))

target_metadata = SQLModel.metadata


def run_migrations_offline() -> None:
    context.configure(
        url=config.get_main_option("sqlalchemy.url"),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
