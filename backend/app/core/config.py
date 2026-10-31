import os
from pydantic import BaseModel


class Settings(BaseModel):
    """Cấu hình trung tâm cho hệ thống TripFlow Backend API (Tối ưu hóa kiến trúc)."""

    PROJECT_NAME: str = os.getenv("PROJECT_NAME", "TripFlow - Vietnam Travel Discovery API")
    VERSION: str = "2.0.0"
    API_V1_STR: str = os.getenv("API_V1_STR", "/api/v1")

    # Bảo mật JWT & RBAC (Role & Permission)
    SECRET_KEY: str = os.getenv(
        "SECRET_KEY",
        "tripflow_super_secret_jwt_key_change_in_production_2026",
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))

    # Kết nối Database: PostgreSQL 15 thuần (B-Tree Index lat,lng) hoặc SQLite Fallback
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./tripflow.db")

    # Tích hợp Goong Maps (goong.io) thay thế Google Maps
    GOONG_API_KEY: str = os.getenv("GOONG_API_KEY", "")
    GOONG_MAPTILES_KEY: str = os.getenv("GOONG_MAPTILES_KEY", "")
    GOONG_BASE_URL: str = os.getenv("GOONG_BASE_URL", "https://rsapi.goong.io")
    MAPS_PROVIDER: str = os.getenv("MAPS_PROVIDER", "goong_maps")
    MAPS_DAILY_BUDGET_LIMIT: int = int(os.getenv("MAPS_DAILY_BUDGET_LIMIT", "500"))

    # Tích hợp Cloudinary CDN tối ưu hình ảnh (w_400,h_300 & w_1200,q_auto,f_auto)
    CLOUDINARY_CLOUD_NAME: str = os.getenv("CLOUDINARY_CLOUD_NAME", "demo")
    CLOUDINARY_API_KEY: str = os.getenv("CLOUDINARY_API_KEY", "")
    CLOUDINARY_API_SECRET: str = os.getenv("CLOUDINARY_API_SECRET", "")

    # Giới hạn nghiệp vụ & Rate Limiting (slowapi)
    CORRIDOR_RATE_LIMIT: str = os.getenv("CORRIDOR_RATE_LIMIT", "10/minute")
    DEFAULT_CORRIDOR_RADIUS_KM: float = float(os.getenv("DEFAULT_CORRIDOR_RADIUS_KM", "2.0"))
    MAX_CORRIDOR_RADIUS_KM: float = float(os.getenv("MAX_CORRIDOR_RADIUS_KM", "10.0"))
    MAX_ITINERARY_STOPS: int = int(os.getenv("MAX_ITINERARY_STOPS", "20"))


settings = Settings()
