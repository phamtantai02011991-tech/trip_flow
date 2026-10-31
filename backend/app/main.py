import json
from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.rate_limit import (
    SLOWAPI_AVAILABLE,
    RateLimitExceeded,
    custom_rate_limit_exceeded_handler,
    limiter,
)
from app.db.seed_db import init_and_seed_db


def _export_openapi_contract(fastapi_app: FastAPI) -> None:
    """Tự động xuất hợp đồng API ra file `backend/swagger.json` (Pitfall #4)."""
    try:
        swagger_path = Path(__file__).resolve().parent.parent / "swagger.json"
        schema = fastapi_app.openapi()
        swagger_path.write_text(
            json.dumps(schema, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
    except Exception:
        pass


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Khởi tạo cơ sở dữ liệu SQLModel, nạp dữ liệu mẫu và xuất swagger.json."""
    init_and_seed_db()
    _export_openapi_contract(app)
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description=(
        "Backend RESTful API cho hệ thống **TripFlow (Travel Discovery)** — "
        "Kiến trúc tối ưu sử dụng **SQLModel**, **PostgreSQL 15 thuần (B-Tree Index lat,lng)**, "
        "**Goong Maps API**, **Cloudinary CDN**, **Bounding Box + Shapely Corridor Search**, "
        "phân quyền **RBAC (Role & Permission)** và **Rate Limiting (slowapi 10/minute)**."
    ),
    lifespan=lifespan,
)

app.state.limiter = limiter
if SLOWAPI_AVAILABLE:
    app.add_exception_handler(RateLimitExceeded, custom_rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/", tags=["Root & Health"])
def root():
    return {
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "docs_url": "/docs",
        "swagger_contract_url": f"{settings.API_V1_STR}/contract/swagger.json",
        "api_prefix": settings.API_V1_STR,
        "default_province": "TP. Hồ Chí Minh (HCM)",
        "architecture": {
            "orm": "SQLModel",
            "database": "PostgreSQL 15 B-Tree Index (lat, lng)",
            "maps": "Goong Maps (goong.io)",
            "corridor_engine": "Bounding Box SQL + Shapely (LineString, Point)",
            "image_cdn": "Cloudinary (w_400,h_300 & w_1200,q_auto,f_auto)",
            "rate_limiter": "slowapi (10/minute)",
        },
    }


@app.get("/health", tags=["Root & Health"])
def health_check():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
    }


@app.get(f"{settings.API_V1_STR}/contract/swagger.json", tags=["API Contract"])
def get_swagger_contract():
    """Trả về hợp đồng OpenAPI 3.1 (swagger.json) để đồng bộ schema giữa Backend, Flutter và Admin Web."""
    return app.openapi()
