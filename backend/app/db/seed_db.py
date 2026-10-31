import json
from datetime import datetime
from sqlalchemy import inspect, text
from sqlmodel import Session, SQLModel

from app.core.security import DEFAULT_ROLE_PERMISSIONS, get_password_hash
from app.db.session import SessionLocal, engine
from app.integrations.cloudinary_service import cloudinary_service
from app.models.crawl_job import CrawlJob
from app.models.models import (
    AdminRole,
    AuditLog,
    Category,
    ContentReport,
    Destination,
    DestinationImage,
    Favorite,
    Itinerary,
    ItineraryStop,
    LocalFood,
    Permission,
    Province,
    Restaurant,
    Role,
    RolePermissionLink,
    SMSOTPVerification,
    User,
)


def _ensure_ingestion_columns() -> None:
    """
    Tự động bổ sung các cột mới của Module AI Data Ingestion, Review Engine và Auth Module
    (is_verified, source, source_url, reviews_count, sample_reviews_json, is_high_rated, specialties, phone)
    nếu cơ sở dữ liệu SQLite/PostgreSQL đã được tạo từ phiên bản trước.
    """
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    target_tables = ["destinations", "restaurants"]

    with engine.begin() as conn:
        for tbl in target_tables:
            if tbl not in existing_tables:
                continue
            cols = {col["name"] for col in inspector.get_columns(tbl)}
            if "is_verified" not in cols:
                conn.execute(
                    text(f"ALTER TABLE {tbl} ADD COLUMN is_verified BOOLEAN DEFAULT 1")
                )
            if "source" not in cols:
                conn.execute(
                    text(f"ALTER TABLE {tbl} ADD COLUMN source VARCHAR(60) DEFAULT 'admin'")
                )
            if "source_url" not in cols:
                conn.execute(
                    text(f"ALTER TABLE {tbl} ADD COLUMN source_url VARCHAR(550) DEFAULT NULL")
                )

        if "restaurants" in existing_tables:
            rest_cols = {col["name"] for col in inspector.get_columns("restaurants")}
            if "reviews_count" not in rest_cols:
                conn.execute(
                    text("ALTER TABLE restaurants ADD COLUMN reviews_count INTEGER DEFAULT 120")
                )
                conn.execute(
                    text("UPDATE restaurants SET reviews_count = review_count WHERE reviews_count IS NULL OR reviews_count = 120")
                )
            if "sample_reviews_json" not in rest_cols:
                conn.execute(
                    text("ALTER TABLE restaurants ADD COLUMN sample_reviews_json TEXT DEFAULT '[]'")
                )
            if "is_high_rated" not in rest_cols:
                conn.execute(
                    text("ALTER TABLE restaurants ADD COLUMN is_high_rated BOOLEAN DEFAULT 1")
                )
            if "specialties" not in rest_cols:
                conn.execute(
                    text("ALTER TABLE restaurants ADD COLUMN specialties VARCHAR(300) DEFAULT NULL")
                )
                conn.execute(
                    text("UPDATE restaurants SET specialties = specialty_dishes WHERE specialties IS NULL")
                )

        if "users" in existing_tables:
            user_cols = {col["name"] for col in inspector.get_columns("users")}
            if "phone" not in user_cols:
                conn.execute(
                    text("ALTER TABLE users ADD COLUMN phone VARCHAR(20) DEFAULT NULL")
                )
            conn.execute(
                text("UPDATE users SET phone = '0987654321' WHERE email = 'admin@tripflow.vn' AND (phone IS NULL OR phone = '')")
            )
            conn.execute(
                text("UPDATE users SET phone = '0901234567' WHERE email = 'traveler@tripflow.vn' AND (phone IS NULL OR phone = '')")
            )


def _seed_rbac_users_and_categories(db: Session, now: datetime) -> None:
    """Khởi tạo Role, Permission, Users và Categories nếu DB mới tinh."""
    if db.query(Permission).count() == 0:
        permission_defs = [
            ("destination:read", "Xem địa điểm du lịch", "destination", "Xem danh sách và chi tiết địa điểm"),
            ("destination:write", "Tạo & sửa địa điểm", "destination", "Thêm mới và chỉnh sửa địa điểm du lịch"),
            ("destination:delete", "Xóa địa điểm", "destination", "Xóa địa điểm khỏi hệ thống"),
            ("food:write", "Quản lý đặc sản", "local_food", "Thêm, sửa, ẩn đặc sản địa phương"),
            ("restaurant:write", "Quản lý nhà hàng", "restaurant", "Thêm, sửa, ẩn nhà hàng dọc lộ trình"),
            ("itinerary:write", "Quản lý lịch trình mẫu", "itinerary", "Tạo và chỉnh sửa lịch trình mẫu"),
            ("report:moderate", "Duyệt báo cáo & đánh giá", "report", "Xác minh và xử lý báo sai thông tin"),
            ("partner:manage", "Quản lý đối tác & tài trợ", "partner", "Gắn nhãn tài trợ và nguồn dữ liệu đối tác"),
            ("user:manage", "Quản lý tài khoản & RBAC", "user", "Phân quyền Role/Permission và khóa tài khoản"),
            ("audit:read", "Xem nhật ký Audit Logs", "audit", "Tra cứu lịch sử thao tác quản trị"),
        ]
        perm_map = {}
        for idx, (code, name, module, desc) in enumerate(permission_defs, start=1):
            p = Permission(id=idx, code=code, name=name, module=module, description=desc)
            db.add(p)
            perm_map[code] = p
        db.flush()

        role_defs = [
            (
                1,
                "super_admin",
                "Super Admin",
                "Toàn quyền hệ thống, quản lý nhân sự, phân quyền Role/Permission và cấu hình hạn mức.",
            ),
            (
                2,
                "content_admin",
                "Content Admin",
                "Quản lý và duyệt xuất bản nội dung toàn bộ các tỉnh/thành trên toàn quốc.",
            ),
            (
                3,
                "province_editor",
                "Nhân viên Nội dung theo Tỉnh",
                "Tạo và chỉnh sửa dữ liệu trong phạm vi tỉnh/thành được phân công (VD: TP. Hồ Chí Minh).",
            ),
            (
                4,
                "moderator",
                "Kiểm duyệt viên (Moderator)",
                "Kiểm duyệt đánh giá, phản hồi cộng đồng và xử lý báo cáo sai thông tin.",
            ),
            (
                5,
                "user",
                "Du khách (User)",
                "Người dùng ứng dụng di động khám phá du lịch và tạo lịch trình cá nhân.",
            ),
        ]

        for r_id, r_code, r_name, r_desc in role_defs:
            role_row = Role(id=r_id, code=r_code, name=r_name, description=r_desc)
            db.add(role_row)
            perms_for_role = DEFAULT_ROLE_PERMISSIONS.get(r_code, ["destination:read"])
            db.add(
                AdminRole(
                    id=r_id,
                    role_code=r_code,
                    role_name=r_name,
                    permissions_json=json.dumps(perms_for_role),
                    description=r_desc,
                )
            )
            for p_code in perms_for_role:
                if p_code in perm_map:
                    db.add(
                        RolePermissionLink(
                            role_id=r_id,
                            permission_id=perm_map[p_code].id,
                        )
                    )
        db.flush()

    if db.query(Category).count() == 0:
        categories = [
            Category(id=1, code="heritage", name="Di tích lịch sử", icon_name="account_balance", description="Di tích quốc gia đặc biệt và công trình lịch sử"),
            Category(id=2, code="architecture", name="Kiến trúc & Biểu tượng", icon_name="location_city", description="Kiến trúc cổ điển Pháp và công trình biểu tượng đô thị"),
            Category(id=3, code="museum", name="Bảo tàng & Văn hóa", icon_name="museum", description="Bảo tàng lịch sử, mỹ thuật và không gian văn hóa"),
            Category(id=4, code="market", name="Chợ & Mua sắm", icon_name="storefront", description="Chợ truyền thống và trung tâm giao thương sầm uất"),
            Category(id=5, code="street_walk", name="Không gian đô thị & Bến sông", icon_name="directions_walk", description="Phố đi bộ, quảng trường và du thuyền ven sông"),
        ]
        db.add_all(categories)
        db.flush()


def _ensure_all_10_provinces_and_content(db: Session, now: datetime) -> None:
    """
    Idempotent Incremental Seed (Upsert):
    Đảm bảo cơ sở dữ liệu luôn có đầy đủ 10 Tỉnh/Thành phố du lịch trọng điểm thuộc 4 vùng miền Việt Nam
    (`Bắc Bộ`, `Trung Bộ`, `Tây Nguyên`, `Nam Bộ`), cùng 28 Địa điểm, 26 Nhà hàng dọc hành lang lộ trình,
    24 Đặc sản địa phương và 11 Lịch trình mẫu.
    """
    # --------------------------------------------------------------------
    # 1. ĐẢM BẢO ĐỦ 10 TỈNH/THÀNH PHỐ TRỌNG ĐIỂM TOÀN QUỐC
    # --------------------------------------------------------------------
    province_defs = [
        (
            1,
            "HCM",
            "TP. Hồ Chí Minh",
            "Nam Bộ",
            (
                "Đô thị năng động bậc nhất Việt Nam, nơi giao thoa giữa di sản kiến trúc Pháp cổ điển, "
                "dấu ấn lịch sử hào hùng, nhịp sống hiện đại sôi động bên sông Sài Gòn và nền ẩm thực đường phố phong phú."
            ),
            "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1200&q=80",
            10.7769,
            106.7009,
        ),
        (
            2,
            "DN",
            "TP. Đà Nẵng",
            "Trung Bộ",
            (
                "Thành phố biển đáng sống miền Trung với bãi biển Mỹ Khê quyến rũ, danh thắng Ngũ Hành Sơn, "
                "bán đảo Sơn Trà xanh mát, những cây cầu biểu tượng bắc qua sông Hàn và ẩm thực miền Trung đậm đà."
            ),
            "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1200&q=80",
            16.0544,
            108.2022,
        ),
        (
            3,
            "HN",
            "Thủ đô Hà Nội",
            "Bắc Bộ",
            (
                "Thủ đô nghìn năm văn hiến với 36 phố phường cổ kính, Hồ Gươm lịch sử, Văn Miếu - Quốc Tử Giám, "
                "Hoàng thành Thăng Long và tinh hoa ẩm thực Bắc Bộ thanh tao."
            ),
            "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1200&q=80",
            21.0285,
            105.8542,
        ),
        (
            4,
            "QN",
            "Quảng Ninh (Vịnh Hạ Long)",
            "Bắc Bộ",
            (
                "Kỳ quan thiên nhiên thế giới Vịnh Hạ Long với hàng nghìn đảo đá vôi kỳ vĩ trên làn nước ngọc bích, "
                "Bảo tàng Quảng Ninh hiện đại và ẩm thực hải sản chả mực giã tay trứ danh."
            ),
            "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80",
            20.9599,
            107.0425,
        ),
        (
            5,
            "LC",
            "Lào Cai (Sa Pa)",
            "Bắc Bộ",
            (
                "Thị trấn trong sương vùng cao Tây Bắc với đỉnh Fansipan - Nóc nhà Đông Dương hùng vĩ, "
                "thung lũng ruộng bậc thang Mường Hoa, bản Cát Cát và ẩm thực thắng cố, lẩu cá hồi đặc sắc."
            ),
            "https://images.unsplash.com/photo-1540611025311-01df3cef54b5?auto=format&fit=crop&w=1200&q=80",
            22.3364,
            103.8438,
        ),
        (
            6,
            "HUE",
            "Thừa Thiên Huế (Cố đô Huế)",
            "Trung Bộ",
            (
                "Kinh đô xưa của triều đại nhà Nguyễn với Quần thể di tích Cố đô Huế được UNESCO công nhận, "
                "chùa Thiên Mụ bên dòng sông Hương thơ mộng và nền ẩm thực cung đình lẫn dân gian tinh tế."
            ),
            "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1200&q=80",
            16.4637,
            107.5909,
        ),
        (
            7,
            "QNA",
            "Quảng Nam (Phố cổ Hội An)",
            "Trung Bộ",
            (
                "Thương cảng cổ Hội An rực rỡ sắc đèn lồng bên dòng sông Hoài, Chùa Cầu trăm tuổi, "
                "Rừng dừa Bảy Mẫu xanh mướt và những món ngon trứ danh Cao lầu, Cơm gà phố Hội."
            ),
            "https://images.unsplash.com/photo-1555400038-63f5ba517a47?auto=format&fit=crop&w=1200&q=80",
            15.8801,
            108.3380,
        ),
        (
            8,
            "KH",
            "Khánh Hòa (Nha Trang)",
            "Trung Bộ",
            (
                "Thiên đường du lịch biển đảo Nam Trung Bộ với vịnh Nha Trang trong xanh, Tháp Bà Ponagar cổ kính, "
                "đảo Hòn Tre sôi động và đặc sản bún chả cá sứa, nem nướng Ninh Hòa."
            ),
            "https://images.unsplash.com/photo-1536086845232-47c3021fb97c?auto=format&fit=crop&w=1200&q=80",
            12.2388,
            109.1967,
        ),
        (
            9,
            "LD",
            "Lâm Đồng (Đà Lạt)",
            "Tây Nguyên",
            (
                "Thành phố ngàn hoa trên cao nguyên Lâm Viên se lạnh quanh năm với Hồ Xuân Hương, "
                "Quảng trường Lâm Viên, đỉnh Langbiang huyền thoại và ẩm thực phố núi ấm áp."
            ),
            "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1200&q=80",
            11.9404,
            108.4583,
        ),
        (
            10,
            "KG",
            "Kiên Giang (Đảo Ngọc Phú Quốc)",
            "Nam Bộ",
            (
                "Đảo Ngọc lớn nhất Việt Nam giữa vịnh Thái Lan với những bãi biển hoàng hôn tuyệt mỹ, "
                "Dinh Cậu, Cầu Hôn Sunset Town và đặc sản Bún quậy Kiến Xây, Gỏi cá trích tươi ngon."
            ),
            "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1200&q=80",
            10.2899,
            103.9840,
        ),
    ]

    existing_provinces_by_code = {p.code: p for p in db.query(Province).all()}
    existing_provinces_by_id = {p.id: p for p in db.query(Province).all()}

    for p_id, code, name, region, desc, hero_img, lat, lng in province_defs:
        if code not in existing_provinces_by_code and p_id not in existing_provinces_by_id:
            prov = Province(
                id=p_id,
                code=code,
                name=name,
                region=region,
                description=desc,
                hero_image=hero_img,
                center_lat=lat,
                center_lng=lng,
                is_active=True,
                data_source="internal",
                updated_at=now,
            )
            db.add(prov)
    db.flush()

    # Khởi tạo Users nếu bảng User đang trống (phải chạy sau khi có Province id=1)
    if db.query(User).count() == 0:
        users = [
            User(
                id=1,
                email="admin@tripflow.vn",
                phone="0987654321",
                full_name="Nguyễn Quản Trị (Super Admin)",
                hashed_password=get_password_hash("Admin@123"),
                role="super_admin",
                role_id=1,
                assigned_province_id=None,
                is_active=True,
                created_at=now,
            ),
            User(
                id=2,
                email="content@tripflow.vn",
                full_name="Trần Biên Tập (Content Admin)",
                hashed_password=get_password_hash("Content@123"),
                role="content_admin",
                role_id=2,
                assigned_province_id=None,
                is_active=True,
                created_at=now,
            ),
            User(
                id=3,
                email="hcm.editor@tripflow.vn",
                full_name="Lê Minh Sài Gòn (Biên tập viên TP.HCM)",
                hashed_password=get_password_hash("Editor@123"),
                role="province_editor",
                role_id=3,
                assigned_province_id=1,
                is_active=True,
                created_at=now,
            ),
            User(
                id=4,
                email="mod@tripflow.vn",
                full_name="Phạm Kiểm Duyệt (Moderator)",
                hashed_password=get_password_hash("Mod@123"),
                role="moderator",
                role_id=4,
                assigned_province_id=None,
                is_active=True,
                created_at=now,
            ),
            User(
                id=5,
                email="traveler@tripflow.vn",
                phone="0901234567",
                full_name="Hoàng Du Khách",
                hashed_password=get_password_hash("User@123"),
                role="user",
                role_id=5,
                assigned_province_id=None,
                is_active=True,
                created_at=now,
            ),
        ]
        db.add_all(users)
        db.flush()

    # --------------------------------------------------------------------
    # 2. ĐẢM BẢO ĐỦ 28 ĐỊA ĐIỂM DU LỊCH CHẤT LƯỢNG CAO TRÊN 10 TỈNH/THÀNH
    # --------------------------------------------------------------------
    raw_destinations = [
        # --- 1. TP. Hồ Chí Minh (8 địa điểm) ---
        (
            1, 1, 1,
            "Dinh Độc Lập (Hội trường Thống Nhất)",
            "dinh-doc-lap",
            (
                "Di tích quốc gia đặc biệt nằm giữa khuôn viên rợp bóng cây cổ thụ rộng 12 ha tại trung tâm Quận 1. "
                "Công trình do kiến trúc sư Ngô Viết Thụ thiết kế, kết hợp hài hòa kiến trúc hiện đại phương Tây và triết lý phương Đông. "
                "Du khách có thể tham quan phòng Khánh tiết, phòng Nội các, hầm chỉ huy chiến lược và chiếc trực thăng lịch sử trên sân thượng."
            ),
            "135 Nam Kỳ Khởi Nghĩa, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh",
            10.7770, 106.6953,
            "08:00 - 15:30 (Tất cả các ngày trong tuần)",
            "40.000đ - 65.000đ/người lớn",
            4.8, 3420, 120, True, False, None, "internal",
            "Ban Biên Tập TripFlow xác thực từ Hội trường Thống Nhất",
            "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            2, 1, 4,
            "Chợ Bến Thành",
            "cho-ben-thanh",
            (
                "Ngôi chợ biểu tượng hơn 110 năm tuổi của Sài Gòn - TP. Hồ Chí Minh với tháp đồng hồ 3 mặt nổi tiếng ở cửa Nam. "
                "Bên trong chợ quy tụ hơn 1.500 sạp hàng thủ công mỹ nghệ, vải vóc, quà lưu niệm và khu ẩm thực truyền thống "
                "nhộn nhịp bậc nhất với bún mắm, bánh bèo, chè Nam Bộ và sinh tố trái cây nhiệt đới."
            ),
            "Đường Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh",
            10.7725, 106.6980,
            "06:00 - 19:00 (Chợ đêm: 19:00 - 23:00)",
            "Miễn phí vào cổng",
            4.7, 4180, 90, True, False, None, "internal",
            "Sở Du lịch TP. Hồ Chí Minh & Khảo sát thực địa TripFlow",
            "https://images.unsplash.com/photo-1555400038-63f5ba517a47?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            3, 1, 2,
            "Nhà thờ Đức Bà Sài Gòn",
            "nha-tho-duc-ba-sai-gon",
            (
                "Kiệt tác kiến trúc Roman kết hợp Gothic được hoàn thành năm 1880 tại Quảng trường Công xã Paris. "
                "Toàn bộ gạch xây dựng mang sắc đỏ hồng đặc trưng được chuyển trực tiếp từ Marseille (Pháp), "
                "tạo nên khung cảnh cổ kính, lãng mạn giữa lòng trung tâm Quận 1."
            ),
            "01 Công xã Paris, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh",
            10.7798, 106.6990,
            "Tham quan khuôn viên cả ngày (Đang trùng tu phần mái tháp)",
            "Miễn phí",
            4.8, 3890, 45, True, False, None, "internal",
            "Cổng thông tin Du lịch TP.HCM (Vibrant Ho Chi Minh City)",
            "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            4, 1, 2,
            "Bưu điện Trung tâm Sài Gòn",
            "buu-dien-trung-tam-sai-gon",
            (
                "Được xây dựng trong giai đoạn 1886–1891 với mái vòm sắt uốn cong tinh xảo mang đậm phong cách châu Âu Phục hưng. "
                "Bên trong Bưu điện gây ấn tượng mạnh với hai bản đồ lịch sử vẽ tay trên tường vòm cao, những buồng điện thoại gỗ cổ điển "
                "và quầy bưu phẩm lưu niệm hoạt động liên tục suốt hơn một thế kỷ."
            ),
            "02 Công xã Paris, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh",
            10.7800, 106.6999,
            "07:30 - 18:00 (Thứ 2 - Thứ 7), 08:00 - 17:00 (Chủ nhật)",
            "Miễn phí",
            4.8, 3650, 60, True, False, None, "internal",
            "Bưu điện TP. Hồ Chí Minh & Ban Biên Tập TripFlow",
            "https://images.unsplash.com/photo-1540611025311-01df3cef54b5?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            5, 1, 1,
            "Bến Nhà Rồng - Bảo tàng Hồ Chí Minh",
            "ben-nha-rong-bao-tang-ho-chi-minh",
            (
                "Nằm tại ngã ba sông Sài Gòn giao với kênh Tàu Hủ, Bến Nhà Rồng là nơi người thanh niên Nguyễn Tất Thành "
                "lên tàu Amiral Latouche-Tréville ra đi tìm đường cứu nước ngày 05/06/1911. Công trình nổi bật với kiến trúc Tây Âu "
                "kết hợp mái gắn đôi rồng chầu mặt trăng theo mô-típ đình chùa Việt Nam."
            ),
            "01 Nguyễn Tất Thành, Phường 13, Quận 4, TP. Hồ Chí Minh",
            10.7683, 106.7068,
            "07:30 - 11:30 & 13:30 - 17:00 (Thứ 3 - Chủ nhật)",
            "20.000đ/lượt (Miễn phí cho học sinh, sinh viên có thẻ)",
            4.7, 2190, 90, False, False, None, "internal",
            "Bảo tàng Hồ Chí Minh - Chi nhánh TP.HCM",
            "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            6, 1, 5,
            "Phố đi bộ Nguyễn Huệ & Công viên Bến Bạch Đằng",
            "pho-di-bo-nguyen-hue-ben-bach-dang",
            (
                "Trục cảnh quan hiện đại và sôi động nhất trung tâm Quận 1, kéo dài từ trụ sở UBND Thành phố cổ kính tới bờ sông Sài Gòn lộng gió. "
                "Du khách có thể tản bộ ngắm Chung cư 42 Nguyễn Huệ, thưởng thức nhạc nước buổi tối và trải nghiệm xe buýt đường sông Saigon Waterbus."
            ),
            "Đường Nguyễn Huệ & Đường Tôn Đức Thắng, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh",
            10.7744, 106.7035,
            "Mở cửa tự do 24/24 (Phố đi bộ cấm xe cuối tuần 19:00 - 23:00)",
            "Miễn phí (Vé Waterbus tham khảo: 15.000đ/lượt)",
            4.8, 5120, 90, True, True, "Điểm đến Đối tác Du lịch Đường sông TP.HCM", "partner",
            "Đối tác Saigon Waterbus & Sở Du lịch TP.HCM",
            "https://images.unsplash.com/photo-1536086845232-47c3021fb97c?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            7, 1, 3,
            "Bảo tàng Chứng tích Chiến tranh",
            "bao-tang-chung-tich-chien-tranh",
            (
                "Một trong những bảo tàng thu hút đông du khách quốc tế và trong nước nhất tại Việt Nam, nằm trong Top bảo tàng ấn tượng châu Á. "
                "Bảo tàng lưu giữ hơn 20.000 tài liệu, hiện vật và phim ảnh chân thực về lịch sử đấu tranh bảo vệ độc lập và giá trị của hòa bình."
            ),
            "28 Võ Văn Tần, Phường Võ Thị Sáu, Quận 3, TP. Hồ Chí Minh",
            10.7795, 106.6921,
            "07:30 - 17:30 (Mở cửa tất cả các ngày)",
            "40.000đ/người",
            4.9, 6240, 120, True, False, None, "internal",
            "Bảo tàng Chứng tích Chiến tranh TP.HCM",
            "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            8, 1, 1,
            "Địa đạo Củ Chi (Khu di tích lịch sử Bến Dược)",
            "dia-dao-cu-chi-ben-duoc",
            (
                "Kỳ quan quân sự dưới lòng đất dài hơn 250 km như một mạng nhện nhiều tầng kiên cố tại vùng 'Đất thép thành đồng'. "
                "Du khách được trải nghiệm chui hầm địa đạo, tìm hiểu hệ thống bếp Hoàng Cầm giấu khói và thưởng thức khoai mì chấm muối đậu phộng nóng hổi."
            ),
            "Ấp Phú Hiệp, Xã Phú Mỹ Hưng, Huyện Củ Chi, TP. Hồ Chí Minh",
            11.1414, 106.4625,
            "07:00 - 17:00",
            "35.000đ - 125.000đ/người",
            4.8, 2980, 180, False, False, None, "internal",
            "Khu Di tích Lịch sử Địa đạo Củ Chi",
            "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1000&q=80",
        ),
        # --- 2. TP. Đà Nẵng (3 địa điểm) ---
        (
            9, 2, 2,
            "Cầu Rồng & Bờ Đông Sông Hàn Đà Nẵng",
            "cau-rong-da-nang",
            (
                "Cây cầu biểu tượng của TP. Đà Nẵng với thiết kế hình rồng thép uốn lượn vươn mình ra biển Đông, "
                "nổi tiếng với màn trình diễn phun lửa và phun nước đặc sắc vào mỗi tối cuối tuần."
            ),
            "Đường Nguyễn Văn Linh, Quận Hải Châu, TP. Đà Nẵng",
            16.0611, 108.2275,
            "Mở cửa 24/24 (Phun lửa 21:00 Thứ 6, Thứ 7, Chủ nhật)",
            "Miễn phí",
            4.8, 3100, 60, True, False, None, "internal",
            "Sở Du lịch TP. Đà Nẵng & TripFlow",
            "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            10, 2, 1,
            "Danh thắng Ngũ Hành Sơn (Đà Nẵng)",
            "danh-thang-ngu-hanh-son-da-nang",
            (
                "Quần thể 5 ngọn núi đá vôi Kim - Mộc - Thủy - Hỏa - Thổ nằm bên bờ biển Đà Nẵng với động Huyền Không kỳ ảo, "
                "chùa Linh Ứng cổ kính và làng nghề điêu khắc đá mỹ nghệ Non Nước hơn 400 năm tuổi."
            ),
            "81 Huyền Trân Công Chúa, Phường Hòa Hải, Quận Ngũ Hành Sơn, TP. Đà Nẵng",
            16.0033, 108.2631,
            "07:00 - 17:30",
            "40.000đ/lượt (Thang máy: 15.000đ/lượt)",
            4.8, 2840, 120, True, False, None, "internal",
            "Ban Quản lý Di tích Danh thắng Ngũ Hành Sơn Đà Nẵng",
            "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            12, 2, 2,
            "Chùa Linh Ứng Bán Đảo Sơn Trà",
            "chua-linh-ung-ban-dao-son-tra",
            (
                "Ngôi chùa lớn nhất Đà Nẵng tọa lạc trên lưng chừng bán đảo Sơn Trà, nổi bật với tượng Phật Quan Thế Âm cao 67m "
                "hướng nhìn ra vịnh biển Đà Nẵng xanh biếc và rừng nguyên sinh Sơn Trà."
            ),
            "Bãi Bụt, Phường Thọ Quang, Quận Sơn Trà, TP. Đà Nẵng",
            16.1003, 108.2778,
            "06:00 - 21:00",
            "Miễn phí",
            4.9, 3920, 90, True, False, None, "internal",
            "Sở Du lịch TP. Đà Nẵng & TripFlow",
            "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1000&q=80",
        ),
        # --- 3. Thủ đô Hà Nội (3 địa điểm) ---
        (
            11, 3, 1,
            "Hồ Hoàn Kiếm & Đền Ngọc Sơn",
            "ho-hoan-kiem-den-ngoc-son",
            "Trái tim văn hóa lịch sử của Thủ đô Hà Nội với Tháp Rùa cổ kính, Cầu Thê Húc đỏ son và không gian phố đi bộ cuối tuần.",
            "Phường Hàng Trống, Quận Hoàn Kiếm, Thủ đô Hà Nội",
            21.0288, 105.8525,
            "07:00 - 19:00 (Hồ Hoàn Kiếm mở tự do 24/24)",
            "30.000đ/vé vào Đền Ngọc Sơn",
            4.9, 5400, 90, True, False, None, "internal",
            "Sở Du lịch Hà Nội & TripFlow",
            "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            13, 3, 1,
            "Văn Miếu - Quốc Tử Giám",
            "van-mieu-quoc-tu-giam",
            (
                "Trường đại học đầu tiên của Việt Nam được xây dựng từ năm 1070 dưới thời vua Lý Thánh Tông, "
                "lưu giữ 82 bia Tiến sĩ được UNESCO công nhận là Di sản tư liệu thế giới và Khuê Văn Các biểu tượng của Thủ đô."
            ),
            "58 Quốc Tử Giám, Phường Văn Miếu, Quận Đống Đa, Thủ đô Hà Nội",
            21.0278, 105.8355,
            "08:00 - 17:00 (Có tour đêm Tinh hoa Đạo học)",
            "70.000đ/người lớn",
            4.9, 4850, 120, True, False, None, "internal",
            "Trung tâm Hoạt động Văn hóa Khoa học Văn Miếu - Quốc Tử Giám",
            "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            14, 3, 1,
            "Khu Di tích Hoàng thành Thăng Long",
            "hoang-thanh-thang-long",
            (
                "Di sản văn hóa thế giới UNESCO gắn liền với lịch sử kinh đô Thăng Long - Hà Nội suốt hơn 13 thế kỷ, "
                "nổi bật với Đoan Môn, Điện Kính Thiên, Bắc Môn và Khu khảo cổ học 18 Hoàng Diệu."
            ),
            "19C Hoàng Diệu, Phường Điện Biên, Quận Ba Đình, Thủ đô Hà Nội",
            21.0341, 105.8400,
            "08:00 - 17:00 (Thứ 3 - Chủ nhật)",
            "70.000đ/lượt",
            4.8, 3620, 120, True, False, None, "internal",
            "Trung tâm Bảo tồn Di sản Thăng Long - Hà Nội",
            "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1000&q=80",
        ),
        # --- 4. Quảng Ninh - Vịnh Hạ Long (2 địa điểm) ---
        (
            15, 4, 5,
            "Vịnh Hạ Long - Động Thiên Cung & Hòn Trống Mái",
            "vinh-ha-long-dong-thien-cung",
            (
                "Di sản thiên nhiên thế giới được UNESCO hai lần vinh danh với gần 2.000 hòn đảo đá vôi kỳ vĩ, "
                "Động Thiên Cung lộng lẫy nhũ đá và biểu tượng Hòn Trống Mái giữa làn nước xanh ngọc bích."
            ),
            "Cảng tàu khách quốc tế Hạ Long, Phường Bãi Cháy, TP. Hạ Long, Quảng Ninh",
            20.9101, 107.0763,
            "06:30 - 18:30 (Tàu tham quan tuyến 1 & tuyến 2)",
            "290.000đ/vé tuyến + 200.000đ vé tàu",
            4.9, 6450, 240, True, False, None, "internal",
            "Ban Quản lý Vịnh Hạ Long & Sở Du lịch Quảng Ninh",
            "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            16, 4, 3,
            "Bảo tàng & Thư viện Quảng Ninh",
            "bao-tang-quang-ninh",
            (
                "Kiệt tác kiến trúc 'Viên ngọc đen' bên bờ vịnh Hạ Long lấy cảm hứng từ than đá Quảng Ninh, "
                "trưng bày bộ xương cá voi khổng lồ, không gian văn hóa biển đảo và mô hình hầm lò khai thác than sống động."
            ),
            "Đường Trần Quốc Nghiễn, Phường Hồng Gai, TP. Hạ Long, Quảng Ninh",
            20.9515, 107.0998,
            "08:00 - 12:00 & 13:00 - 17:00",
            "40.000đ/người lớn",
            4.8, 3290, 90, True, False, None, "internal",
            "Bảo tàng Quảng Ninh & TripFlow",
            "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1000&q=80",
        ),
        # --- 5. Lào Cai - Sa Pa (2 địa điểm) ---
        (
            17, 5, 2,
            "Đỉnh Fansipan - Nóc nhà Đông Dương (Sun World Fansipan Legend)",
            "dinh-fansipan-sapa",
            (
                "Đỉnh núi cao 3.143m thuộc dãy Hoàng Liên Sơn hùng vĩ. Du khách trải nghiệm tàu hỏa leo núi Mường Hoa, "
                "cáp treo vượt biển mây và chiêm bái quần thể tâm linh kỳ vĩ trên đỉnh thiêng Tây Bắc."
            ),
            "Khu du lịch Sun World Fansipan Legend, Đường Nguyễn Chí Thanh, TX. Sa Pa, Lào Cai",
            22.3033, 103.7750,
            "07:30 - 17:30",
            "800.000đ/vé cáp treo khứ hồi",
            4.9, 5380, 240, True, True, "Đối tác Khu du lịch Quốc gia Sa Pa", "partner",
            "Sở Du lịch Lào Cai & Sun World Fansipan Legend",
            "https://images.unsplash.com/photo-1540611025311-01df3cef54b5?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            18, 5, 3,
            "Bản Cát Cát & Thác Tiên Sa Sa Pa",
            "ban-cat-cat-sapa",
            (
                "Bản làng cổ đẹp nhất Tây Bắc của đồng bào dân tộc H'Mông nằm dưới chân dãy Hoàng Liên Sơn, "
                "nổi bật với những nếp nhà gỗ pơ-mu, guồng nước tre khổng lồ, nghề dệt thổ cẩm và thác Tiên Sa."
            ),
            "Xã San Sả Hồ, Thị xã Sa Pa, Tỉnh Lào Cai",
            22.3268, 103.8315,
            "06:00 - 18:00",
            "150.000đ/người lớn",
            4.7, 3810, 150, True, False, None, "internal",
            "Trung tâm Thông tin & Xúc tiến Du lịch Lào Cai",
            "https://images.unsplash.com/photo-1540611025311-01df3cef54b5?auto=format&fit=crop&w=1000&q=80",
        ),
        # --- 6. Thừa Thiên Huế (2 địa điểm) ---
        (
            19, 6, 1,
            "Quần thể Đại Nội Huế - Hoàng Thành & Tử Cấm Thành",
            "dai-noi-hue-hoang-thanh",
            (
                "Trung tâm hành chính - chính trị tối cao của triều đại nhà Nguyễn suốt 143 năm (1802–1945), "
                "bao gồm Ngọ Môn, Điện Thái Hòa, Thế Miếu, Hiển Lâm Các và Cửu Đỉnh — Di sản Văn hóa Thế giới UNESCO."
            ),
            "Đường 23/8, Phường Thuận Hòa, TP. Huế, Thừa Thiên Huế",
            16.4698, 107.5786,
            "07:00 - 17:30 (Mở cửa đêm Hoàng Cung cuối tuần)",
            "200.000đ/người lớn",
            4.9, 5120, 180, True, False, None, "internal",
            "Trung tâm Bảo tồn Di tích Cố đô Huế",
            "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            20, 6, 1,
            "Chùa Thiên Mụ & Bờ Bắc Sông Hương",
            "chua-thien-mu-hue",
            (
                "Ngôi cổ tự hơn 400 năm tuổi nằm trên đồi Hà Khê bên dòng sông Hương thơ mộng, "
                "biểu tượng tâm linh của xứ Huế với tháp Phước Duyên 7 tầng cao 21m uy nghiêm."
            ),
            "Đường Nguyễn Phúc Nguyên, Phường Hương Long, TP. Huế, Thừa Thiên Huế",
            16.4533, 107.5450,
            "08:00 - 18:00",
            "Miễn phí",
            4.8, 4050, 90, True, False, None, "internal",
            "Sở Du lịch Thừa Thiên Huế & TripFlow",
            "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80",
        ),
        # --- 7. Quảng Nam - Phố cổ Hội An (2 địa điểm) ---
        (
            21, 7, 1,
            "Chùa Cầu & Khu Phố Cổ Hội An",
            "chua-cau-pho-co-hoi-an",
            (
                "Di sản văn hóa thế giới với những dãy nhà cổ mái ngói rêu phong vàng óng, giàn hoa giấy rực rỡ, "
                "biểu tượng Chùa Cầu hơn 400 năm tuổi và đêm phố cổ lung linh hàng nghìn chiếc đèn lồng trên sông Hoài."
            ),
            "Đường Nguyễn Thị Minh Khai & Trần Phú, Phường Minh An, TP. Hội An, Quảng Nam",
            15.8771, 108.3260,
            "07:00 - 22:00",
            "80.000đ/vé tham quan quần thể phố cổ",
            4.9, 6820, 180, True, False, None, "internal",
            "Trung tâm Quản lý Bảo tồn Di sản Văn hóa Hội An",
            "https://images.unsplash.com/photo-1555400038-63f5ba517a47?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            22, 7, 5,
            "Rừng Dừa Bảy Mẫu Cẩm Thanh Hội An",
            "rung-dua-bay-mau-hoi-an",
            (
                "Khu du lịch sinh thái rừng dừa nước xanh mát rộng hơn 100 ha tại cửa sông Thu Bồn. "
                "Du khách ngồi thuyền thúng len lỏi qua rặng dừa, xem múa thúng điêu luyện và quăng chài bắt cá."
            ),
            "Tổ 2, Thôn Cần Nhân, Xã Cẩm Thanh, TP. Hội An, Quảng Nam",
            15.8732, 108.3665,
            "07:00 - 17:30",
            "30.000đ/vé cổng + 150.000đ/thuyền thúng 2 khách",
            4.8, 3490, 120, True, False, None, "internal",
            "Sở Văn hóa, Thể thao và Du lịch Quảng Nam",
            "https://images.unsplash.com/photo-1555400038-63f5ba517a47?auto=format&fit=crop&w=1000&q=80",
        ),
        # --- 8. Khánh Hòa - Nha Trang (2 địa điểm) ---
        (
            23, 8, 1,
            "Tháp Bà Ponagar Nha Trang",
            "thap-ba-ponagar-nha-trang",
            (
                "Quần thể kiến trúc đền tháp Chăm Pa cổ kính quy mô bậc nhất miền Trung nằm trên đồi Cù Lao bên bờ sông Cái, "
                "được xây dựng từ thế kỷ VIII đến thế kỷ XIII với kỹ thuật gạch nung xếp khít không mạch vữa độc đáo."
            ),
            "Đường 2 Tháng 4, Phường Vĩnh Phước, TP. Nha Trang, Khánh Hòa",
            12.2654, 109.1956,
            "06:00 - 17:30",
            "30.000đ/người",
            4.8, 4390, 90, True, False, None, "internal",
            "Trung tâm Bảo tồn Di tích Tỉnh Khánh Hòa",
            "https://images.unsplash.com/photo-1536086845232-47c3021fb97c?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            24, 8, 5,
            "VinWonders Nha Trang - Đảo Hòn Tre",
            "vinwonders-nha-trang-hon-tre",
            (
                "Tổ hợp giải trí và nghỉ dưỡng biển đảo hàng đầu trên đảo Hòn Tre giữa vịnh Nha Trang, "
                "nổi bật với cáp treo vượt biển, công viên nước, thủy cung đại dương và Tata Show."
            ),
            "Đảo Hòn Tre, Phường Vĩnh Nguyên, TP. Nha Trang, Khánh Hòa",
            12.2165, 109.2415,
            "08:30 - 21:00",
            "950.000đ/người lớn (Bao gồm cáp treo 2 chiều)",
            4.9, 5210, 300, True, True, "Điểm đến Giải trí Biển Đảo Nha Trang", "partner",
            "Sở Du lịch Khánh Hòa & VinWonders Nha Trang",
            "https://images.unsplash.com/photo-1536086845232-47c3021fb97c?auto=format&fit=crop&w=1000&q=80",
        ),
        # --- 9. Lâm Đồng - Đà Lạt (2 địa điểm) ---
        (
            25, 9, 2,
            "Quảng trường Lâm Viên & Hồ Xuân Hương Đà Lạt",
            "quang-truong-lam-vien-ho-xuan-huong",
            (
                "Trái tim của thành phố ngàn hoa Đà Lạt với hai công trình kiến trúc khối Nụ hoa Atiso và Hoa Dã Quỳ khổng lồ "
                "bằng kính màu hướng ra mặt Hồ Xuân Hương thơ mộng giữa rừng thông."
            ),
            "Đường Trần Quốc Toản, Phường 10, TP. Đà Lạt, Lâm Đồng",
            11.9404, 108.4425,
            "Mở cửa tự do 24/24",
            "Miễn phí",
            4.8, 4920, 90, True, False, None, "internal",
            "Sở Văn hóa, Thể thao và Du lịch Lâm Đồng",
            "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            26, 9, 5,
            "Khu du lịch Đỉnh Langbiang Đà Lạt",
            "dinh-langbiang-da-lat",
            (
                "Nóc nhà của cao nguyên Lâm Viên ở độ cao 2.167m, nơi du khách đi xe Jeep vượt rừng thông lên đỉnh Radar "
                "ngắm toàn cảnh Suối Vàng, Suối Bạc và giao lưu văn hóa cồng chiêng Tây Nguyên."
            ),
            "Thị trấn Lạc Dương, Huyện Lạc Dương, Tỉnh Lâm Đồng",
            12.0468, 108.4385,
            "07:00 - 17:00",
            "50.000đ/vé cổng (Xe Jeep khứ hồi: 100.000đ/người)",
            4.8, 3760, 150, True, False, None, "internal",
            "Khu du lịch Langbiang Lâm Đồng",
            "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1000&q=80",
        ),
        # --- 10. Kiên Giang - Đảo Ngọc Phú Quốc (2 địa điểm) ---
        (
            27, 10, 1,
            "Dinh Cậu & Chợ Đêm Dương Đông Phú Quốc",
            "dinh-cau-cho-dem-phu-quoc",
            (
                "Biểu tượng tâm linh và thắng cảnh ngắm hoàng hôn đẹp nhất trung tâm Dương Đông Phú Quốc, "
                "nằm trên ghềnh đá tự nhiên vươn ra biển gắn liền với ngọn hải đăng và khu chợ đêm hải sản sầm uất."
            ),
            "Khu phố 2, Phường Dương Đông, TP. Phú Quốc, Kiên Giang",
            10.2175, 103.9578,
            "06:00 - 23:00",
            "Miễn phí",
            4.8, 4120, 120, True, False, None, "internal",
            "Sở Du lịch Kiên Giang & TP. Phú Quốc",
            "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1000&q=80",
        ),
        (
            28, 10, 2,
            "Thị trấn Hoàng Hôn Sunset Town & Cầu Hôn Phú Quốc",
            "thi-tran-hoang-hon-cau-hon-phu-quoc",
            (
                "Quần thể kiến trúc mang sắc màu Địa Trung Hải tại Nam Đảo Phú Quốc với kiệt tác Cầu Hôn (Kiss Bridge) "
                "nơi hai nhịp cầu cách nhau 30cm đón ánh hoàng hôn rực rỡ trên biển đảo Tây Nam."
            ),
            "Phường An Thới, TP. Phú Quốc, Tỉnh Kiên Giang",
            10.0325, 104.0065,
            "07:00 - 22:30",
            "100.000đ/vé tham quan Cầu Hôn",
            4.9, 4680, 180, True, True, "Điểm đến Biểu tượng Nam Đảo Phú Quốc", "partner",
            "Sở Du lịch Kiên Giang & Sunset Town Phú Quốc",
            "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1000&q=80",
        ),
    ]

    existing_dest_slugs = {d.slug for d in db.query(Destination).all()}
    existing_dest_ids = {d.id for d in db.query(Destination).all()}

    for (
        d_id, prov_id, cat_id, name, slug, desc, addr, lat, lng,
        hours, ticket, rating, rev_cnt, dur, featured, sponsored,
        sp_label, source, attr, img_url
    ) in raw_destinations:
        if slug in existing_dest_slugs or d_id in existing_dest_ids:
            continue
        thumb_url = cloudinary_service.build_thumbnail_url(img_url)
        detail_url = cloudinary_service.build_detail_url(img_url)
        dest = Destination(
            id=d_id,
            province_id=prov_id,
            category_id=cat_id,
            name=name,
            slug=slug,
            description=desc,
            address=addr,
            latitude=lat,
            longitude=lng,
            opening_hours=hours,
            ticket_price_info=ticket,
            rating=rating,
            review_count=rev_cnt,
            recommended_duration_mins=dur,
            thumbnail_url=thumb_url,
            detail_image_url=detail_url,
            is_featured=featured,
            is_sponsored=sponsored,
            sponsor_label=sp_label,
            is_verified=True,
            source="admin",
            source_url=None,
            status="published",
            data_source=source,
            source_attribution=attr,
            last_verified_at=now,
            updated_at=now,
        )
        db.add(dest)
        db.flush()

        db.add(
            DestinationImage(
                destination_id=dest.id,
                image_url=detail_url,
                thumbnail_url=thumb_url,
                caption=f"Hình ảnh thực tế {name}",
                sort_order=1,
                license_type="partner_authorized" if sponsored else "owned",
                credit_author="TripFlow Editorial Photography",
            )
        )
    db.flush()

    # --------------------------------------------------------------------
    # 3. ĐẢM BẢO ĐỦ 26 NHÀ HÀNG DỌC HÀNH LANG LỘ TRÌNH TRÊN 10 TỈNH/THÀNH
    # --------------------------------------------------------------------
    raw_restaurants = [
        # --- 1. TP. Hồ Chí Minh (8 nhà hàng) ---
        (
            1, 1,
            "Cơm Tấm Bụi Sài Gòn - Lê Thánh Tôn",
            "100 Lê Thánh Tôn, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh",
            10.7785, 106.7015,
            "Cơm tấm & Món Việt",
            "Cơm tấm sườn nướng mật ong, bì, chả trứng muối, canh khổ qua",
            "55.000đ - 110.000đ", "06:30 - 22:00", "028 3824 5678",
            4.6, 940, False, None, "internal",
            "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80",
        ),
        (
            2, 1,
            "Bánh Mì Huỳnh Hoa - Phạm Ngũ Lão",
            "26 Lê Thị Riêng, Phường Phạm Ngũ Lão, Quận 1, TP. Hồ Chí Minh",
            10.7698, 106.6932,
            "Ẩm thực đường phố",
            "Bánh mì đặc ruột Sài Gòn nhân thập cẩm pate, bơ, chả lụa, thịt nguội, chà bông",
            "65.000đ - 75.000đ", "06:00 - 22:00", "028 3925 0885",
            4.7, 2850, False, None, "internal",
            "https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=900&q=80",
        ),
        (
            3, 1,
            "Bếp Mẹ Ỉn - Lê Thánh Tôn (Gần Chợ Bến Thành)",
            "136/9 Lê Thánh Tôn, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh",
            10.7738, 106.6975,
            "Cơm nhà & Đặc sản Nam Bộ",
            "Bánh xèo tôm thịt nhảy, cơm tấm sườn non, gỏi cuốn tôm thịt, chè chuối nướng",
            "75.000đ - 180.000đ", "10:30 - 22:30", "028 2211 1119",
            4.8, 1780, True, "Đối tác Ẩm thực Địa phương (Michelin Bib Gourmand)", "partner",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80",
        ),
        (
            4, 1,
            "Nhà hàng Ngon (Quán Ăn Ngon 160 Pasteur)",
            "160 Pasteur, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh",
            10.7782, 106.6968,
            "Ẩm thực 3 miền & Sài Gòn",
            "Bánh khọt Vũng Tàu, Hủ tiếu Nam Vang, Gỏi ngó sen tôm thịt, Cơm tấm Sài Gòn",
            "80.000đ - 250.000đ", "07:00 - 22:30", "028 3827 7131",
            4.6, 2310, False, None, "internal",
            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80",
        ),
        (
            5, 1,
            "Bánh Xèo 46A Đinh Công Tráng",
            "46A Đinh Công Tráng, Phường Tân Định, Quận 1/Quận 3, TP. Hồ Chí Minh",
            10.7892, 106.6905,
            "Bánh xèo Nam Bộ",
            "Bánh xèo chảo gang giòn rụm tôm đất thịt ba rọi ăn kèm hơn 10 loại rau rừng",
            "90.000đ - 160.000đ", "10:00 - 14:00 & 16:00 - 21:00", "028 3824 1110",
            4.5, 1420, False, None, "internal",
            "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=900&q=80",
        ),
        (
            6, 1,
            "Phở Hòa Pasteur",
            "260C Pasteur, Phường Võ Thị Sáu, Quận 3, TP. Hồ Chí Minh",
            10.7868, 106.6884,
            "Phở Sài Gòn truyền thống",
            "Phở bò tái nạm gầu gân sườn, quẩy giòn, rau thơm miền Nam & tương đen gia truyền",
            "75.000đ - 115.000đ", "05:30 - 22:30", "028 3829 7943",
            4.7, 2640, True, "Được tài trợ • Quán Phở Gia Truyền Lâu Năm", "partner",
            "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=900&q=80",
        ),
        (
            7, 1,
            "Hủ Tiếu Nam Vang Nhân Quán",
            "A68 Nguyễn Trãi, Phường Nguyễn Cư Trinh, Quận 1 (Giáp Quận 5), TP. Hồ Chí Minh",
            10.7662, 106.6820,
            "Hủ tiếu & Mì Hoa - Việt",
            "Hủ tiếu Nam Vang khô và nước với tôm tươi, thịt bằm, gan heo, trứng cút và tỏi phi thơm lừng",
            "65.000đ - 95.000đ", "06:00 - 23:00", "028 3837 2652",
            4.6, 1180, False, None, "internal",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
        ),
        (
            8, 1,
            "Cơm Tấm Ba Ghiền - Phú Nhuận",
            "84 Đặng Văn Ngữ, Phường 10, Quận Phú Nhuận, TP. Hồ Chí Minh",
            10.7955, 106.6785,
            "Cơm tấm Sài Gòn",
            "Cơm tấm miếng sườn nướng khổng lồ tẩm ướp đậm đà, bì thính, chả hấp, đồ chua giòn ngọt",
            "75.000đ - 145.000đ", "07:30 - 20:30", "028 3846 1073",
            4.7, 3190, False, None, "internal",
            "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80",
        ),
        # --- 2. TP. Đà Nẵng (2 nhà hàng) ---
        (
            9, 2,
            "Mì Quảng Bà Mua - Trần Bình Trọng (Đà Nẵng)",
            "19-21 Trần Bình Trọng, Quận Hải Châu, TP. Đà Nẵng",
            16.0642, 108.2215,
            "Đặc sản Xứ Quảng",
            "Mì Quảng tôm thịt trứng, Mì Quảng cá lóc, Bánh tráng cuốn thịt heo",
            "45.000đ - 95.000đ", "06:30 - 21:30", "0236 3821 999",
            4.7, 1650, False, None, "internal",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
        ),
        (
            10, 2,
            "Hải Sản Bé Mặn - Võ Nguyên Giáp (Biển Mỹ Khê)",
            "Lô 8 Võ Nguyên Giáp, Quận Sơn Trà, TP. Đà Nẵng",
            16.0715, 108.2468,
            "Hải sản tươi sống Đà Nẵng",
            "Tôm hùm nướng phô mai, Cua rang me, Mực hấp gừng, Chip chip hấp sả",
            "150.000đ - 450.000đ", "09:00 - 23:30", "0905 207 848",
            4.6, 2120, True, "Đối tác Ẩm thực Biển Đà Nẵng", "partner",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80",
        ),
        # --- 3. Thủ đô Hà Nội (2 nhà hàng dọc trục Hoàn Kiếm - Văn Miếu) ---
        (
            11, 3,
            "Phở Thìn Bờ Hồ - Đinh Tiên Hoàng",
            "61 Đinh Tiên Hoàng, Phường Lý Thái Tổ, Quận Hoàn Kiếm, Thủ đô Hà Nội",
            21.0294, 105.8532,
            "Phở Bò Hà Nội truyền thống",
            "Phở bò tái chín nước dùng trong vắt, ngọt thanh xương ống hầm gia truyền từ 1955",
            "60.000đ - 100.000đ", "06:00 - 22:00", "024 3825 2768",
            4.8, 3210, False, None, "internal",
            "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=900&q=80",
        ),
        (
            12, 3,
            "Bún Chả Hương Liên - Lê Văn Hưu",
            "24 Lê Văn Hưu, Phường Phan Chu Trinh, Quận Hai Bà Trưng, Thủ đô Hà Nội",
            21.0185, 105.8528,
            "Bún chả & Nem cua bể Hà Nội",
            "Bún chả nướng than hoa thơm lừng, nem hải sản, nem cua bể giòn rụm",
            "60.000đ - 120.000đ", "08:00 - 20:30", "024 3943 4106",
            4.7, 4520, False, None, "internal",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
        ),
        # --- 4. Quảng Ninh - Hạ Long (2 nhà hàng dọc trục Bãi Cháy - Hồng Gai) ---
        (
            13, 4,
            "Nhà hàng Hồng Hạnh 3 Hạ Long",
            "50 Hạ Long, Phường Bãi Cháy, TP. Hạ Long, Quảng Ninh",
            20.9532, 107.0585,
            "Hải sản & Đặc sản Vịnh Hạ Long",
            "Chả mực giã tay Hạ Long, Tôm hùm bông, Bề bề rang muối, Hàu nướng mỡ hành",
            "150.000đ - 400.000đ", "09:00 - 22:30", "0203 3812 345",
            4.8, 2890, True, "Đối tác Ẩm thực Vịnh Hạ Long", "partner",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80",
        ),
        (
            14, 4,
            "Bún Bề Bề & Chả Mực Làng Chài Hạ Long",
            "Đường Trần Quốc Nghiễn, Phường Hồng Gai, TP. Hạ Long, Quảng Ninh",
            20.9488, 107.0825,
            "Bún hải sản & Chả mực",
            "Bún bề bề tôm nõn, Bánh cuốn chả mực giã tay nóng hổi",
            "50.000đ - 110.000đ", "06:00 - 21:00", "0203 3658 999",
            4.7, 1540, False, None, "internal",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
        ),
        # --- 5. Lào Cai - Sa Pa (2 nhà hàng dọc trục Nhà thờ Đá - Bản Cát Cát - Fansipan) ---
        (
            15, 5,
            "Nhà hàng A Phủ Sa Pa - Fansipan",
            "15 Fansipan, Thị xã Sa Pa, Tỉnh Lào Cai",
            22.3325, 103.8402,
            "Đặc sản Dân tộc Tây Bắc",
            "Thắng cố ngựa Bắc Hà, Lẩu cá hồi vân Sa Pa, Lợn cắp nách nướng mắc khén, Gà đen nướng tiêu rừng",
            "120.000đ - 320.000đ", "09:00 - 23:00", "0214 3871 555",
            4.8, 2410, False, None, "internal",
            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80",
        ),
        (
            16, 5,
            "Lẩu Cá Hồi & Đồ Nướng Bản Mây Sa Pa",
            "086 Đường Cát Cát, Thị xã Sa Pa, Tỉnh Lào Cai",
            22.3292, 103.8358,
            "Lẩu Cá Hồi & Nướng Sa Pa",
            "Lẩu cá hồi tươi sống ăn kèm rau cải mèo, Cá tầm nướng, Cơm lam chấm muối vừng",
            "100.000đ - 280.000đ", "08:00 - 22:30", "0214 3872 888",
            4.7, 1690, False, None, "internal",
            "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80",
        ),
        # --- 6. Thừa Thiên Huế (2 nhà hàng dọc trục Đại Nội - Sông Hương) ---
        (
            17, 6,
            "Bún Bò Huế Mệ Kéo - Bạch Đằng",
            "20 Bạch Đằng, Phường Phú Cát, TP. Huế, Thừa Thiên Huế",
            16.4712, 107.5865,
            "Bún bò Huế gia truyền",
            "Bún bò Huế giò heo, chả cua, tiết luộc với nước dùng mắm ruốc sả thơm nồng hơn 70 năm",
            "45.000đ - 75.000đ", "06:00 - 11:00", "0234 3821 442",
            4.8, 2760, False, None, "internal",
            "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=900&q=80",
        ),
        (
            18, 6,
            "Quán Hạnh - Bánh Bèo Nậm Lọc Phó Đức Chính",
            "11 Phó Đức Chính, Phường Phú Hội, TP. Huế, Thừa Thiên Huế",
            16.4628, 107.5892,
            "Đặc sản Bánh Huế & Nem lụi",
            "Bánh bèo chén tôm chấy, Bánh nậm, Bánh bột lọc gói lá chuối, Nem lụi nướng sả",
            "50.000đ - 120.000đ", "09:00 - 21:30", "0234 3837 375",
            4.7, 3150, False, None, "internal",
            "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=900&q=80",
        ),
        # --- 7. Quảng Nam - Hội An (2 nhà hàng dọc trục Phố Cổ - Cẩm Thanh) ---
        (
            19, 7,
            "Cơm Gà Bà Buội Phố Cổ Hội An",
            "22 Phan Chu Trinh, Phường Minh An, TP. Hội An, Quảng Nam",
            15.8782, 108.3295,
            "Cơm gà Hội An gia truyền",
            "Cơm gà xé bóp hành tây, rau răm, đu đủ chua ăn kèm nước lòng gà nghệ vàng óng từ 1955",
            "55.000đ - 95.000đ", "10:00 - 21:00", "0235 3861 159",
            4.8, 3420, False, None, "internal",
            "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80",
        ),
        (
            20, 7,
            "Cao Lầu Không Gian Xanh Hội An",
            "687 Hai Bà Trưng, Phường Minh An, TP. Hội An, Quảng Nam",
            15.8778, 108.3272,
            "Cao lầu & Đặc sản Phố Hội",
            "Cao lầu sợi vàng dai giòn, thịt xá xíu, tóp mỡ giòn tan, Hoành thánh chiên & Bánh bao bánh vạc",
            "45.000đ - 90.000đ", "08:30 - 21:30", "0235 3919 289",
            4.7, 2190, False, None, "internal",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
        ),
        # --- 8. Khánh Hòa - Nha Trang (2 nhà hàng dọc trục Tháp Bà - trung tâm biển Nha Trang) ---
        (
            21, 8,
            "Nem Nướng Đặng Văn Quyên Nha Trang",
            "16A Lãn Ông, Phường Xương Huân, TP. Nha Trang, Khánh Hòa",
            12.2485, 109.1932,
            "Nem nướng Ninh Hòa",
            "Nem nướng lụi than hồng cuốn bánh tráng chiên giòn, xoài xanh, rau thơm và nước chấm nếp thịt bằm",
            "60.000đ - 120.000đ", "07:30 - 21:30", "0258 3826 737",
            4.7, 3680, False, None, "internal",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80",
        ),
        (
            22, 8,
            "Bún Cá Sứa Năm Beo Chợ Đầm",
            "B2 Chung cư Phan Bội Châu (Gần Chợ Đầm), TP. Nha Trang, Khánh Hòa",
            12.2535, 109.1925,
            "Bún chả cá sứa Nha Trang",
            "Bún cá dầm, chả cá thu chiên & hấp, sứa biển giòn sần sật với nước dùng cá biển ngọt thanh",
            "45.000đ - 75.000đ", "06:00 - 21:00", "0258 3814 290",
            4.8, 2140, False, None, "internal",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
        ),
        # --- 9. Lâm Đồng - Đà Lạt (2 nhà hàng dọc trục Hồ Xuân Hương - trung tâm Đà Lạt) ---
        (
            23, 9,
            "Lẩu Gà Lá É Tao Ngộ Đà Lạt",
            "05 Đường 3 Tháng 4, Phường 3, TP. Đà Lạt, Lâm Đồng",
            11.9362, 108.4485,
            "Đặc sản Lẩu phố núi Đà Lạt",
            "Lẩu gà ta chặt miếng nấu măng tươi, nấm bào ngư và lá é the mát chấm muối ớt xanh",
            "150.000đ - 300.000đ", "08:00 - 22:30", "0263 3521 666",
            4.8, 4290, False, None, "internal",
            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80",
        ),
        (
            24, 9,
            "Bánh Căn Lệ Yersin Đà Lạt",
            "27/44 Yersin, Phường 10, TP. Đà Lạt, Lâm Đồng",
            11.9438, 108.4492,
            "Bánh căn & Ẩm thực sáng Đà Lạt",
            "Bánh căn khuôn đất nung nhân trứng cút, bò bằm ăn kèm nước mắm xíu mại viên nóng hổi",
            "40.000đ - 75.000đ", "06:30 - 16:30", "0263 3812 889",
            4.7, 2510, False, None, "internal",
            "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=900&q=80",
        ),
        # --- 10. Kiên Giang - Phú Quốc (2 nhà hàng dọc trục Dương Đông - Dinh Cậu) ---
        (
            25, 10,
            "Bún Quậy Kiến Xây Dương Đông Phú Quốc",
            "28 Bạch Đằng, Phường Dương Đông, TP. Phú Quốc, Kiên Giang",
            10.2215, 103.9612,
            "Đặc sản Bún quậy Phú Quốc",
            "Bún tươi ép tại chỗ ăn cùng chả tôm, chả cá, mực trứng tươi ngọt và chén muối ớt tắc tự quậy",
            "60.000đ - 95.000đ", "06:30 - 23:00", "0297 3847 999",
            4.8, 3890, False, None, "internal",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
        ),
        (
            26, 10,
            "Nhà hàng Ra Khơi - Gỏi Cá Trích Phú Quốc",
            "131 Đường 30 Tháng 4, Phường Dương Đông, TP. Phú Quốc, Kiên Giang",
            10.2128, 103.9648,
            "Hải sản & Gỏi cá trích Đảo Ngọc",
            "Gỏi cá trích cuốn dừa nạo rau rừng chấm nước mắm Phú Quốc, Nhum biển nướng mỡ hành, Ghẹ Hàm Ninh",
            "120.000đ - 380.000đ", "09:00 - 23:00", "0297 3980 111",
            4.7, 3120, True, "Đối tác Ẩm thực Biển Đảo Phú Quốc", "partner",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80",
        ),
    ]

    existing_rest_names = {r.name for r in db.query(Restaurant).all()}
    existing_rest_ids = {r.id for r in db.query(Restaurant).all()}

    RESTAURANT_REVIEWS_MAP = {
        1: {
            "reviews_count": 1840,
            "specialties": "Cơm gia đình miền Nam, rau luộc kho quẹt, đậu hũ chiên sả",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Phương Linh", "rating": 5.0, "text": "Không gian mộc mạc hoài niệm, món ăn vị thanh đượm chất cơm mẹ nấu thời xưa.", "relative_time": "2 tuần trước"},
                {"author": "Thái An", "rating": 4.5, "text": "Rau luộc kho quẹt và canh chua cá lóc đậm đà vừa miệng, nhân viên nhẹ nhàng chu đáo.", "relative_time": "1 tháng trước"},
            ],
        },
        2: {
            "reviews_count": 5240,
            "specialties": "Bánh mì pate bơ thịt nguội đặc ruột khổng lồ",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Quốc Huy", "rating": 5.0, "text": "Bánh mì ngập tràn pate bơ béo ngậy và thịt nguội hảo hạng, vỏ bánh giòn tan rụm.", "relative_time": "1 tuần trước"},
                {"author": "Hồng Ánh", "rating": 4.5, "text": "Một ổ bánh mì nửa ký ăn được hai người, vị pate gia truyền thơm nức mũi không nơi nào sánh bằng.", "relative_time": "2 tuần trước"},
            ],
        },
        3: {
            "reviews_count": 2180,
            "specialties": "Bánh xèo tôm nhảy giòn rụm, cơm chiên trái dừa thơm béo",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Thu Trang", "rating": 5.0, "text": "Món bánh xèo cuốn rau rừng giòn thơm, nước chấm chua ngọt pha rất khéo.", "relative_time": "3 tuần trước"},
                {"author": "Khánh Duy", "rating": 4.5, "text": "Quán đạt danh hiệu Michelin Bib Gourmand hoàn toàn xứng đáng, phục vụ nhanh dù đông khách.", "relative_time": "1 tháng trước"},
            ],
        },
        4: {
            "reviews_count": 3210,
            "specialties": "Bánh khọt Vũng Tàu giòn rụm, gỏi ngó sen tôm thịt, hủ tiếu",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Minh Khang", "rating": 4.5, "text": "Thực đơn hội tụ tinh hoa ẩm thực ba miền, không gian biệt thự cổ rất thoáng đãng.", "relative_time": "2 tuần trước"},
                {"author": "Thanh Hà", "rating": 4.5, "text": "Các quầy chế biến trực tiếp sạch sẽ, món bánh khọt và chả giò ăn rất tròn vị.", "relative_time": "1 tháng trước"},
            ],
        },
        5: {
            "reviews_count": 1950,
            "specialties": "Bánh xèo chảo gang vỏ giòn rụm, tôm đất thịt ba rọi",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Gia Huy", "rating": 4.5, "text": "Bánh xèo khổng lồ tráng chảo gang mỏng tang giòn rụm, rau rừng ăn kèm phong phú tươi non.", "relative_time": "2 tuần trước"},
                {"author": "Ngọc Trâm", "rating": 4.5, "text": "Tôm đất ngọt thịt và nước mắm chấm cay thơm chuẩn vị miền Tây Nam Bộ.", "relative_time": "3 tuần trước"},
            ],
        },
        6: {
            "reviews_count": 4120,
            "specialties": "Phở bò tái nạm gia truyền, quẩy giòn miền Nam",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Hoàng Nam", "rating": 5.0, "text": "Nước dùng phở ngọt thanh xương hầm, thịt mềm thơm, quẩy giòn rụm chấm nước phở béo rất tuyệt.", "relative_time": "2 tuần trước"},
                {"author": "Thanh Trúc", "rating": 4.5, "text": "Quán phở lâu đời ở Sài Gòn, đĩa rau thơm phong phú và tương đen gia truyền rất ngon.", "relative_time": "1 tháng trước"},
            ],
        },
        7: {
            "reviews_count": 1680,
            "specialties": "Hủ tiếu Nam Vang khô tỏi phi thơm, gan heo lòng tươi",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Văn Hùng", "rating": 4.5, "text": "Tô hủ tiếu khô trộn sốt tỏi phi thơm lừng, tôm tươi giòn và nước súp ngọt tôm khô hầm.", "relative_time": "3 tuần trước"},
                {"author": "Thục Quyên", "rating": 4.5, "text": "Sợi hủ tiếu dai dai không bở, tô súp sườn và gan cật làm rất sạch không bị tanh.", "relative_time": "1 tháng trước"},
            ],
        },
        8: {
            "reviews_count": 3890,
            "specialties": "Cơm tấm miếng sườn khổng lồ nướng than hồng, bì chả",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Minh Khôi", "rating": 5.0, "text": "Miếng sườn to đùng che kín cả đĩa cơm, tẩm ướp đậm đà nướng than hồng thơm phức nức mũi.", "relative_time": "3 tuần trước"},
                {"author": "Thảo Vy", "rating": 4.5, "text": "Hạt gạo tấm tơi xốp, bì giòn thính thơm, mỡ hành béo ngậy. Ăn một dĩa sườn bì no tới chiều.", "relative_time": "1 tháng trước"},
            ],
        },
        9: {
            "reviews_count": 2340,
            "specialties": "Mì Quảng tôm thịt trứng, bánh tráng nướng mè",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Trần Tuấn", "rating": 5.0, "text": "Mì quảng chuẩn vị Đà Nẵng, nước nhưn đậm đà, sợi mì vàng tươi dai ngon ăn kèm bánh tráng mè nướng.", "relative_time": "2 tuần trước"},
                {"author": "Lê Hà", "rating": 4.5, "text": "Quán sạch sẽ, rau sống búp chuối tươi non, thịt gà ta dai ngọt.", "relative_time": "1 tháng trước"},
            ],
        },
        10: {
            "reviews_count": 3450,
            "specialties": "Hải sản tươi sống bắt tại hồ, tôm hùm, cua rang me",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Đình Phong", "rating": 5.0, "text": "Hải sản sống bơi trong bể được cân ký công khai, nướng phô mai và rang me cực ngon.", "relative_time": "1 tuần trước"},
                {"author": "Lan Anh", "rating": 4.5, "text": "Không gian view biển Mỹ Khê lộng gió, chế biến nhanh và giá cả niêm yết rõ ràng.", "relative_time": "3 tuần trước"},
            ],
        },
        11: {
            "reviews_count": 3210,
            "specialties": "Phở bò tái lăn gia truyền, nước dùng trong vắt ngọt xương",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Nguyễn Duy", "rating": 5.0, "text": "Hương vị phở phố cổ Hà Nội đích thực, nước dùng ngọt thanh vị xương hầm không hề lạm dụng mì chính.", "relative_time": "1 tuần trước"},
                {"author": "Vũ Thu", "rating": 4.5, "text": "Thịt bò tươi mềm thơm nức mũi, hành hoa rợp bát, không gian phố cổ hoài niệm.", "relative_time": "3 tuần trước"},
            ],
        },
        12: {
            "reviews_count": 4520,
            "specialties": "Bún chả nướng than hoa Obama, nem cua bể giòn rụm",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Đức Anh", "rating": 5.0, "text": "Chả nướng than hoa thơm lừng chấm cùng nước mắm chua ngọt ấm nóng, nem cua bể vỏ giòn tan nhân đầy đặn.", "relative_time": "2 tuần trước"},
                {"author": "Mai Chi", "rating": 4.5, "text": "Quán nổi tiếng từng đón Tổng thống Obama, chả băm và chả miếng đều rất vừa miệng.", "relative_time": "1 tháng trước"},
            ],
        },
        13: {
            "reviews_count": 3150,
            "specialties": "Chả mực giã tay giòn sần sật, bề bề rang muối",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Tuấn Hưng", "rating": 5.0, "text": "Chả mực giã tay tươi rói ăn giòn sần sật, đồ hải sản tươi rói nhìn thẳng ra vịnh Hạ Long.", "relative_time": "1 tuần trước"},
                {"author": "Cẩm Ly", "rating": 4.5, "text": "Món lẩu hải sản đầy ắp bề bề, mực và tôm tươi. Phục vụ chuyên nghiệp và chu đáo.", "relative_time": "3 tuần trước"},
            ],
        },
        14: {
            "reviews_count": 1980,
            "specialties": "Bún bề bề tôm nõn, bánh cuốn chả mực giã tay nóng hổi",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Đăng Khoa", "rating": 4.5, "text": "Bát bún bề bề đầy đặn, nước dùng ngọt tự nhiên từ ghẹ tôm biển, ăn sáng nhìn biển rất chill.", "relative_time": "2 tuần trước"},
                {"author": "Ánh Tuyết", "rating": 4.5, "text": "Bánh cuốn tráng mỏng mềm mướt ăn kèm miếng chả mực nóng hổi chấm nước mắm ớt tuyệt đỉnh.", "relative_time": "1 tháng trước"},
            ],
        },
        15: {
            "reviews_count": 2840,
            "specialties": "Thắng cố ngựa Bắc Hà, gà đen nướng mắc khén Sa Pa",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Hoàng Long", "rating": 5.0, "text": "Thắng cố nấu rất sạch thơm mùi hạt dổi thảo quả, lợn bản nướng mắc khén da giòn rụm.", "relative_time": "1 tuần trước"},
                {"author": "Mỹ Hạnh", "rating": 4.5, "text": "Không gian quán ấm cúng giữa tiết trời Sa Pa mù sương, rượu táo mèo nhâm nhi cực kỳ hợp.", "relative_time": "3 tuần trước"},
            ],
        },
        16: {
            "reviews_count": 2120,
            "specialties": "Lẩu cá hồi vân Sa Pa, cá tầm nướng muối ớt",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Hữu Phước", "rating": 4.5, "text": "Cá hồi phi lê tươi rói nhúng lẩu chua cay ăn kèm rau cải mèo Sa Pa ngọt mát, thịt cá béo ngọt.", "relative_time": "2 tuần trước"},
                {"author": "Yến Nhi", "rating": 4.5, "text": "Cá tầm nướng than thơm phức, nước lẩu đậm đà, nhân viên phục vụ rất nhiệt tình.", "relative_time": "1 tháng trước"},
            ],
        },
        17: {
            "reviews_count": 2960,
            "specialties": "Bún bò Huế giò heo, chả cua mắm ruốc sả nồng",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Văn Tiến", "rating": 5.0, "text": "Tô bún bò mệ Kéo thơm lừng mùi mắm ruốc và sả ớt, miếng chả cua ngọt lịm đậm đà phong vị Cố Đô.", "relative_time": "2 tuần trước"},
                {"author": "Thanh Thủy", "rating": 4.5, "text": "Ăn một lần nhớ mãi không quên, nước dùng cay the kích thích vị giác vô cùng.", "relative_time": "1 tháng trước"},
            ],
        },
        18: {
            "reviews_count": 3380,
            "specialties": "Bánh bèo chén tôm chấy, bánh nậm lọc gói lá chuối",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Nhật Minh", "rating": 5.0, "text": "Bánh bèo chén bột dẻo tôm chấy đỏ cam thơm ngọt, nem lụi cuốn bánh tráng rau sống rất ngon.", "relative_time": "1 tuần trước"},
                {"author": "Diệu Thảo", "rating": 4.5, "text": "Quán bánh Huế gia truyền nổi tiếng, các loại bánh nậm lọc trong veo dẻo dai chấm nước mắm ngọt.", "relative_time": "3 tuần trước"},
            ],
        },
        19: {
            "reviews_count": 3640,
            "specialties": "Cơm gà xé bóp nghệ rau răm, nước lòng gà nghệ vàng óng",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Bảo An", "rating": 5.0, "text": "Cơm gà hạt vàng óng thơm mùi nước luộc gà, thịt gà xé dai ngọt bóp hành tây giòn chua dịu.", "relative_time": "1 tuần trước"},
                {"author": "Minh Trang", "rating": 4.5, "text": "Thương hiệu cơm gà lâu đời nhất phố cổ Hội An, nước chấm lòng gà đậm đà trứ danh.", "relative_time": "2 tuần trước"},
            ],
        },
        20: {
            "reviews_count": 2450,
            "specialties": "Cao lầu Hội An tóp mỡ giòn rụm, thịt xá xíu thơm",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Quang Dũng", "rating": 4.5, "text": "Sợi cao lầu màu vàng tro dai sần sật, tóp mỡ chiên giòn tan ăn cùng thịt xá xíu ngấm vị.", "relative_time": "2 tuần trước"},
                {"author": "Kim Oanh", "rating": 4.5, "text": "Không gian xanh mát giữa lòng phố cổ, món hoành thánh chiên cũng rất giòn ngon.", "relative_time": "1 tháng trước"},
            ],
        },
        21: {
            "reviews_count": 3890,
            "specialties": "Nem nướng Ninh Hòa cuốn bánh tráng chiên giòn, nước chấm nếp thịt bằm",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Tấn Lộc", "rating": 5.0, "text": "Nem nướng than hồng thơm nức cuộn rau sống xoài xanh và nước chấm tương nếp gia truyền béo ngậy.", "relative_time": "1 tuần trước"},
                {"author": "Bích Phượng", "rating": 4.5, "text": "Một phần nem nướng đầy đặn ăn no nê, bánh tráng chiên giòn rụm kết hợp nước chấm độc nhất vô nhị.", "relative_time": "3 tuần trước"},
            ],
        },
        22: {
            "reviews_count": 2380,
            "specialties": "Bún cá dầm, sứa biển giòn sần sật chả cá thu chiên",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Hải Nam", "rating": 5.0, "text": "Sứa biển tươi trong veo cắn vào giòn sần sật mát lạnh, nước dùng trong ngọt thanh vị cá cờ cá thu.", "relative_time": "2 tuần trước"},
                {"author": "Huyền My", "rating": 4.5, "text": "Quán bún cá nổi tiếng Chợ Đầm Nha Trang, chả cá chiên dai thơm không bột, ăn kèm ớt sim cay nồng.", "relative_time": "1 tháng trước"},
            ],
        },
        23: {
            "reviews_count": 4290,
            "specialties": "Lẩu gà lá é chua cay, măng chua ớt xiêm xanh",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Bảo Trâm", "rating": 5.0, "text": "Trời Đà Lạt se lạnh húp xì xụp nồi lẩu gà lá é cay nồng thì tuyệt đỉnh, thịt gà chắc ngọt.", "relative_time": "1 tuần trước"},
                {"author": "Tuấn Kiệt", "rating": 4.5, "text": "Lá é tươi thơm đặc trưng kết hợp ớt xiêm xanh và măng chua, nước lẩu ngọt lịm khó quên.", "relative_time": "3 tuần trước"},
            ],
        },
        24: {
            "reviews_count": 2750,
            "specialties": "Bánh căn trứng cút xíu mại mỡ hành chén ngập dầu",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Thu Thảo", "rating": 5.0, "text": "Bánh căn nướng khuôn đất giòn đáy xốp mặt, chén xíu mại hành hoa béo ngậy chấm ngập bánh nóng hổi.", "relative_time": "2 tuần trước"},
                {"author": "Đức Trọng", "rating": 4.5, "text": "Quán bánh căn ruột mỗi lần lên Đà Lạt, xoài băm chua chua ăn kèm giải ngấy rất chuẩn.", "relative_time": "1 tháng trước"},
            ],
        },
        25: {
            "reviews_count": 3890,
            "specialties": "Bún quậy tôm mực tươi ép tại chỗ, muối ớt tắc tự quậy",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Hải Đăng", "rating": 5.0, "text": "Bún tươi ép nóng hổi tại chỗ, chả tôm mực giòn sần sật ngọt lịm, tự pha chén nước chấm muối tắc theo khẩu vị cực kỳ thú vị.", "relative_time": "1 tuần trước"},
                {"author": "Ngọc Mai", "rating": 4.5, "text": "Nước dùng thanh ngọt nguyên chất hải sản, ăn nóng hổi giữa không gian gió biển đảo ngọc Phú Quốc.", "relative_time": "2 tuần trước"},
            ],
        },
        26: {
            "reviews_count": 3420,
            "specialties": "Gỏi cá trích Phú Quốc cuốn dừa nạo, nhum biển nướng mỡ hành",
            "is_high_rated": True,
            "sample_reviews": [
                {"author": "Trung Kiên", "rating": 5.0, "text": "Gỏi cá trích tươi rói cuốn bánh tráng, dừa nạo rau rừng chấm nước mắm Phú Quốc sánh đặc ngon ngất ngây.", "relative_time": "1 tuần trước"},
                {"author": "Hương Giang", "rating": 4.5, "text": "Hải sản tươi sống đa dạng, nhum biển nướng trứng và ghẹ Hàm Ninh rất chắc thịt.", "relative_time": "3 tuần trước"},
            ],
        },
    }

    for (
        r_id, prov_id, name, addr, lat, lng, cuisine, dishes,
        price, hours, phone, rating, rev_cnt, sponsored, sp_label, source, img_url
    ) in raw_restaurants:
        if name in existing_rest_names or r_id in existing_rest_ids:
            continue
        extra_info = RESTAURANT_REVIEWS_MAP.get(r_id, {})
        actual_reviews_count = extra_info.get("reviews_count", rev_cnt or 120)
        actual_is_high_rated = extra_info.get("is_high_rated", True)
        actual_specialties = extra_info.get("specialties", dishes)
        actual_sample_reviews = json.dumps(extra_info.get("sample_reviews", []), ensure_ascii=False)

        db.add(
            Restaurant(
                id=r_id,
                province_id=prov_id,
                name=name,
                address=addr,
                latitude=lat,
                longitude=lng,
                cuisine_type=cuisine,
                specialty_dishes=dishes,
                specialties=actual_specialties,
                price_range=price,
                opening_hours=hours,
                contact_phone=phone,
                rating=rating,
                review_count=rev_cnt,
                reviews_count=actual_reviews_count,
                sample_reviews_json=actual_sample_reviews,
                is_high_rated=actual_is_high_rated,
                image_url=cloudinary_service.build_detail_url(img_url),
                thumbnail_url=cloudinary_service.build_thumbnail_url(img_url),
                is_sponsored=sponsored,
                sponsor_label=sp_label,
                is_verified=True,
                source="admin",
                source_url=None,
                status="published",
                data_source=source,
                last_updated_at=now,
            )
        )
    db.flush()

    # Đồng bộ cập nhật các cột mới cho toàn bộ nhà hàng hiện có trong database
    for r in db.query(Restaurant).all():
        extra = RESTAURANT_REVIEWS_MAP.get(r.id)
        if extra:
            r.reviews_count = extra["reviews_count"]
            r.is_high_rated = extra.get("is_high_rated", True)
            r.specialties = extra.get("specialties", r.specialty_dishes)
            r.sample_reviews_json = json.dumps(extra.get("sample_reviews", []), ensure_ascii=False)
        else:
            if not getattr(r, "reviews_count", None):
                r.reviews_count = r.review_count or 120
            if getattr(r, "is_high_rated", None) is None:
                r.is_high_rated = bool(r.rating >= 4.2 and r.reviews_count >= 50)
            if not getattr(r, "specialties", None):
                r.specialties = r.specialty_dishes
    db.commit()

    # --------------------------------------------------------------------
    # 4. ĐẢM BẢO ĐỦ 24 ĐẶC SẢN ĐỊA PHƯƠNG TRÊN 10 TỈNH/THÀNH
    # --------------------------------------------------------------------
    raw_foods = [
        # --- 1. TP. Hồ Chí Minh (6 đặc sản) ---
        (
            1, 1,
            "Cơm tấm Sài Gòn (Sườn - Bì - Chả)",
            "Linh hồn ẩm thực của người Sài Gòn từ sáng sớm tới đêm khuya. Hạt gạo tấm dẻo thơm ăn kèm sườn cốt lết nướng than hồng vàng óng, bì heo trộn thính, chả trứng chưng và nước mắm kẹo chua ngọt.",
            "Bắt nguồn từ bữa ăn dân dã của người nông dân đồng bằng sông Cửu Long và công nhân bến cảng Sài Gòn xưa, nay đã trở thành biểu tượng ẩm thực được vinh danh quốc tế.",
            "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80",
            "Quanh năm (Ngon nhất vào bữa sáng 07:00 - 09:30 hoặc bữa trưa)",
            "45.000đ - 120.000đ",
            [1, 8, 3, 4],
        ),
        (
            2, 1,
            "Bánh mì Sài Gòn đặc ruột giòn rụm",
            "Ổ bánh mì nướng vỏ mỏng giòn tan, ruột mềm xốp, phết lớp bơ trứng gà béo ngậy và pate gan thơm lừng, kẹp đầy đặn thịt nguội, chả lụa, xíu mại, đồ chua củ cải cà rốt.",
            "Từ chiếc bánh baguette du nhập vào Sài Gòn cuối thế kỷ 19, người dân địa phương đã biến tấu thành món ăn đường phố đưa danh từ 'Bánh Mì' vào từ điển Oxford.",
            "https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=900&q=80",
            "Quanh năm (Bữa sáng nhanh gọn hoặc xế chiều 15:00 - 21:00)",
            "25.000đ - 70.000đ",
            [2, 4],
        ),
        (
            3, 1,
            "Hủ tiếu Nam Vang (Khô & Nước)",
            "Sợi hủ tiếu dai mềm trụng vừa tới, nổi bật với phiên bản Hủ tiếu khô trộn sốt xì dầu đậm đà kèm tô nước dùng ninh xương ống ngọt thanh, tôm sú tươi, thịt bằm, trứng cút.",
            "Món ăn giao thoa văn hóa ẩm thực Khmer - Hoa - Việt được người Sài Gòn tinh chỉnh vị nước lèo trong vắt, ngọt dịu tự nhiên từ xương heo và mực khô nướng.",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
            "Quanh năm (Bữa sáng 06:30 - 10:00 hoặc ăn đêm 19:00 - 23:00)",
            "55.000đ - 95.000đ",
            [7, 4],
        ),
        (
            4, 1,
            "Bánh xèo miền Nam rau rừng",
            "Chiếc bánh xèo vàng nghệ rộng vành tráng mỏng trên chảo gang lửa lớn, viền bánh giòn rụm, nhân tôm đất, thịt ba rọi, đậu xanh nguyên vỏ ăn kèm hơn 10 loại rau rừng.",
            "Tên gọi 'bánh xèo' bắt nguồn từ âm thanh 'xèo... xèo...' vui tai khi đổ bột gạo pha nước cốt dừa vào chảo gang nóng già.",
            "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=900&q=80",
            "Ngon nhất vào những buổi chiều tối mát trời tại Sài Gòn",
            "75.000đ - 150.000đ",
            [5, 3, 4],
        ),
        (
            5, 1,
            "Phở Sài Gòn kèm tương đen & rau thơm",
            "Tô Phở Sài Gòn có nước dùng đậm hương thảo quả, hồi, quế, hơi ngọt hậu từ xương bò hầm, luôn dọn kèm đĩa rau quế, ngò gai, giá trụng đầy đặn và tương đen gia truyền.",
            "Phát triển thành phong cách Phở miền Nam đặc trưng dọc trục đường Pasteur Quận 1 - Quận 3 từ thập niên 1950.",
            "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=900&q=80",
            "Quanh năm (Đặc biệt vào buổi sáng sớm từ 06:00)",
            "65.000đ - 110.000đ",
            [6, 4],
        ),
        (
            6, 1,
            "Cà phê sữa đá & Cà phê vợt Sài Gòn",
            "Ly cà phê pha phin hoặc pha bằng vợt vải truyền thống hòa quyện cùng sữa đặc ngọt béo và đá viên mát lạnh — thức uống mở đầu ngày mới tràn đầy năng lượng.",
            "Cà phê vợt có tuổi đời hơn 70 năm tại các con hẻm Phú Nhuận và Chợ Lớn, trong khi cà phê bệt quanh Công xã Paris là nét văn hóa giao lưu phóng khoáng.",
            "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=900&q=80",
            "Buổi sáng 07:00 - 10:30",
            "20.000đ - 55.000đ",
            [4, 3],
        ),
        # --- 2. TP. Đà Nẵng (2 đặc sản) ---
        (
            7, 2,
            "Mì Quảng Tôm Thịt Trứng Cút Đà Nẵng",
            "Sợi mì gạo tráng dày màu trắng hoặc vàng nghệ chan lượng nước nhân đậm đà vừa xâm xấp, ăn kèm bánh tráng mè nướng giòn, đậu phộng rang và rau sống Trà Quế.",
            "Niềm tự hào ẩm thực của người dân xứ Quảng - Đà Nẵng trong mọi dịp lễ tết và đãi khách phương xa.",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
            "Bữa sáng và bữa trưa (06:30 - 14:00)",
            "40.000đ - 85.000đ",
            [9],
        ),
        (
            8, 2,
            "Bánh Tráng Cuốn Thịt Heo Hai Đầu Da",
            "Thịt heo luộc khéo léo giữ hai đầu mỡ da trong veo, cuốn cùng bánh tráng phơi sương, mì lá và rau sống chấm mắm nêm cá cơm thơm nồng.",
            "Đặc sản trứ danh của thành phố biển Đà Nẵng kết hợp vị ngọt của thịt heo và vị mặn mòi của mắm nêm miền Trung.",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80",
            "Quanh năm (Trưa và tối)",
            "75.000đ - 150.000đ",
            [9, 10],
        ),
        # --- 3. Thủ đô Hà Nội (2 đặc sản) ---
        (
            9, 3,
            "Phở Bò Gia Truyền Hà Nội",
            "Tô phở Bắc chuẩn vị với nước dùng trong vắt ninh từ xương ống bò và gừng nướng, bánh phở mềm mỏng, thịt bò tái chín thái bản to ăn kèm quẩy giòn và hành lá.",
            "Tinh hoa ẩm thực đất Kinh kỳ gắn liền với những gánh phở phố cổ Hoàn Kiếm từ đầu thế kỷ 20.",
            "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=900&q=80",
            "Bữa sáng sớm (06:00 - 10:00) hoặc tối se lạnh",
            "55.000đ - 100.000đ",
            [11],
        ),
        (
            10, 3,
            "Bún Chả Hà Nội & Nem Cua Bể",
            "Thịt ba chỉ và chả viên ướp đậm đà kẹp tre nướng trên than hoa thơm nức, thả ngập trong bát nước chấm chua ngọt ấm nóng cùng đu đủ xanh và bún rối.",
            "Món ăn trứ danh của Thủ đô Hà Nội làm say lòng du khách và các nguyên thủ quốc tế.",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
            "Bữa trưa (10:30 - 14:30)",
            "60.000đ - 120.000đ",
            [12],
        ),
        # --- 4. Quảng Ninh - Hạ Long (2 đặc sản) ---
        (
            11, 4,
            "Chả Mực Giã Tay Hạ Long",
            "Những miếng chả mực vàng ruộm được giã tay thủ công từ mực nang tươi đánh bắt tại vịnh Hạ Long, giữ trọn độ giòn sần sật và vị ngọt tự nhiên của biển.",
            "Đặc sản nằm trong Top 50 món ăn nổi tiếng nhất Việt Nam, thường ăn kèm bánh cuốn nóng hoặc xôi trắng.",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80",
            "Quanh năm (Sáng và trưa)",
            "60.000đ - 150.000đ",
            [13, 14],
        ),
        (
            12, 4,
            "Bún Bề Bề Hải Sản Vịnh Hạ Long",
            "Tô bún đầy ắp bề bề (tôm tích) bóc nõn chắc thịt, tôm biển, chả mực và đậu phụ chiên, chan nước dùng ninh từ đầu tôm và xương ngọt lịm.",
            "Món ăn sáng và ăn trưa đặc trưng của ngư dân và du khách khi ghé thăm phố biển Hạ Long.",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
            "Bữa sáng (06:00 - 11:00)",
            "50.000đ - 95.000đ",
            [14, 13],
        ),
        # --- 5. Lào Cai - Sa Pa (2 đặc sản) ---
        (
            13, 5,
            "Lẩu Cá Hồi Vân & Cá Tầm Sa Pa",
            "Cá hồi vân nuôi bằng nguồn nước suối lạnh dưới chân đỉnh Fansipan có thớ thịt hồng cam săn chắc, ít mỡ, nhúng lẩu chua cay ăn kèm rau cải mèo và nấm hương rừng.",
            "Nét ẩm thực giao thoa độc đáo của vùng núi cao ôn đới Sa Pa trong tiết trời sương mù se lạnh.",
            "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80",
            "Buổi tối se lạnh tại Sa Pa",
            "250.000đ - 500.000đ/nồi",
            [15, 16],
        ),
        (
            14, 5,
            "Thắng Cố & Thịt Lợn Cắp Nách Nướng Tây Bắc",
            "Món ăn truyền thống lâu đời của đồng bào H'Mông nấu cùng 12 loại gia vị thảo quả, hạt dổi, mắc khén núi rừng, dùng kèm thịt lợn bản nướng giòn bì.",
            "Xuất phát từ các phiên chợ vùng cao Bắc Hà - Sa Pa, mang đậm hương vị núi rừng Tây Bắc.",
            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80",
            "Quanh năm (Đặc biệt vào mùa đông và phiên chợ cuối tuần)",
            "120.000đ - 300.000đ",
            [15, 16],
        ),
        # --- 6. Thừa Thiên Huế (2 đặc sản) ---
        (
            15, 6,
            "Bún Bò Huế Cố Đô",
            "Sợi bún nhỏ vừa ăn chan nước dùng ninh xương bò hòa quyện mắm ruốc Huế và sả cây thơm lừng, ăn kèm bắp bò, giò heo, chả cua và rau sống thái nhỏ.",
            "Di sản ẩm thực trứ danh của đất Thần Kinh được lưu truyền qua nhiều thế hệ nghệ nhân nấu bún.",
            "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=900&q=80",
            "Buổi sáng (06:00 - 10:30)",
            "40.000đ - 75.000đ",
            [17],
        ),
        (
            16, 6,
            "Bánh Bèo - Nậm - Lọc & Cơm Hến Xứ Huế",
            "Những chén bánh bèo bột gạo mềm mịn rắc tôm chấy đỏ au, bánh nậm gói lá dong thanh tao và bánh bột lọc nhân tôm thịt rim mặn ngọt.",
            "Phản ánh sự cầu kỳ, tinh tế trong nghệ thuật chế biến món ăn của người phụ nữ Cố đô Huế.",
            "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=900&q=80",
            "Xế chiều và buổi tối (14:00 - 21:00)",
            "45.000đ - 100.000đ",
            [18],
        ),
        # --- 7. Quảng Nam - Hội An (2 đặc sản) ---
        (
            17, 7,
            "Cao Lầu Phố Cổ Hội An",
            "Sợi mì vàng ươm dai giòn được nhào từ bột gạo ngâm nước tro củi Cù Lao Chàm và nước giếng Bá Lễ, trộn cùng thịt xá xíu, giá trụng và rau sống Trà Quế.",
            "Món ăn độc nhất vô nhị gắn liền với lịch sử giao thương cảng thị quốc tế Hội An từ thế kỷ XVII.",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
            "Trưa và tối khi dạo phố cổ Hội An",
            "40.000đ - 75.000đ",
            [20, 19],
        ),
        (
            18, 7,
            "Cơm Gà Xé Phố Hội",
            "Hạt cơm nấu bằng nước luộc gà và lá dứa dậy mùi thơm cùng sắc vàng nghệ bắt mắt, trộn gỏi gà ta thả vườn xé phay, hành tây, rau răm và tương ớt rim Hội An.",
            "Từ những gánh cơm gà đêm nơi góc phố Phan Chu Trinh, nay đã trở thành thương hiệu ẩm thực toàn cầu của Hội An.",
            "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80",
            "Bữa trưa và bữa tối (10:30 - 21:00)",
            "50.000đ - 90.000đ",
            [19, 20],
        ),
        # --- 8. Khánh Hòa - Nha Trang (2 đặc sản) ---
        (
            19, 8,
            "Nem Nướng Ninh Hòa Nha Trang",
            "Thịt heo quết mịn nướng trên than hồng thơm phức, cuốn cùng bánh tráng chiên giòn rụm, rau sống, xoài chua và chấm ngập trong bát nước tương nếp nấu tôm thịt béo bùi.",
            "Đặc sản gốc vùng Ninh Hòa (Khánh Hòa) làm nên sức hút ẩm thực không thể chối từ tại phố biển Nha Trang.",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80",
            "Trưa và chiều tối (10:00 - 21:30)",
            "55.000đ - 110.000đ",
            [21],
        ),
        (
            20, 8,
            "Bún Chả Cá Sứa Nha Trang",
            "Nước dùng trong veo nấu từ xương cá cờ và cá thu không hề tanh, kết hợp những miếng sứa biển trắng giòn sần sật và chả cá Nha Trang dai ngọt.",
            "Hương vị đại dương thanh mát mở đầu ngày mới của người dân xứ Trầm Hương.",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
            "Buổi sáng (06:00 - 10:30)",
            "40.000đ - 70.000đ",
            [22],
        ),
        # --- 9. Lâm Đồng - Đà Lạt (2 đặc sản) ---
        (
            21, 9,
            "Lẩu Gà Lá É Đà Lạt",
            "Nồi lẩu gà ta thả đồi nấu cùng măng củ giòn ngọt và nắm lá é trắng nhúng tái tỏa hương thơm the mát như sả chanh, xua tan cái lạnh phố núi.",
            "Món ăn hội tụ hương vị thảo mộc vùng cao nguyên Lâm Viên khiến mọi du khách đến Đà Lạt đều tìm thưởng thức.",
            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80",
            "Buổi trưa và buổi tối se lạnh (11:00 - 22:00)",
            "150.000đ - 300.000đ",
            [23],
        ),
        (
            22, 9,
            "Bánh Căn Trứng Cút & Xíu Mại Đà Lạt",
            "Những cặp bánh căn bột gạo nướng giòn nóng hổi trên khuôn đất nung, chấm cùng chén nước mắm hành mỡ pha xíu mại thịt viên béo mềm.",
            "Thức quà sáng bình dị bên bếp than hồng sưởi ấm những con dốc mờ sương Đà Lạt.",
            "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=900&q=80",
            "Buổi sáng sớm (06:30 - 11:00)",
            "40.000đ - 75.000đ",
            [24],
        ),
        # --- 10. Kiên Giang - Phú Quốc (2 đặc sản) ---
        (
            23, 10,
            "Bún Quậy Kiến Xây Phú Quốc",
            "Tô bún độc đáo với sợi bún gạo ép trực tiếp vào nồi nước sôi, chả tôm và chả cá tươi quết quanh thành tô chín tái bằng nước lèo nóng hổi, chấm muối ớt đường tắc tự quậy.",
            "Sáng tạo ẩm thực trứ danh tại thị trấn Dương Đông gắn liền với nguồn hải sản tươi đánh bắt trong ngày ở Đảo Ngọc.",
            "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80",
            "Quanh năm (Sáng và tối)",
            "55.000đ - 95.000đ",
            [25],
        ),
        (
            24, 10,
            "Gỏi Cá Trích Đại Dương Đảo Ngọc",
            "Phi lê cá trích tươi rói trộn hành tây, ớt sừng và nước cốt chanh, cuốn bánh tráng với dừa khô nạo, rau rừng đảo Phú Quốc và chấm nước mắm cốt cá cơm đậu phộng.",
            "Món ăn biểu tượng thể hiện sự trù phú của vùng biển đảo Tây Nam Tổ quốc.",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80",
            "Bữa trưa và bữa tối bên bờ biển",
            "120.000đ - 220.000đ",
            [26],
        ),
    ]

    existing_food_names = {f.name for f in db.query(LocalFood).all()}
    existing_food_ids = {f.id for f in db.query(LocalFood).all()}

    for f_id, prov_id, name, desc, story, img_url, season, price, rec_ids in raw_foods:
        if name in existing_food_names or f_id in existing_food_ids:
            continue
        db.add(
            LocalFood(
                id=f_id,
                province_id=prov_id,
                name=name,
                description=desc,
                story_origin=story,
                image_url=cloudinary_service.build_detail_url(img_url),
                thumbnail_url=cloudinary_service.build_thumbnail_url(img_url),
                best_season_or_time=season,
                avg_price_range=price,
                recommended_restaurant_ids_json=json.dumps(rec_ids),
                status="published",
                data_source="internal",
                license_info="Ban Biên Tập Ẩm thực TripFlow • Ảnh CDN Cloudinary",
                updated_at=now,
            )
        )
    db.flush()

    # --------------------------------------------------------------------
    # 5. ĐẢM BẢO ĐỦ 11 LỊCH TRÌNH MẪU (ITINERARY & STOPS) CHO CẢ 10 TỈNH/THÀNH
    # --------------------------------------------------------------------
    itinerary_templates = [
        (
            1, 1,
            "1 Ngày Khám Phá Tinh Hoa Sài Gòn Quận 1 - Quận 3",
            (
                "Lịch trình chuẩn cho du khách lần đầu đến TP. Hồ Chí Minh: kết hợp trọn vẹn các di tích biểu tượng "
                "và những quán ăn ngon nằm ngay trên trục di chuyển từ Quận 1 sang Quận 3."
            ),
            1,
            [
                (1, 1, "destination", 1, "Dinh Độc Lập (Hội trường Thống Nhất)", "135 Nam Kỳ Khởi Nghĩa, Quận 1, TP.HCM", 10.7770, 106.6953, "08:00 - 10:00", 120, "Tham quan sớm để tránh nắng và chụp ảnh mặt tiền Dinh."),
                (1, 2, "destination", 4, "Nhà thờ Đức Bà & Bưu điện Trung tâm Sài Gòn", "02 Công xã Paris, Quận 1, TP.HCM", 10.7800, 106.6999, "10:15 - 11:30", 75, "Đi bộ 400m từ Dinh Độc Lập qua công viên 30/4 rợp bóng cây."),
                (1, 3, "restaurant", 4, "Ăn trưa tại Nhà hàng Ngon (160 Pasteur)", "160 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM", 10.7782, 106.6968, "11:45 - 13:15", 90, "Nằm ngay trên trục đường Pasteur nối sang Quận 3."),
                (1, 4, "destination", 7, "Bảo tàng Chứng tích Chiến tranh", "28 Võ Văn Tần, Quận 3, TP.HCM", 10.7795, 106.6921, "14:00 - 16:00", 120, "Không gian trưng bày trong nhà có máy lạnh mát mẻ vào buổi chiều."),
                (1, 5, "destination", 6, "Dạo mát Phố đi bộ Nguyễn Huệ & Bến Bạch Đằng", "Đường Nguyễn Huệ, Quận 1, TP.HCM", 10.7744, 106.7035, "17:30 - 20:30", 180, "Ngắm hoàng hôn trên sông Sài Gòn và thưởng thức ẩm thực quanh Chợ Bến Thành."),
            ],
        ),
        (
            2, 1,
            "Hành Trình Di Sản & Ẩm Thực Đường Phố TP.HCM (2 Ngày)",
            (
                "Khám phá sâu chiều dài lịch sử từ Dinh Độc Lập, Bến Nhà Rồng tới Địa đạo Củ Chi, "
                "kết hợp thưởng thức Cơm tấm, Bánh xèo, Phở Pasteur và dạo mát Bến Bạch Đằng về đêm."
            ),
            2,
            [
                (1, 1, "restaurant", 1, "Ăn sáng Cơm Tấm Bụi Sài Gòn", "100 Lê Thánh Tôn, Quận 1, TP.HCM", 10.7785, 106.7015, "07:30 - 08:30", 60, "Thưởng thức đĩa cơm tấm sườn bì chả chuẩn vị Sài Gòn."),
                (1, 2, "destination", 2, "Tham quan & Mua sắm tại Chợ Bến Thành", "Đường Lê Lợi, Quận 1, TP.HCM", 10.7725, 106.6980, "08:45 - 10:30", 105, "Check-in cửa Nam và khám phá khu ẩm thực truyền thống."),
                (2, 1, "destination", 8, "Khám phá Khu di tích Địa đạo Củ Chi", "Xã Phú Mỹ Hưng, Huyện Củ Chi, TP.HCM", 11.1414, 106.4625, "08:00 - 12:30", 270, "Khởi hành buổi sáng từ trung tâm Quận 1 đi Củ Chi."),
            ],
        ),
        (
            3, 2,
            "1 Ngày Khám Phá Đà Nẵng: Sơn Trà - Cầu Rồng - Ngũ Hành Sơn",
            "Hành trình trọn vẹn qua các danh thắng nổi tiếng nhất TP. Đà Nẵng và thưởng thức Mì Quảng, hải sản biển Mỹ Khê.",
            1,
            [
                (1, 1, "destination", 12, "Chùa Linh Ứng Bán Đảo Sơn Trà", "Bãi Bụt, Quận Sơn Trà, TP. Đà Nẵng", 16.1003, 108.2778, "08:00 - 10:00", 120, "Ngắm toàn cảnh biển Đà Nẵng từ bán đảo Sơn Trà."),
                (1, 2, "restaurant", 9, "Ăn trưa Mì Quảng Bà Mua - Trần Bình Trọng", "19-21 Trần Bình Trọng, Quận Hải Châu, TP. Đà Nẵng", 16.0642, 108.2215, "11:30 - 13:00", 90, "Thưởng thức Mì Quảng tôm thịt và bánh tráng cuốn thịt heo."),
                (1, 3, "destination", 10, "Danh thắng Ngũ Hành Sơn", "81 Huyền Trân Công Chúa, Quận Ngũ Hành Sơn, TP. Đà Nẵng", 16.0033, 108.2631, "14:30 - 17:00", 150, "Khám phá động Huyền Không và làng đá Non Nước."),
                (1, 4, "destination", 9, "Dạo mát Cầu Rồng & Bờ Đông Sông Hàn", "Đường Nguyễn Văn Linh, Quận Hải Châu, TP. Đà Nẵng", 16.0611, 108.2275, "19:30 - 21:30", 120, "Xem Cầu Rồng phun lửa và phun nước tối cuối tuần."),
            ],
        ),
        (
            4, 3,
            "1 Ngày Dạo Bước Nghìn Năm Văn Hiến Thủ Đô Hà Nội",
            "Trải nghiệm không gian lịch sử Hồ Hoàn Kiếm, Hoàng thành Thăng Long, Văn Miếu và ẩm thực Phở bò, Bún chả Hà Nội.",
            1,
            [
                (1, 1, "restaurant", 11, "Ăn sáng Phở Thìn Bờ Hồ", "61 Đinh Tiên Hoàng, Quận Hoàn Kiếm, Hà Nội", 21.0294, 105.8532, "07:00 - 08:00", 60, "Thưởng thức bát phở bò nóng hổi bên Hồ Gươm."),
                (1, 2, "destination", 11, "Hồ Hoàn Kiếm & Đền Ngọc Sơn", "Phường Hàng Trống, Quận Hoàn Kiếm, Hà Nội", 21.0288, 105.8525, "08:15 - 10:00", 105, "Tham quan Cầu Thê Húc và Tháp Bút."),
                (1, 3, "destination", 14, "Khu Di tích Hoàng thành Thăng Long", "19C Hoàng Diệu, Quận Ba Đình, Hà Nội", 21.0341, 105.8400, "10:15 - 12:00", 105, "Khám phá di sản văn hóa thế giới UNESCO."),
                (1, 4, "restaurant", 12, "Ăn trưa Bún Chả Hương Liên", "24 Lê Văn Hưu, Quận Hai Bà Trưng, Hà Nội", 21.0185, 105.8528, "12:15 - 13:30", 75, "Thưởng thức bún chả và nem cua bể."),
                (1, 5, "destination", 13, "Văn Miếu - Quốc Tử Giám", "58 Quốc Tử Giám, Quận Đống Đa, Hà Nội", 21.0278, 105.8355, "14:30 - 16:30", 120, "Tham quan Khuê Văn Các và vườn bia Tiến sĩ."),
            ],
        ),
        (
            5, 4,
            "Hành Trình Du Thuyền Di Sản Vịnh Hạ Long & Bảo Tàng Quảng Ninh",
            "Chiêm ngưỡng kỳ quan thiên nhiên thế giới Vịnh Hạ Long, check-in Bảo tàng Quảng Ninh và thưởng thức chả mực giã tay.",
            1,
            [
                (1, 1, "destination", 15, "Du thuyền Vịnh Hạ Long - Động Thiên Cung", "Cảng tàu khách quốc tế Hạ Long, Quảng Ninh", 20.9101, 107.0763, "08:00 - 12:00", 240, "Tham quan Hòn Trống Mái và Động Thiên Cung."),
                (1, 2, "restaurant", 13, "Ăn trưa Hải sản & Chả mực tại Hồng Hạnh 3", "50 Hạ Long, Phường Bãi Cháy, TP. Hạ Long", 20.9532, 107.0585, "12:30 - 14:00", 90, "Thưởng thức chả mực giã tay và hải sản tươi sống."),
                (1, 3, "destination", 16, "Bảo tàng & Thư viện Quảng Ninh", "Đường Trần Quốc Nghiễn, TP. Hạ Long", 20.9515, 107.0998, "15:00 - 17:00", 120, "Check-in kiến trúc kính đen bên bờ vịnh."),
            ],
        ),
        (
            6, 5,
            "Chinh Phục Đỉnh Fansipan & Bản Cát Cát Sa Pa (1 Ngày)",
            "Săn mây trên Nóc nhà Đông Dương, tản bộ khám phá bản làng H'Mông Cát Cát và thưởng thức lẩu cá hồi vân nóng hổi.",
            1,
            [
                (1, 1, "destination", 17, "Chinh phục Đỉnh Fansipan", "Khu du lịch Sun World Fansipan Legend, Sa Pa", 22.3033, 103.7750, "08:00 - 12:00", 240, "Đi tàu hỏa Mường Hoa và cáp treo lên đỉnh 3.143m."),
                (1, 2, "destination", 18, "Bản Cát Cát & Thác Tiên Sa", "Xã San Sả Hồ, Thị xã Sa Pa", 22.3268, 103.8315, "14:00 - 16:30", 150, "Khám phá văn hóa H'Mông và thác nước Cát Cát."),
                (1, 3, "restaurant", 15, "Ăn tối Lẩu cá hồi & Thắng cố tại Nhà hàng A Phủ", "15 Fansipan, Thị xã Sa Pa", 22.3325, 103.8402, "18:00 - 20:00", 120, "Thưởng thức đặc sản Tây Bắc trong sương lạnh."),
            ],
        ),
        (
            7, 6,
            "1 Ngày Tìm Về Di Sản Cố Đô Huế: Đại Nội - Chùa Thiên Mụ",
            "Hành trình ngược dòng lịch sử qua Hoàng thành Huế, chùa Thiên Mụ bên sông Hương và thưởng thức Bún bò Huế, bánh bèo nậm lọc.",
            1,
            [
                (1, 1, "restaurant", 17, "Ăn sáng Bún Bò Huế Mệ Kéo", "20 Bạch Đằng, TP. Huế", 16.4712, 107.5865, "07:00 - 08:00", 60, "Thưởng thức tô bún bò Huế đậm đà."),
                (1, 2, "destination", 19, "Quần thể Đại Nội Huế - Hoàng Thành", "Đường 23/8, Phường Thuận Hòa, TP. Huế", 16.4698, 107.5786, "08:30 - 11:30", 180, "Tham quan Ngọ Môn, Điện Thái Hòa và Thế Miếu."),
                (1, 3, "restaurant", 18, "Thưởng thức Bánh Bèo Nậm Lọc tại Quán Hạnh", "11 Phó Đức Chính, TP. Huế", 16.4628, 107.5892, "12:00 - 13:30", 90, "Khám phá các món bánh truyền thống xứ Huế."),
                (1, 4, "destination", 20, "Chùa Thiên Mụ & Ngắm Hoàng Hôn Sông Hương", "Phường Hương Long, TP. Huế", 16.4533, 107.5450, "15:30 - 17:30", 120, "Chiêm ngưỡng tháp Phước Duyên bên dòng Hương Giang."),
            ],
        ),
        (
            8, 7,
            "Khám Phá Phố Cổ Hội An & Rừng Dừa Bảy Mẫu (1 Ngày)",
            "Trải nghiệm thuyền thúng rừng dừa Cẩm Thanh, dạo phố đèn lồng Hội An và thưởng thức Cao lầu, Cơm gà phố Hội.",
            1,
            [
                (1, 1, "destination", 22, "Rừng Dừa Bảy Mẫu Cẩm Thanh", "Xã Cẩm Thanh, TP. Hội An", 15.8732, 108.3665, "08:30 - 10:30", 120, "Đi thuyền thúng khám phá rừng dừa nước."),
                (1, 2, "restaurant", 19, "Ăn trưa Cơm Gà Bà Buội Phố Cổ", "22 Phan Chu Trinh, TP. Hội An", 15.8782, 108.3295, "11:30 - 13:00", 90, "Thưởng thức đĩa cơm gà xé trứ danh."),
                (1, 3, "destination", 21, "Chùa Cầu & Khu Phố Cổ Hội An", "Phường Minh An, TP. Hội An", 15.8771, 108.3260, "15:30 - 20:30", 300, "Tản bộ phố cổ và thả hoa đăng trên sông Hoài."),
            ],
        ),
        (
            9, 8,
            "Trải Nghiệm Vịnh Biển Nha Trang: Tháp Bà Ponagar - VinWonders",
            "Khám phá di tích Chăm Pa cổ kính Tháp Bà Ponagar, vui chơi đảo Hòn Tre và thưởng thức बún cá sứa, nem nướng Ninh Hòa.",
            1,
            [
                (1, 1, "restaurant", 22, "Ăn sáng Bún Cá Sứa Năm Beo Chợ Đầm", "Chung cư Phan Bội Châu, TP. Nha Trang", 12.2535, 109.1925, "07:00 - 08:00", 60, "Bún chả cá sứa tươi ngon ngọt nước."),
                (1, 2, "destination", 23, "Tháp Bà Ponagar Nha Trang", "Đường 2 Tháng 4, TP. Nha Trang", 12.2654, 109.1956, "08:30 - 10:30", 120, "Tham quan quần thể kiến trúc Chăm Pa cổ."),
                (1, 3, "restaurant", 21, "Ăn trưa Nem Nướng Đặng Văn Quyên", "16A Lãn Ông, TP. Nha Trang", 12.2485, 109.1932, "11:00 - 12:30", 90, "Đặc sản nem nướng Ninh Hòa chính gốc."),
                (1, 4, "destination", 24, "VinWonders Nha Trang - Đảo Hòn Tre", "Đảo Hòn Tre, TP. Nha Trang", 12.2165, 109.2415, "13:30 - 20:30", 420, "Vui chơi công viên giải trí biển đảo và xem nhạc nước."),
            ],
        ),
        (
            10, 9,
            "1 Ngày Săn Mây Đà Lạt: Quảng Trường Lâm Viên - Đỉnh Langbiang",
            "Tận hưởng không khí se lạnh Đà Lạt với bánh căn nóng hổi, chinh phục đỉnh Langbiang và quây quần bên nồi lẩu gà lá é.",
            1,
            [
                (1, 1, "restaurant", 24, "Ăn sáng Bánh Căn Lệ Yersin", "27/44 Yersin, Phường 10, TP. Đà Lạt", 11.9438, 108.4492, "07:30 - 08:30", 60, "Bánh căn trứng cút xíu mại nóng hổi."),
                (1, 2, "destination", 26, "Khu du lịch Đỉnh Langbiang", "Thị trấn Lạc Dương, Lâm Đồng", 12.0468, 108.4385, "09:00 - 12:00", 180, "Đi xe Jeep lên đỉnh Radar ngắm toàn cảnh cao nguyên."),
                (1, 3, "destination", 25, "Quảng trường Lâm Viên & Hồ Xuân Hương", "Đường Trần Quốc Toản, TP. Đà Lạt", 11.9404, 108.4425, "15:00 - 17:30", 150, "Check-in nụ hoa Atiso và dạo quanh Hồ Xuân Hương."),
                (1, 4, "restaurant", 23, "Ăn tối Lẩu Gà Lá É Tao Ngộ", "05 Đường 3 Tháng 4, TP. Đà Lạt", 11.9362, 108.4485, "18:00 - 20:00", 120, "Thưởng thức lẩu gà lá é ấm nóng."),
            ],
        ),
        (
            11, 10,
            "Khám Phá Đảo Ngọc Phú Quốc: Dinh Cậu - Cầu Hôn Sunset Town",
            "Thưởng thức Bún quậy Kiến Xây, Gỏi cá trích và ngắm hoàng hôn đẹp nhất Việt Nam tại Dinh Cậu & Cầu Hôn Phú Quốc.",
            1,
            [
                (1, 1, "restaurant", 25, "Ăn sáng Bún Quậy Kiến Xây Dương Đông", "28 Bạch Đằng, Phường Dương Đông, Phú Quốc", 10.2215, 103.9612, "08:00 - 09:00", 60, "Trải nghiệm tự pha nước chấm và ăn bún quậy tươi."),
                (1, 2, "destination", 27, "Dinh Cậu & Bãi Biển Dương Đông", "Khu phố 2, Phường Dương Đông, Phú Quốc", 10.2175, 103.9578, "09:30 - 11:30", 120, "Viếng Dinh Cậu trên ghềnh đá ven biển."),
                (1, 3, "restaurant", 26, "Ăn trưa Gỏi Cá Trích tại Nhà hàng Ra Khơi", "131 Đường 30 Tháng 4, Dương Đông, Phú Quốc", 10.2128, 103.9648, "12:00 - 13:30", 90, "Thưởng thức gỏi cá trích và hải sản Phú Quốc."),
                (1, 4, "destination", 28, "Thị trấn Hoàng Hôn Sunset Town & Cầu Hôn", "Phường An Thới, Nam Đảo Phú Quốc", 10.0325, 104.0065, "16:00 - 19:30", 210, "Ngắm hoàng hôn trên Cầu Hôn Kiss Bridge."),
            ],
        ),
    ]

    existing_itin_titles = {i.title for i in db.query(Itinerary).all()}
    existing_itin_ids = {i.id for i in db.query(Itinerary).all()}

    for itin_id, prov_id, title, desc, total_days, stop_tuples in itinerary_templates:
        if title in existing_itin_titles or itin_id in existing_itin_ids:
            continue
        itin = Itinerary(
            id=itin_id,
            user_id=1,
            province_id=prov_id,
            title=title,
            description=desc,
            total_days=total_days,
            is_template=True,
            status="active",
            created_at=now,
            updated_at=now,
        )
        db.add(itin)
        db.flush()

        for day_num, order, st_type, ref_id, st_title, st_addr, st_lat, st_lng, p_time, dur, notes in stop_tuples:
            db.add(
                ItineraryStop(
                    itinerary_id=itin.id,
                    day_number=day_num,
                    stop_order=order,
                    stop_type=st_type,
                    reference_id=ref_id,
                    title=st_title,
                    address=st_addr,
                    latitude=st_lat,
                    longitude=st_lng,
                    planned_time=p_time,
                    duration_mins=dur,
                    notes=notes,
                )
            )
    db.flush()


def _seed_initial_favorites_reports_and_audits(db: Session, now: datetime) -> None:
    """Khởi tạo Favorites, ContentReports và AuditLogs nếu bảng đang trống."""
    if db.query(Favorite).count() == 0:
        db.add_all([
            Favorite(user_id=5, target_type="destination", target_id=1, created_at=now),
            Favorite(user_id=5, target_type="destination", target_id=6, created_at=now),
            Favorite(user_id=5, target_type="restaurant", target_id=3, created_at=now),
            Favorite(user_id=5, target_type="local_food", target_id=1, created_at=now),
        ])

    if db.query(ContentReport).count() == 0:
        db.add_all([
            ContentReport(
                id=1, user_id=5, target_type="restaurant", target_id=5,
                target_name="Bánh Xèo 46A Đinh Công Tráng",
                issue_type="wrong_hours",
                description="Quán có nghỉ trưa từ 14:00 đến 16:00, nhờ Admin ghi rõ khung giờ nghỉ trưa để du khách tránh ghé lúc đóng bếp.",
                rating=5, status="pending", created_at=now,
            ),
            ContentReport(
                id=2, user_id=5, target_type="destination", target_id=3,
                target_name="Nhà thờ Đức Bà Sài Gòn",
                issue_type="review_feedback",
                description="Hiện tại phần tháp chuông vẫn đang có giàn giáo trùng tu nhưng khuôn viên phía trước chụp ảnh rất đẹp.",
                rating=5, status="pending", created_at=now,
            ),
            ContentReport(
                id=3, user_id=5, target_type="restaurant", target_id=2,
                target_name="Bánh Mì Huỳnh Hoa - Phạm Ngũ Lão",
                issue_type="wrong_price",
                description="Giá ổ bánh mì thập cẩm mới điều chỉnh nhẹ lên 68.000đ/ổ.",
                rating=5, status="resolved",
                moderator_note="Moderator đã xác minh và cập nhật khoảng giá 65.000đ - 75.000đ.",
                created_at=now, resolved_at=now,
            ),
        ])

    if db.query(AuditLog).count() == 0:
        db.add_all([
            AuditLog(
                actor_id=1, actor_email="admin@tripflow.vn", actor_role="super_admin",
                action="CREATE", entity_type="province", entity_id=1,
                summary="Khởi tạo dữ liệu chuẩn 10 Tỉnh/Thành phố du lịch Việt Nam với SQLModel, Goong Maps và Cloudinary CDN.",
                changes_json=json.dumps({"provinces_count": 10, "is_active": True}, ensure_ascii=False),
                created_at=now,
            ),
            AuditLog(
                actor_id=3, actor_email="hcm.editor@tripflow.vn", actor_role="province_editor",
                action="UPDATE", entity_type="destination", entity_id=1,
                summary="Cập nhật giờ mở cửa và ảnh Cloudinary cho Dinh Độc Lập (Quận 1, TP.HCM).",
                changes_json=json.dumps({"opening_hours": "08:00 - 15:30", "verified": True}, ensure_ascii=False),
                created_at=now,
            ),
        ])


def init_and_seed_db() -> None:
    """
    Script chuẩn nạp dữ liệu mẫu theo cơ chế Idempotent Incremental Seed (Upsert):
    - Khởi tạo bảng Role, Permission, RolePermissionLink (SQLModel RBAC) và CrawlJob
    - Tự động đồng bộ cột `is_verified`, `source`, `source_url` cho Destination & Restaurant
    - Đảm bảo luôn có đủ 10 Tỉnh/Thành phố du lịch trọng điểm thuộc 4 vùng miền Việt Nam:
      (`HCM`, `DN`, `HN`, `QN`, `LC`, `HUE`, `QNA`, `KH`, `LD`, `KG`)
    - Đảm bảo 28 Địa điểm du lịch, 26 Nhà hàng dọc lộ trình, 24 Đặc sản và 11 Lịch trình mẫu.
    """
    SQLModel.metadata.create_all(engine)
    _ensure_ingestion_columns()
    db: Session = SessionLocal()
    try:
        now = datetime.utcnow()
        _seed_rbac_users_and_categories(db, now)
        _ensure_all_10_provinces_and_content(db, now)
        _seed_initial_favorites_reports_and_audits(db, now)
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    init_and_seed_db()
    print("Seeded TripFlow database with all 10 provinces successfully via seed_db.py!")
