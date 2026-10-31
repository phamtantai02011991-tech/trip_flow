from sqlalchemy.orm import sessionmaker
from sqlmodel import Session, SQLModel, create_engine

from app.core.config import settings

is_sqlite = settings.DATABASE_URL.startswith("sqlite")
connect_args = {"check_same_thread": False} if is_sqlite else {}

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True,
)

# Sử dụng SQLModel Session để tương thích cả câu lệnh select(Model) lẫn db.query(Model)
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    class_=Session,
)

# Alias Base = SQLModel để đồng bộ metadata
Base = SQLModel


def get_db():
    """Dependency cung cấp SQLModel Session cho mỗi HTTP request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
