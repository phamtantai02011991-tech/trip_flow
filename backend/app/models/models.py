from datetime import datetime
from typing import List, Optional
from sqlalchemy import Column, Index, Text
from sqlmodel import Field, Relationship, SQLModel


# ============================================================================
# 1. PHÂN QUYỀN RBAC CHUẨN: BẢNG ROLES, PERMISSIONS & ROLE_PERMISSION_LINKS
#    (Pitfall #2 & Thay đổi cốt lõi #3: Dùng SQLModel)
# ============================================================================

class RolePermissionLink(SQLModel, table=True):
    """Bảng trung gian kết nối nhiều-nhiều giữa Role và Permission."""

    __tablename__ = "role_permission_links"

    role_id: Optional[int] = Field(
        default=None, foreign_key="roles.id", primary_key=True
    )
    permission_id: Optional[int] = Field(
        default=None, foreign_key="permissions.id", primary_key=True
    )


class Permission(SQLModel, table=True):
    """Bảng Quyền hạn chi tiết (VD: destination:write, restaurant:write, report:moderate...)."""

    __tablename__ = "permissions"

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(index=True, unique=True, max_length=80)
    name: str = Field(max_length=150)
    module: str = Field(default="general", max_length=60)
    description: Optional[str] = Field(default="", sa_column=Column(Text))

    roles: List["Role"] = Relationship(
        back_populates="permissions", link_model=RolePermissionLink
    )


class Role(SQLModel, table=True):
    """Bảng Vai trò hệ thống (super_admin, content_admin, province_editor, moderator, user)."""

    __tablename__ = "roles"

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(index=True, unique=True, max_length=50)
    name: str = Field(max_length=120)
    description: Optional[str] = Field(default="", sa_column=Column(Text))

    permissions: List[Permission] = Relationship(
        back_populates="roles", link_model=RolePermissionLink
    )
    users: List["User"] = Relationship(back_populates="role_obj")


class AdminRole(SQLModel, table=True):
    """Bảng tóm tắt Vai trò Quản trị (Tương thích ngược với giao diện Admin cũ)."""

    __tablename__ = "admin_roles"

    id: Optional[int] = Field(default=None, primary_key=True)
    role_code: str = Field(index=True, unique=True, max_length=50)
    role_name: str = Field(max_length=120)
    permissions_json: str = Field(default="[]", sa_column=Column(Text))
    description: Optional[str] = Field(default=None, sa_column=Column(Text))


# ============================================================================
# 2. TỈNH/THÀNH PHỐ & DANH MỤC ĐỊA ĐIỂM
# ============================================================================

class Province(SQLModel, table=True):
    """Bảng Tỉnh/Thành phố (HCM, DN, HN...)."""

    __tablename__ = "provinces"

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(index=True, unique=True, max_length=20)
    name: str = Field(max_length=120)
    region: str = Field(max_length=60)
    description: Optional[str] = Field(default=None, sa_column=Column(Text))
    hero_image: Optional[str] = Field(default=None, max_length=500)
    center_lat: float = Field(default=10.7769)
    center_lng: float = Field(default=106.7009)
    is_active: bool = Field(default=True)
    data_source: str = Field(default="internal", max_length=100)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    destinations: List["Destination"] = Relationship(
        back_populates="province",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )
    local_foods: List["LocalFood"] = Relationship(
        back_populates="province",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )
    restaurants: List["Restaurant"] = Relationship(
        back_populates="province",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )
    itineraries: List["Itinerary"] = Relationship(
        back_populates="province",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )


class Category(SQLModel, table=True):
    """Bảng Danh mục địa điểm du lịch."""

    __tablename__ = "categories"

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(index=True, unique=True, max_length=50)
    name: str = Field(max_length=120)
    icon_name: str = Field(default="place", max_length=60)
    description: Optional[str] = Field(default=None, sa_column=Column(Text))

    destinations: List["Destination"] = Relationship(back_populates="category")


# ============================================================================
# 3. ĐỊA ĐIỂM DU LỊCH & HÌNH ẢNH CLOUDINARY (Thay đổi #1, #3, #5)
#    Đánh B-Tree Composite Index trên (latitude, longitude) thay vì dùng PostGIS
# ============================================================================

class Destination(SQLModel, table=True):
    """Bảng Địa điểm du lịch có B-Tree Composite Index (latitude, longitude) và URL Cloudinary."""

    __tablename__ = "destinations"
    __table_args__ = (
        Index("ix_destinations_lat_lng", "latitude", "longitude"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    province_id: int = Field(foreign_key="provinces.id", index=True)
    category_id: Optional[int] = Field(default=1, foreign_key="categories.id", index=True)
    name: str = Field(index=True, max_length=200)
    slug: Optional[str] = Field(default=None, index=True, max_length=220)
    description: str = Field(sa_column=Column(Text, nullable=False))
    address: str = Field(max_length=350)
    latitude: float = Field(index=True)
    longitude: float = Field(index=True)
    opening_hours: str = Field(default="07:30 - 17:30", max_length=180)
    ticket_price_info: str = Field(default="Miễn phí", max_length=200)
    rating: float = Field(default=4.7)
    review_count: int = Field(default=120)
    recommended_duration_mins: int = Field(default=90)
    thumbnail_url: Optional[str] = Field(default=None, max_length=550)
    detail_image_url: Optional[str] = Field(default=None, max_length=550)
    is_featured: bool = Field(default=False)
    is_sponsored: bool = Field(default=False)
    sponsor_label: Optional[str] = Field(default=None, max_length=150)
    is_verified: bool = Field(default=False, index=True)
    source: str = Field(default="admin", index=True, max_length=60)
    source_url: Optional[str] = Field(default=None, max_length=550)
    status: str = Field(default="published", index=True, max_length=30)
    data_source: str = Field(default="internal", max_length=60)
    source_attribution: str = Field(
        default="Ban Biên Tập TripFlow & Sở Du lịch TP.HCM", max_length=300
    )
    last_verified_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    province: Optional[Province] = Relationship(back_populates="destinations")
    category: Optional[Category] = Relationship(back_populates="destinations")
    images: List["DestinationImage"] = Relationship(
        back_populates="destination",
        sa_relationship_kwargs={
            "cascade": "all, delete-orphan",
            "order_by": "DestinationImage.sort_order",
        },
    )


class DestinationImage(SQLModel, table=True):
    """Bảng Hình ảnh địa điểm lưu URL nhẹ từ Cloudinary CDN kèm giấy phép sử dụng."""

    __tablename__ = "destination_images"

    id: Optional[int] = Field(default=None, primary_key=True)
    destination_id: int = Field(foreign_key="destinations.id", index=True)
    image_url: str = Field(max_length=550)
    thumbnail_url: Optional[str] = Field(default=None, max_length=550)
    caption: Optional[str] = Field(default=None, max_length=250)
    sort_order: int = Field(default=1)
    license_type: str = Field(default="owned", max_length=80)
    credit_author: str = Field(default="TripFlow Studio", max_length=200)

    destination: Optional[Destination] = Relationship(back_populates="images")


# ============================================================================
# 4. ĐẶC SẢN ĐỊA PHƯƠNG & NHÀ HÀNG (B-Tree Index lat,lng phục vụ Bounding Box)
# ============================================================================

class LocalFood(SQLModel, table=True):
    """Bảng Món ăn / Đặc sản địa phương."""

    __tablename__ = "local_foods"

    id: Optional[int] = Field(default=None, primary_key=True)
    province_id: int = Field(foreign_key="provinces.id", index=True)
    name: str = Field(index=True, max_length=200)
    description: str = Field(sa_column=Column(Text, nullable=False))
    story_origin: Optional[str] = Field(default=None, sa_column=Column(Text))
    image_url: Optional[str] = Field(default=None, max_length=550)
    thumbnail_url: Optional[str] = Field(default=None, max_length=550)
    best_season_or_time: str = Field(
        default="Quanh năm (Ngon nhất vào buổi sáng hoặc tối)", max_length=180
    )
    avg_price_range: str = Field(default="40.000đ - 85.000đ", max_length=120)
    recommended_restaurant_ids_json: str = Field(
        default="[]", sa_column=Column(Text)
    )
    status: str = Field(default="published", index=True, max_length=30)
    data_source: str = Field(default="internal", max_length=60)
    license_info: str = Field(
        default="Bản quyền nội dung TripFlow Editorial", max_length=250
    )
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    province: Optional[Province] = Relationship(back_populates="local_foods")


class Restaurant(SQLModel, table=True):
    """
    Bảng Nhà hàng / Quán ăn.
    Có B-Tree Composite Index ix_restaurants_lat_lng trên (latitude, longitude)
    để truy vấn lọc vùng chữ nhật Bounding Box cực nhanh trước khi chạy Shapely.
    """

    __tablename__ = "restaurants"
    __table_args__ = (
        Index("ix_restaurants_lat_lng", "latitude", "longitude"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    province_id: int = Field(foreign_key="provinces.id", index=True)
    name: str = Field(index=True, max_length=220)
    address: str = Field(max_length=350)
    latitude: float = Field(index=True)
    longitude: float = Field(index=True)
    cuisine_type: str = Field(default="Đặc sản Sài Gòn", max_length=120)
    specialty_dishes: Optional[str] = Field(default=None, max_length=300)
    price_range: str = Field(default="45.000đ - 120.000đ", max_length=120)
    opening_hours: str = Field(default="06:30 - 22:00", max_length=150)
    contact_phone: Optional[str] = Field(default=None, max_length=50)
    rating: float = Field(default=4.6)
    review_count: int = Field(default=150)
    reviews_count: int = Field(default=120, index=True)
    sample_reviews_json: Optional[str] = Field(default="[]", sa_column=Column(Text, nullable=True))
    is_high_rated: bool = Field(default=True, index=True)
    specialties: Optional[str] = Field(default=None, max_length=300)
    image_url: Optional[str] = Field(default=None, max_length=550)
    thumbnail_url: Optional[str] = Field(default=None, max_length=550)
    is_sponsored: bool = Field(default=False)
    sponsor_label: Optional[str] = Field(default=None, max_length=150)
    is_verified: bool = Field(default=False, index=True)
    source: str = Field(default="admin", index=True, max_length=60)
    source_url: Optional[str] = Field(default=None, max_length=550)
    status: str = Field(default="published", index=True, max_length=30)
    data_source: str = Field(default="internal", max_length=60)
    last_updated_at: datetime = Field(default_factory=datetime.utcnow)

    province: Optional[Province] = Relationship(back_populates="restaurants")


# ============================================================================
# 5. NGƯỜI DÙNG, YÊU THÍCH, LỊCH TRÌNH, BÁO CÁO & AUDIT LOGS
# ============================================================================

class User(SQLModel, table=True):
    """Bảng Tài khoản Người dùng & Nhân sự Quản trị (Liên kết bảng Role & Permission)."""

    __tablename__ = "users"

    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(index=True, unique=True, max_length=180)
    full_name: str = Field(max_length=160)
    hashed_password: str = Field(max_length=260)
    role: str = Field(default="user", index=True, max_length=50)
    role_id: Optional[int] = Field(default=None, foreign_key="roles.id", index=True)
    assigned_province_id: Optional[int] = Field(
        default=None, foreign_key="provinces.id"
    )
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    role_obj: Optional[Role] = Relationship(back_populates="users")
    favorites: List["Favorite"] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )
    itineraries: List["Itinerary"] = Relationship(back_populates="user")


class Favorite(SQLModel, table=True):
    """Bảng Danh sách Yêu thích của người dùng."""

    __tablename__ = "favorites"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id", index=True)
    target_type: str = Field(max_length=40)
    target_id: int
    created_at: datetime = Field(default_factory=datetime.utcnow)

    user: Optional[User] = Relationship(back_populates="favorites")


class Itinerary(SQLModel, table=True):
    """Bảng Lịch trình tham quan cá nhân hoặc Lịch trình mẫu."""

    __tablename__ = "itineraries"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = Field(default=None, foreign_key="users.id", index=True)
    province_id: int = Field(foreign_key="provinces.id", index=True)
    title: str = Field(max_length=220)
    description: Optional[str] = Field(default=None, sa_column=Column(Text))
    total_days: int = Field(default=1)
    is_template: bool = Field(default=False, index=True)
    status: str = Field(default="active", max_length=30)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    user: Optional[User] = Relationship(back_populates="itineraries")
    province: Optional[Province] = Relationship(back_populates="itineraries")
    stops: List["ItineraryStop"] = Relationship(
        back_populates="itinerary",
        sa_relationship_kwargs={
            "cascade": "all, delete-orphan",
            "order_by": "ItineraryStop.day_number, ItineraryStop.stop_order",
        },
    )


class ItineraryStop(SQLModel, table=True):
    """Bảng Điểm dừng trong lịch trình."""

    __tablename__ = "itinerary_stops"

    id: Optional[int] = Field(default=None, primary_key=True)
    itinerary_id: int = Field(foreign_key="itineraries.id", index=True)
    day_number: int = Field(default=1)
    stop_order: int = Field(default=1)
    stop_type: str = Field(default="destination", max_length=40)
    reference_id: Optional[int] = Field(default=None)
    title: str = Field(max_length=220)
    address: Optional[str] = Field(default=None, max_length=350)
    latitude: float = Field(default=10.7769)
    longitude: float = Field(default=106.7009)
    planned_time: str = Field(default="08:30 - 10:00", max_length=60)
    duration_mins: int = Field(default=90)
    notes: Optional[str] = Field(default=None, sa_column=Column(Text))

    itinerary: Optional[Itinerary] = Relationship(back_populates="stops")


class ContentReport(SQLModel, table=True):
    """Bảng Báo cáo sai thông tin & Đánh giá từ cộng đồng."""

    __tablename__ = "content_reports"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = Field(default=None, foreign_key="users.id")
    target_type: str = Field(max_length=40)
    target_id: int
    target_name: str = Field(max_length=220)
    issue_type: str = Field(max_length=80)
    description: str = Field(sa_column=Column(Text, nullable=False))
    rating: Optional[int] = Field(default=None)
    status: str = Field(default="pending", index=True, max_length=30)
    moderator_note: Optional[str] = Field(default=None, sa_column=Column(Text))
    created_at: datetime = Field(default_factory=datetime.utcnow)
    resolved_at: Optional[datetime] = Field(default=None)


class AuditLog(SQLModel, table=True):
    """Bảng Nhật ký thao tác quản trị (Audit Logs)."""

    __tablename__ = "audit_logs"

    id: Optional[int] = Field(default=None, primary_key=True)
    actor_id: Optional[int] = Field(default=None, foreign_key="users.id")
    actor_email: str = Field(max_length=180)
    actor_role: str = Field(max_length=60)
    action: str = Field(index=True, max_length=50)
    entity_type: str = Field(index=True, max_length=60)
    entity_id: Optional[int] = Field(default=None)
    summary: str = Field(max_length=400)
    changes_json: str = Field(default="{}", sa_column=Column(Text))
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)
