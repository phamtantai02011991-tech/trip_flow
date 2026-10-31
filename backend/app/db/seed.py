"""
Module tương thích ngược re-export `init_and_seed_db` từ `app.db.seed_db`.
"""

from app.db.seed_db import init_and_seed_db

__all__ = ["init_and_seed_db"]
