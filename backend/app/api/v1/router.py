from fastapi import APIRouter

from app.api.v1.endpoints import (
    admin,
    admin_crawler,
    assistant,
    auth,
    destinations,
    expenses,
    favorites,
    itineraries,
    local_foods,
    maps,
    places,
    provinces,
    restaurants,
    reviews,
    trips,
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
api_router.include_router(trips.router, prefix="/trips", tags=["10. Chuyến đi & AI lập lộ trình (Trips & AI Planner)"])
api_router.include_router(expenses.router, prefix="/trips", tags=["11. Chi phí chuyến đi (Expenses)"])
api_router.include_router(places.router, prefix="/places", tags=["12. Tìm quanh đây & Lịch sử tìm kiếm (Nearby & Search)"])
api_router.include_router(assistant.router, prefix="/assistant", tags=["13. Trợ lý du lịch AI (AI Assistant)"])
api_router.include_router(maps.router, prefix="/maps", tags=["14. Chỉ đường thật (Routing)"])
api_router.include_router(reviews.router, prefix="/reviews", tags=["15. Đánh giá của người dùng (Reviews)"])
