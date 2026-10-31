from fastapi import APIRouter

from app.api.v1.endpoints import (
    admin,
    admin_crawler,
    auth,
    destinations,
    favorites,
    itineraries,
    local_foods,
    provinces,
    restaurants,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["1. Xác thực & Hồ sơ (Auth)"])
api_router.include_router(provinces.router, prefix="/provinces", tags=["2. Tỉnh / Thành phố (Provinces)"])
api_router.include_router(destinations.router, prefix="/destinations", tags=["3. Địa điểm du lịch (Destinations)"])
api_router.include_router(local_foods.router, prefix="/local-foods", tags=["4. Đặc sản & Món ăn (Local Foods)"])
api_router.include_router(restaurants.router, prefix="/restaurants", tags=["5. Nhà hàng & Tìm dọc lộ trình (Restaurants & Corridor)"])
api_router.include_router(itineraries.router, prefix="/itineraries", tags=["6. Lịch trình tham quan (Itineraries)"])
api_router.include_router(favorites.router, prefix="/favorites", tags=["7. Danh sách Yêu thích (Favorites)"])
api_router.include_router(admin.router, prefix="/admin", tags=["8. Quản trị Hệ thống (Admin & RBAC)"])
api_router.include_router(admin_crawler.router, prefix="/admin", tags=["9. AI Data Ingestion & Google Maps Crawler (Admin)"])
