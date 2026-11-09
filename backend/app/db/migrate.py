"""Chạy migration Alembic khi container khởi động.

- DB trống: `alembic upgrade head`.
- DB cũ do `create_all` tạo (chưa có alembic_version): stamp baseline rồi upgrade.
- DB đã có alembic_version: upgrade bình thường.
"""

from __future__ import annotations

import logging

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

from app.core.config import settings

logger = logging.getLogger("tripflow.migrate")


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    cfg = Config("alembic.ini")
    cfg.set_main_option("sqlalchemy.url", settings.DATABASE_URL.replace("%", "%%"))

    engine = create_engine(settings.DATABASE_URL)
    tables = set(inspect(engine).get_table_names())
    engine.dispose()

    if "alembic_version" not in tables and tables:
        logger.info("DB cũ không có alembic_version — stamp baseline head.")
        command.stamp(cfg, "head")
        return

    logger.info("Chạy alembic upgrade head.")
    command.upgrade(cfg, "head")


if __name__ == "__main__":
    main()
