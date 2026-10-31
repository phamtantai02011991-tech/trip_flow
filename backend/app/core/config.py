import os
from pathlib import Path

from pydantic import BaseModel


def _load_dotenv() -> None:
    """Nạp backend/.env vào os.environ mà không cần thêm dependency.

    `os.getenv` chỉ thấy biến môi trường thật; trước đây file .env bị bỏ qua hoàn
    toàn nên mọi key (Gemini/Goong/Cloudinary) đều rơi về giá trị mặc định.
    Biến đã có sẵn trong môi trường luôn được ưu tiên hơn .env.
    """
    candidates = [Path(__file__).resolve().parents[2] / ".env", Path(".env")]
    for path in candidates:
        if not path.is_file():
            continue
        for raw in path.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value
        return


_load_dotenv()


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

    # ---------- Gemini (Module 2 & 4) ----------
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_API_BASE: str = os.getenv(
        "GEMINI_API_BASE", "https://generativelanguage.googleapis.com/v1beta"
    )
    # Để trống = tự chọn model đầu tiên hỗ trợ generateContent qua GET /models
    GEMINI_MODEL_PLANNER: str = os.getenv("GEMINI_MODEL_PLANNER", "")
    GEMINI_MODEL_CHAT: str = os.getenv("GEMINI_MODEL_CHAT", "")
    GEMINI_TIMEOUT_SECONDS: float = float(os.getenv("GEMINI_TIMEOUT_SECONDS", "60"))
    GEMINI_MAX_OUTPUT_TOKENS: int = int(os.getenv("GEMINI_MAX_OUTPUT_TOKENS_PLANNER", "8192"))
    GEMINI_PRICE_IN_PER_M: float = float(os.getenv("GEMINI_PRICE_IN_PER_M", "0.75"))
    GEMINI_PRICE_OUT_PER_M: float = float(os.getenv("GEMINI_PRICE_OUT_PER_M", "3.75"))

    # ---------- Bản đồ / cache ----------
    PLACES_CACHE_TTL_HOURS: int = int(os.getenv("PLACES_CACHE_TTL_HOURS", "24"))
    AI_PLANS_PER_DAY: int = int(os.getenv("AI_PLANS_PER_DAY", "5"))


settings = Settings()
