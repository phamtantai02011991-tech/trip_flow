from datetime import datetime
from typing import Any, Dict, List, Optional
from sqlmodel import Field, SQLModel


# ============================================================================
# 1. AUTH, USER, ROLE & PERMISSION SCHEMAS (SQLModel)
# ============================================================================

class PermissionOut(SQLModel):
    id: int
    code: str
    name: str
    module: str
    description: Optional[str] = ""


class RoleOut(SQLModel):
    id: int
    code: str
    name: str
    description: Optional[str] = ""
    permissions: List[str] = []


class LoginRequest(SQLModel):
    email: str
    password: str


class RegisterRequest(SQLModel):
    email: str
    full_name: str
    password: str


class UserOut(SQLModel):
    id: int
    email: str
    full_name: str
    role: str
    role_id: Optional[int] = None
    assigned_province_id: Optional[int] = None
    is_active: bool
    permissions: List[str] = []
    created_at: Optional[datetime] = None


class UserRoleUpdate(SQLModel):
    role: str
    assigned_province_id: Optional[int] = None
    is_active: Optional[bool] = None


class TokenResponse(SQLModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


# ============================================================================
# 2. PROVINCE & CATEGORY SCHEMAS (SQLModel)
# ============================================================================

class CategoryOut(SQLModel):
    id: int
    code: str
    name: str
    icon_name: Optional[str] = "place"
    description: Optional[str] = None


class ProvinceBase(SQLModel):
    code: str
    name: str
    region: str
    description: Optional[str] = None
    hero_image: Optional[str] = None
    center_lat: float = 10.7769
    center_lng: float = 106.7009
    is_active: bool = True
    data_source: str = "internal"


class ProvinceCreate(ProvinceBase):
    pass


class ProvinceUpdate(SQLModel):
    code: Optional[str] = None
    name: Optional[str] = None
    region: Optional[str] = None
    description: Optional[str] = None
    hero_image: Optional[str] = None
    center_lat: Optional[float] = None
    center_lng: Optional[float] = None
    is_active: Optional[bool] = None
    data_source: Optional[str] = None


class ProvinceOut(ProvinceBase):
    id: int
    updated_at: Optional[datetime] = None
    destination_count: int = 0
    food_count: int = 0
    restaurant_count: int = 0


class RegionSummaryOut(SQLModel):
    region: str
    province_count: int = 0
    destination_count: int = 0
    food_count: int = 0
    restaurant_count: int = 0
    provinces: List[str] = []


# ============================================================================
# 3. DESTINATION & CLOUDINARY SCHEMAS (SQLModel)
# ============================================================================

class DestinationImageIn(SQLModel):
    image_url: str
    thumbnail_url: Optional[str] = None
    caption: Optional[str] = None
    sort_order: int = 1
    license_type: str = "owned"
    credit_author: str = "TripFlow Studio"


class DestinationImageOut(DestinationImageIn):
    id: int
    destination_id: int


class DestinationBase(SQLModel):
    province_id: int
    category_id: Optional[int] = 1
    name: str
    slug: Optional[str] = None
    description: str
    address: str
    latitude: float
    longitude: float
    opening_hours: str = "07:30 - 17:30"
    ticket_price_info: str = "Miễn phí"
    rating: float = 4.7
    review_count: int = 100
    recommended_duration_mins: int = 90
    thumbnail_url: Optional[str] = None
    detail_image_url: Optional[str] = None
    is_featured: bool = False
    is_sponsored: bool = False
    sponsor_label: Optional[str] = None
    is_verified: bool = False
    source: str = "admin"
    source_url: Optional[str] = None
    status: str = "published"
    data_source: str = "internal"
    source_attribution: str = "Ban Biên Tập TripFlow & Sở Du lịch TP.HCM"


class DestinationCreate(DestinationBase):
    images: Optional[List[DestinationImageIn]] = None


class DestinationUpdate(SQLModel):
    province_id: Optional[int] = None
    category_id: Optional[int] = None
    name: Optional[str] = None
    slug: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    opening_hours: Optional[str] = None
    ticket_price_info: Optional[str] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None
    recommended_duration_mins: Optional[int] = None
    thumbnail_url: Optional[str] = None
    detail_image_url: Optional[str] = None
    is_featured: Optional[bool] = None
    is_sponsored: Optional[bool] = None
    sponsor_label: Optional[str] = None
    is_verified: Optional[bool] = None
    source: Optional[str] = None
    source_url: Optional[str] = None
    status: Optional[str] = None
    data_source: Optional[str] = None
    source_attribution: Optional[str] = None
    images: Optional[List[DestinationImageIn]] = None


class DestinationOut(DestinationBase):
    id: int
    category_code: Optional[str] = None
    category_name: Optional[str] = None
    province_name: Optional[str] = None
    last_verified_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    images: List[DestinationImageOut] = []


class PaginatedDestinations(SQLModel):
    items: List[DestinationOut]
    total: int
    page: int
    page_size: int


# ============================================================================
# 4. LOCAL FOOD SCHEMAS (SQLModel)
# ============================================================================

class LocalFoodBase(SQLModel):
    province_id: int
    name: str
    description: str
    story_origin: Optional[str] = None
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    best_season_or_time: str = "Quanh năm"
    avg_price_range: str = "40.000đ - 85.000đ"
    recommended_restaurant_ids: List[int] = []
    status: str = "published"
    data_source: str = "internal"
    license_info: str = "Bản quyền nội dung TripFlow Editorial"


class LocalFoodCreate(LocalFoodBase):
    pass


class LocalFoodUpdate(SQLModel):
    province_id: Optional[int] = None
    name: Optional[str] = None
    description: Optional[str] = None
    story_origin: Optional[str] = None
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    best_season_or_time: Optional[str] = None
    avg_price_range: Optional[str] = None
    recommended_restaurant_ids: Optional[List[int]] = None
    status: Optional[str] = None
    data_source: Optional[str] = None
    license_info: Optional[str] = None


class LocalFoodOut(LocalFoodBase):
    id: int
    province_name: Optional[str] = None
    updated_at: Optional[datetime] = None
    recommended_restaurants: List[Dict[str, Any]] = []


# ============================================================================
# 5. RESTAURANT & CORRIDOR SEARCH SCHEMAS (Bounding Box + Shapely + Goong)
# ============================================================================

class ReviewItem(SQLModel):
    """Trích đoạn đánh giá chân thực từ thực khách Google Maps."""
    author: str = "Thực khách TripFlow"
    rating: float = 5.0
    text: str
    relative_time: str = "Gần đây"


class RestaurantBase(SQLModel):
    province_id: int
    name: str
    address: str
    latitude: float
    longitude: float
    cuisine_type: str = "Đặc sản Sài Gòn"
    specialty_dishes: Optional[str] = None
    price_range: str = "45.000đ - 120.000đ"
    opening_hours: str = "06:30 - 22:00"
    contact_phone: Optional[str] = None
    rating: float = 4.6
    review_count: int = 120
    reviews_count: int = 120
    is_high_rated: bool = True
    specialties: Optional[str] = None
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    is_sponsored: bool = False
    sponsor_label: Optional[str] = None
    is_verified: bool = False
    source: str = "admin"
    source_url: Optional[str] = None
    status: str = "published"
    data_source: str = "internal"


class RestaurantCreate(RestaurantBase):
    sample_reviews_json: Optional[str] = "[]"


class RestaurantUpdate(SQLModel):
    province_id: Optional[int] = None
    name: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    cuisine_type: Optional[str] = None
    specialty_dishes: Optional[str] = None
    specialties: Optional[str] = None
    price_range: Optional[str] = None
    opening_hours: Optional[str] = None
    contact_phone: Optional[str] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None
    reviews_count: Optional[int] = None
    is_high_rated: Optional[bool] = None
    sample_reviews_json: Optional[str] = None
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    is_sponsored: Optional[bool] = None
    sponsor_label: Optional[str] = None
    is_verified: Optional[bool] = None
    source: Optional[str] = None
    source_url: Optional[str] = None
    status: Optional[str] = None
    data_source: Optional[str] = None


class RestaurantOut(RestaurantBase):
    id: int
    province_name: Optional[str] = None
    sample_reviews: List[ReviewItem] = []
    last_updated_at: Optional[datetime] = None
    hours_verification_notice: str = (
        "Vui lòng kiểm tra lại giờ hoạt động thực tế trước khi di chuyển."
    )


class CorridorRestaurantOut(RestaurantOut):
    distance_from_route_km: float
    detour_distance_km: float
    estimated_detour_mins: int
    nearest_route_point_lat: float
    nearest_route_point_lng: float
    route_progress_pct: float
    corridor_score: float = 0.0


class SmartMealStopRequest(SQLModel):
    day_number: int = 1
    preferred_time: Optional[str] = "12:00"
    corridor_radius_km: float = 2.0
    cuisine_filter: Optional[str] = None


class SmartMealStopResponse(SQLModel):
    itinerary_id: int
    day_number: int
    inserted_stop: Dict[str, Any]
    recommended_restaurant: CorridorRestaurantOut
    smart_score: float
    reasoning: str


class WaypointCoord(SQLModel):
    lat: float
    lng: float


class BoundingBoxOut(SQLModel):
    min_lat: float
    max_lat: float
    min_lng: float
    max_lng: float


class RouteCorridorRequest(SQLModel):
    province_id: Optional[int] = 1
    origin_name: Optional[str] = "Điểm xuất phát"
    origin_lat: float
    origin_lng: float
    destination_name: Optional[str] = "Điểm đến"
    destination_lat: float
    destination_lng: float
    corridor_radius_km: float = Field(default=2.0, ge=0.2, le=10.0)
    cuisine_filter: Optional[str] = None
    waypoints: Optional[List[WaypointCoord]] = None


class RouteCorridorResponse(SQLModel):
    origin_name: str
    destination_name: str
    total_route_distance_km: float
    corridor_radius_km: float
    encoded_polyline: str = ""
    maps_provider: str = "goong_maps"
    bounding_box: Optional[BoundingBoxOut] = None
    candidates_in_bbox_count: int = 0
    shapely_engine_used: bool = True
    polyline: List[WaypointCoord]
    results_count: int
    restaurants: List[CorridorRestaurantOut]


# ============================================================================
# 6. ITINERARY & OFFLINE SYNC SCHEMAS (SQLModel)
# ============================================================================

class ItineraryStopIn(SQLModel):
    day_number: int = 1
    stop_order: int = 1
    stop_type: str = "destination"
    reference_id: Optional[int] = None
    title: str
    address: Optional[str] = None
    latitude: float = 10.7769
    longitude: float = 106.7009
    planned_time: str = "08:30 - 10:00"
    duration_mins: int = 90
    notes: Optional[str] = None


class ItineraryStopOut(ItineraryStopIn):
    id: int
    itinerary_id: int


class ItineraryCreate(SQLModel):
    province_id: int = 1
    title: str
    description: Optional[str] = None
    total_days: int = 1
    is_template: bool = False
    status: str = "active"
    stops: List[ItineraryStopIn] = []


class ItineraryUpdate(SQLModel):
    province_id: Optional[int] = None
    title: Optional[str] = None
    description: Optional[str] = None
    total_days: Optional[int] = None
    is_template: Optional[bool] = None
    status: Optional[str] = None
    stops: Optional[List[ItineraryStopIn]] = None


class ItinerarySyncRequest(SQLModel):
    local_id: Optional[int] = None
    server_id: Optional[int] = None
    province_id: int = 1
    title: str
    description: Optional[str] = None
    total_days: int = 1
    stops: List[ItineraryStopIn] = []


class ItineraryOut(SQLModel):
    id: int
    user_id: Optional[int] = None
    province_id: int
    province_name: Optional[str] = None
    title: str
    description: Optional[str] = None
    total_days: int
    is_template: bool
    status: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    stops: List[ItineraryStopOut] = []


# ============================================================================
# 7. FAVORITES, CONTENT REPORTS, CLOUDINARY UPLOAD & ADMIN AUDIT SCHEMAS
# ============================================================================

class FavoriteCreate(SQLModel):
    target_type: str
    target_id: int


class FavoriteOut(SQLModel):
    id: int
    user_id: int
    target_type: str
    target_id: int
    created_at: Optional[datetime] = None


class ContentReportCreate(SQLModel):
    target_type: str = "destination"
    target_id: int
    target_name: str
    issue_type: str = "wrong_hours"
    description: str
    rating: Optional[int] = 5


class ContentReportResolve(SQLModel):
    status: str
    moderator_note: Optional[str] = None


class ContentReportOut(SQLModel):
    id: int
    user_id: Optional[int] = None
    target_type: str
    target_id: int
    target_name: str
    issue_type: str
    description: str
    rating: Optional[int] = None
    status: str
    moderator_note: Optional[str] = None
    created_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None


class AuditLogOut(SQLModel):
    id: int
    actor_id: Optional[int] = None
    actor_email: str
    actor_role: str
    action: str
    entity_type: str
    entity_id: Optional[int] = None
    summary: str
    changes_json: Optional[str] = "{}"
    created_at: Optional[datetime] = None


class CloudinaryUploadRequest(SQLModel):
    image_url: Optional[str] = None
    filename: Optional[str] = "tripflow_upload.jpg"
    folder: str = "tripflow/destinations"


class CloudinaryUploadResponse(SQLModel):
    provider: str = "cloudinary"
    public_id: str
    original_url: str
    thumbnail_url: str
    detail_url: str
    transformations: Dict[str, str]


class AdminDashboardStats(SQLModel):
    total_provinces: int
    total_destinations: int
    total_local_foods: int
    total_restaurants: int
    total_templates: int
    total_users: int
    pending_reports: int
    sponsored_items_count: int
    data_source_breakdown: Dict[str, int]
    maps_api_quota: Dict[str, Any]
    recent_audit_logs: List[AuditLogOut]


# ============================================================================
# 8. AI DATA INGESTION & GOOGLE MAPS CRAWLER SCHEMAS
# ============================================================================

class CrawlTriggerRequest(SQLModel):
    keyword: str = "quán ăn ngon"
    lat: float = 10.762622
    lng: float = 106.660172
    province_id: int = 1


CrawlRequest = CrawlTriggerRequest


class CrawlTriggerResponse(SQLModel):
    job_id: int
    status: str = "PENDING"
    keyword: str
    lat: float
    lng: float
    message: str = "Đã tạo tiến trình cào dữ liệu ngầm thành công."


class CrawlJobOut(SQLModel):
    id: int
    job_id: int
    keyword: str
    lat: float
    lng: float
    status: str
    total_scraped: int = 0
    inserted_count: int = 0
    duplicate_count: int = 0
    error_message: Optional[str] = None
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

