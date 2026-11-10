# 📋 KẾ HOẠCH TOÀN DIỆN CHUYỂN ĐỔI BACKEND SANG ASP.NET CORE (.NET 10 / C#) — 100% PARITY

**Dự án:** Nền tảng Du lịch & Lộ trình Phượt Thông minh TripFlow  
**Tác nhân thực hiện:** 🧠 Planner Agent (Model: pro)  
**Người nhận kế hoạch:** 💻 Coder Agent (Model: inherit / pro)  
**Tài liệu hợp đồng chuẩn:** `backend/swagger.json` (OpenAPI v3 Contract)  
**Ngày lập kế hoạch:** 10/11/2026  
**Mục tiêu tối thượng:** Chuyển đổi toàn diện 100% tính năng từ FastAPI sang ASP.NET Core Web API (.NET 10 / C#) chạy trên cơ sở dữ liệu PostgreSQL thật; bảo đảm không phá vỡ hợp đồng API với ứng dụng Flutter di động và React Admin Dashboard; đạt điểm chuẩn DoD, pass 7/7 bài kiểm tra `smoke_test.py` và tối thiểu 40 bài test unit/integration .NET.

---

## 1. BẢNG PHÂN TÍCH HIỆN TRẠNG & CÁC LỖI HỢP ĐỒNG NGUY HIỂM

### 1.1. Báo động đỏ: Sự khác biệt kiến trúc và Lỗi vỡ giao diện (Breaking Changes)
Trong quá trình khảo sát thực tế codebase Flutter (`lib/`) và React Admin (`admin-web/`), Planner Agent phát hiện 5 cạm bẫy sống còn mà Coder Agent bắt buộc phải tuân thủ tuyệt đối:

| Vấn đề | Hiện trạng FastAPI / Yêu cầu Client | Cạm bẫy thường gặp ở ASP.NET Core | Giải pháp kỹ thuật bắt buộc (.NET 10) |
| :--- | :--- | :--- | :--- |
| **1. JSON Naming Policy** | Client (Flutter & Admin) dùng hoàn toàn `snake_case` (ví dụ `province_id`, `access_token`, `image_url`, `total_days`). | ASP.NET Core mặc định `camelCase` (`provinceId`, `accessToken`) hoặc `PascalCase`. Khiến Flutter và Admin null toàn bộ dữ liệu. | Cấu hình `JsonNamingPolicy.SnakeCaseLower` trong `AddJsonOptions` ở `Program.cs`. |
| **2. Enum Serialization** | Trả về chuỗi lowercase: `"motorbike"`, `"saver"`, `"published"`, `"food"`, `"gas"`. | .NET mặc định serialize Enum thành số nguyên (`0`, `1`, `2`) gây crash deserialization phía client. | Bổ sung `JsonStringEnumConverter(JsonNamingPolicy.SnakeCaseLower)` vào JsonOptions. |
| **3. Error Envelope** | Client bắt trường `detail`:<br>• Chuỗi đơn: `{"detail": "Mô tả lỗi"}`<br>• Cấu trúc AI: `{"detail": {"code": "...", "message": "..."}}`. React Admin gọi `err.response.data?.detail`. | .NET Core mặc định trả `ProblemDetails` với `{ "title": "...", "errors": {...} }`. Flutter và React Admin lập tức báo `undefined` hoặc văng Exception. | Thiết lập `ErrorEnvelopeMiddleware` và Custom Model Validation Filter để mọi lỗi 4xx/5xx luôn được đóng gói dưới dạng `{ "detail": ... }`. |
| **4. Date & Time Format** | ISO 8601 UTC string (`2026-11-10T02:00:00Z`). | Đôi khi bị kèm múi giờ local hoặc tick format nếu không định cấu hình UTC. | Dùng `DateTime.UtcNow` và ép chuẩn ISO 8601 trong JSON Serializer. |
| **5. Sequence Out-of-sync sau Seed** | PostgreSQL sử dụng `SEQUENCE` cho cột ID serial. Sau khi seed dữ liệu với ID tường minh (1, 2, 3...), sequence vẫn ở mức 1. | Khi người dùng thực hiện INSERT bản ghi mới, Postgres quăng lỗi `duplicate key value violates unique constraint`. | Sau khi seed xong, bắt buộc chạy SQL: `SELECT setval(pg_get_serial_sequence('table', 'id'), coalesce(max(id), 1), max(id) IS NOT NULL) FROM table;`. |

---

## 2. THIẾT KẾ KIẾN TRÚC TỔNG THỂ SOLUTION (.NET 10)

### 2.1. Cấu trúc Solution & Projects
Solution sẽ được đặt tên là `TripFlow.sln` tại thư mục gốc, bao gồm 2 project chính:
1. `backend-dotnet/TripFlow.Api/TripFlow.Api.csproj` (Web API ASP.NET Core .NET 10)
2. `backend-dotnet/TripFlow.Tests/TripFlow.Tests.csproj` (xUnit Test Project kiểm thử tích hợp trên PostgreSQL)

```
d:\trip_flow\
├── TripFlow.sln
├── backend-dotnet/
│   ├── TripFlow.Api/
│   │   ├── Controllers/
│   │   │   ├── AuthController.cs              # POST login, register, otp/send, otp/verify, me, 2fa, export, delete
│   │   │   ├── ProvincesController.cs         # GET provinces, regions/summary, categories, {id}
│   │   │   ├── DestinationsController.cs      # GET destinations (paginated), {id}, POST {id}/report
│   │   │   ├── LocalFoodsController.cs        # GET local-foods, {id}
│   │   │   ├── RestaurantsController.cs       # GET restaurants, POST corridor-search, GET on-route, {id}
│   │   │   ├── ItinerariesController.cs       # GET, POST, sync, {id}, stops, smart-meal-stops
│   │   │   ├── PlacesController.cs            # GET nearby, suggest, along-route, history CRUD
│   │   │   ├── TripsController.cs             # GET, POST, {id}, duplicate, share, stops, reorder, generate, ai-status
│   │   │   ├── ExpensesController.cs          # GET, POST, PUT, DELETE expenses, budget-summary
│   │   │   ├── ReviewsController.cs           # GET, POST, summary, DELETE {place_key}
│   │   │   ├── FavoritesController.cs         # GET, POST, DELETE favorites
│   │   │   ├── MapsController.cs              # GET directions
│   │   │   ├── AssistantController.cs         # POST chat
│   │   │   ├── HealthController.cs            # GET /, /health, /health/ready, /api/v1/contract/swagger.json
│   │   │   └── AdminController.cs             # Toàn bộ /api/v1/admin/* (dashboard, upload, CRUD catalog, users, reports, audit, crawl)
│   │   ├── Data/
│   │   │   ├── TripFlowDbContext.cs           # EF Core DbContext 22+ entities, B-Tree Composite Index (lat, lng)
│   │   │   ├── DatabaseSeeder.cs              # Idempotent incremental seed (168 dests, 77 rests, 50 rest stops, 10 provs)
│   │   │   └── SeederExtensions.cs            # Reset Postgres Sequences script
│   │   ├── Models/
│   │   │   ├── Entities/                      # 22+ EF Core Entity Models
│   │   │   └── DTOs/                          # Data Transfer Objects đúng chuẩn swagger.json
│   │   ├── Services/
│   │   │   ├── IAuthService.cs & AuthService.cs
│   │   │   ├── ITokenService.cs & TokenService.cs
│   │   │   ├── ISmsService.cs & SmsService.cs
│   │   │   ├── IGeoService.cs & GeoService.cs
│   │   │   ├── IPlacesService.cs & PlacesService.cs
│   │   │   ├── ITripService.cs & TripService.cs
│   │   │   ├── IExpenseService.cs & ExpenseService.cs
│   │   │   ├── IMapsService.cs & MapsService.cs
│   │   │   └── IAIAssistantService.cs & AIAssistantService.cs
│   │   ├── Middleware/
│   │   │   ├── ErrorEnvelopeMiddleware.cs     # Bọc tất cả lỗi thành {"detail": ...}
│   │   │   └── GuestTokenHeaderFilter.cs      # Trích xuất X-Guest-Token
│   │   ├── Program.cs                         # Configuration, DI, JSON Options, JWT, CORS, Swagger
│   │   └── appsettings.json                   # ConnectionStrings, JWT Secret, External API keys
│   └── TripFlow.Tests/
│       ├── TripFlow.Tests.csproj
│       ├── Fixtures/DatabaseFixture.cs        # Khởi tạo Test Database PostgreSQL
│       ├── AuthParityTests.cs
│       ├── CatalogParityTests.cs
│       ├── PlacesAndCorridorTests.cs
│       ├── TripsAndExpensesTests.cs
│       └── AdminParityTests.cs
```

### 2.2. Danh sách NuGet Packages bắt buộc

#### Project `TripFlow.Api.csproj`:
```xml
<ItemGroup>
  <!-- Entity Framework Core & PostgreSQL -->
  <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
  <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.0">
    <PrivateAssets>all</PrivateAssets>
    <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
  </PackageReference>
  
  <!-- Authentication & Security -->
  <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="10.0.0" />
  <PackageReference Include="System.IdentityModel.Tokens.Jwt" Version="8.6.0" />
  <PackageReference Include="BCrypt.Net-Next" Version="4.0.3" />
  <PackageReference Include="Otp.NET" Version="1.4.0" />

  <!-- OpenAPI & Swagger -->
  <PackageReference Include="Swashbuckle.AspNetCore" Version="7.3.1" />
  <PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="10.0.0" />
</ItemGroup>
```

#### Project `TripFlow.Tests.csproj`:
```xml
<ItemGroup>
  <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.13.0" />
  <PackageReference Include="xunit" Version="2.9.3" />
  <PackageReference Include="xunit.runner.visualstudio" Version="3.0.2" />
  <PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="10.0.0" />
  <PackageReference Include="FluentAssertions" Version="8.1.1" />
  <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
</ItemGroup>
```

---

## 3. THIẾT KẾ CƠ SỞ DỮ LIỆU & EF CORE MAPPINGS (PHASE 1)

### 3.1. Danh mục 22 Bảng Entity & Chỉ mục B-Tree Composite
Cần ánh xạ chính xác 100% tên bảng và tên cột vào PostgreSQL để tương thích với dữ liệu và truy vấn:

1. `provinces` (`Province`): `id`, `code` (unique, varchar 20), `name`, `region`, `description`, `hero_image`, `center_lat`, `center_lng`, `is_active`, `data_source`, `updated_at`.
2. `categories` (`Category`): `id`, `code` (unique, varchar 50), `name`, `icon_name`, `description`.
3. `destinations` (`Destination`): `id`, `province_id`, `category_id`, `name`, `slug`, `description`, `address`, `latitude`, `longitude`, `opening_hours`, `ticket_price_info`, `rating`, `review_count`, `recommended_duration_mins`, `thumbnail_url`, `detail_image_url`, `is_featured`, `is_sponsored`, `sponsor_label`, `is_verified`, `source`, `source_url`, `status`, `data_source`, `source_attribution`, `last_verified_at`, `updated_at`.
   - **Composite Index:** `ix_destinations_lat_lng` trên `(latitude, longitude)` phục vụ Bounding Box.
4. `destination_images` (`DestinationImage`): `id`, `destination_id`, `image_url`, `thumbnail_url`, `caption`, `sort_order`, `license_type`, `credit_author`.
5. `local_foods` (`LocalFood`): `id`, `province_id`, `name`, `description`, `story_origin`, `image_url`, `thumbnail_url`, `best_season_or_time`, `avg_price_range`, `recommended_restaurant_ids_json`, `status`, `data_source`, `license_info`, `updated_at`.
6. `restaurants` (`Restaurant`): `id`, `province_id`, `name`, `address`, `latitude`, `longitude`, `cuisine_type`, `specialty_dishes`, `specialties`, `price_range`, `opening_hours`, `contact_phone`, `rating`, `review_count`, `reviews_count`, `sample_reviews_json`, `is_high_rated`, `image_url`, `thumbnail_url`, `image_credit`, `image_license`, `image_source_url`, `is_sponsored`, `sponsor_label`, `is_verified`, `source`, `source_url`, `status`, `data_source`, `last_updated_at`.
   - **Composite Index:** `ix_restaurants_lat_lng` trên `(latitude, longitude)`.
7. `rest_stops` (`RestStop`): `id`, `province_id`, `category` (`fuel`, `ev`, `rest`, `viewpoint`, `park`, `mechanic`, `toilet`, `cafe`), `name`, `address`, `latitude`, `longitude`, `opening_hours`, `phone`, `description`, `brand`, `image_url`, `thumbnail_url`, `image_credit`, `image_license`, `image_source_url`, `rating`, `review_count`, `is_verified`, `source`, `source_url`, `status`, `data_source`, `updated_at`.
   - **Composite Index:** `ix_rest_stops_lat_lng` trên `(latitude, longitude)`.
8. `users` (`User`): `id`, `email` (unique, varchar 180), `phone` (index, varchar 20), `full_name`, `hashed_password`, `role` (index, default 'user'), `role_id`, `assigned_province_id`, `is_active`, `failed_login_attempts`, `locked_until`, `totp_secret`, `totp_enabled`, `created_at`.
9. `roles` (`Role`): `id`, `code` (unique, varchar 50), `name`, `description`.
10. `permissions` (`Permission`): `id`, `code` (unique, varchar 80), `name`, `module`, `description`.
11. `role_permission_links` (`RolePermissionLink`): `role_id`, `permission_id` (Composite Primary Key).
12. `admin_roles` (`AdminRole`): `id`, `role_code` (unique), `role_name`, `permissions_json`, `description`.
13. `itineraries` (`Itinerary`): `id`, `user_id`, `province_id`, `title`, `description`, `total_days`, `is_template`, `status`, `created_at`, `updated_at`.
14. `itinerary_stops` (`ItineraryStop`): `id`, `itinerary_id`, `day_number`, `stop_order`, `stop_type`, `reference_id`, `title`, `address`, `latitude`, `longitude`, `planned_time`, `duration_mins`, `notes`.
15. `trips` (`Trip`): `id`, `user_id`, `province_id`, `title`, `origin_name`, `origin_lat`, `origin_lng`, `destination_name`, `destination_lat`, `destination_lng`, `start_date`, `total_days`, `party_size`, `vehicle` (varchar), `budget_level` (varchar), `budget_amount`, `preferences_json`, `status` (varchar), `share_token` (unique), `guest_token` (index), `ai_generated`, `generation_meta_json`, `created_at`, `updated_at`.
16. `trip_days` (`TripDay`): `id`, `trip_id`, `day_number`, `date`, `title`, `note`.
17. `trip_stops` (`TripStop`): `id`, `trip_day_id`, `trip_id`, `stop_order`, `kind`, `place_id`, `ref_table`, `ref_id`, `name`, `address`, `lat`, `lng`, `arrive_at`, `stay_mins`, `travel_mins_from_prev`, `distance_km_from_prev`, `est_cost`, `note`, `source`.
18. `expenses` (`Expense`): `id`, `trip_id`, `trip_day_id`, `category` (varchar: `fuel`, `food`, `hotel`, `ticket`, `other`), `title`, `amount`, `planned`, `spent_at`, `paid_by`, `note`, `created_at`.
19. `place_reviews` (`PlaceReview`): `id`, `place_key` (index), `user_id`, `author_name`, `rating`, `comment`, `visited_on`, `created_at`, `is_hidden`.
20. `favorites` (`Favorite`): `id`, `user_id`, `target_type`, `target_id`, `created_at`.
21. `content_reports` (`ContentReport`): `id`, `user_id`, `target_type`, `target_id`, `target_name`, `issue_type`, `description`, `rating`, `status`, `moderator_note`, `created_at`, `resolved_at`.
22. `audit_logs` (`AuditLog`): `id`, `actor_id`, `actor_email`, `actor_role`, `action`, `entity_type`, `entity_id`, `summary`, `changes_json`, `created_at`.
23. `sms_otp_verifications` (`SMSOTPVerification`): `id`, `phone`, `otp_code`, `expires_at`, `is_used`, `attempts`, `full_name`, `created_at`.
24. `place_cache` (`PlaceCache`): `id`, `provider`, `cache_key`, `payload_json`, `fetched_at`, `expires_at`.
25. `search_history` (`SearchHistory`): `id`, `user_id`, `query`, `kind`, `place_id`, `lat`, `lng`, `created_at`.
26. `crawl_jobs` (`CrawlJob`): `id`, `keyword`, `lat`, `lng`, `status`, `total_scraped`, `inserted_count`, `duplicate_count`, `error_message`, `created_at`, `completed_at`.

### 3.2. Cấu hình DbContext Fluent API Mẫu
```csharp
public class TripFlowDbContext : DbContext
{
    public TripFlowDbContext(DbContextOptions<TripFlowDbContext> options) : base(options) { }

    public DbSet<Province> Provinces => Set<Province>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Destination> Destinations => Set<Destination>();
    public DbSet<DestinationImage> DestinationImages => Set<DestinationImage>();
    public DbSet<LocalFood> LocalFoods => Set<LocalFood>();
    public DbSet<Restaurant> Restaurants => Set<Restaurant>();
    public DbSet<RestStop> RestStops => Set<RestStop>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<RolePermissionLink> RolePermissionLinks => Set<RolePermissionLink>();
    public DbSet<AdminRole> AdminRoles => Set<AdminRole>();
    public DbSet<Itinerary> Itineraries => Set<Itinerary>();
    public DbSet<ItineraryStop> ItineraryStops => Set<ItineraryStop>();
    public DbSet<Trip> Trips => Set<Trip>();
    public DbSet<TripDay> TripDays => Set<TripDay>();
    public DbSet<TripStop> TripStops => Set<TripStop>();
    public DbSet<Expense> Expenses => Set<Expense>();
    public DbSet<PlaceReview> PlaceReviews => Set<PlaceReview>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<ContentReport> ContentReports => Set<ContentReport>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<SMSOTPVerification> SMSOTPVerifications => Set<SMSOTPVerification>();
    public DbSet<PlaceCache> PlaceCaches => Set<PlaceCache>();
    public DbSet<SearchHistory> SearchHistories => Set<SearchHistory>();
    public DbSet<CrawlJob> CrawlJobs => Set<CrawlJob>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Đặt tên bảng dạng snake_case
        foreach (var entity in modelBuilder.Model.GetEntityTypes())
        {
            entity.SetTableName(ToSnakeCase(entity.ClrType.Name));
        }
        // Mapping tên bảng đặc biệt cho khớp SQLAlchemy cũ
        modelBuilder.Entity<RolePermissionLink>().ToTable("role_permission_links");
        modelBuilder.Entity<SMSOTPVerification>().ToTable("sms_otp_verifications");
        modelBuilder.Entity<DestinationImage>().ToTable("destination_images");
        modelBuilder.Entity<ItineraryStop>().ToTable("itinerary_stops");
        modelBuilder.Entity<TripDay>().ToTable("trip_days");
        modelBuilder.Entity<TripStop>().ToTable("trip_stops");
        modelBuilder.Entity<PlaceReview>().ToTable("place_reviews");
        modelBuilder.Entity<ContentReport>().ToTable("content_reports");
        modelBuilder.Entity<AuditLog>().ToTable("audit_logs");
        modelBuilder.Entity<PlaceCache>().ToTable("place_cache");
        modelBuilder.Entity<SearchHistory>().ToTable("search_history");
        modelBuilder.Entity<CrawlJob>().ToTable("crawl_jobs");
        modelBuilder.Entity<LocalFood>().ToTable("local_foods");
        modelBuilder.Entity<RestStop>().ToTable("rest_stops");
        modelBuilder.Entity<AdminRole>().ToTable("admin_roles");

        // Primary Keys & Indexes
        modelBuilder.Entity<RolePermissionLink>()
            .HasKey(rpl => new { rpl.RoleId, rpl.PermissionId });

        modelBuilder.Entity<Destination>()
            .HasIndex(d => new { d.Latitude, d.Longitude })
            .HasDatabaseName("ix_destinations_lat_lng");

        modelBuilder.Entity<Restaurant>()
            .HasIndex(r => new { r.Latitude, r.Longitude })
            .HasDatabaseName("ix_restaurants_lat_lng");

        modelBuilder.Entity<RestStop>()
            .HasIndex(rs => new { rs.Latitude, rs.Longitude })
            .HasDatabaseName("ix_rest_stops_lat_lng");
    }

    private static string ToSnakeCase(string input)
    {
        if (string.IsNullOrEmpty(input)) return input;
        var startUnderscores = System.Text.RegularExpressions.Regex.Match(input, @"^_+");
        return startUnderscores + System.Text.RegularExpressions.Regex.Replace(input, @"([a-z0-9])([A-Z])", "$1_$2").ToLower();
    }
}
```

---

## 4. CHI TIẾT SEED DỮ LIỆU THẬT & ĐỒNG BỘ SEQUENCE (PHASE 2)

### 4.1. Dữ liệu Seed và Tiêu chí Idempotent (168 Dest / 77 Rest / 50 RestStops / 10 Provinces)
1. **10 Provinces cốt lõi:**
   `HCM` (Hồ Chí Minh), `DN` (Đà Nẵng), `HN` (Hà Nội), `QN` (Quảng Ninh), `LC` (Lào Cai), `HUE` (Thừa Thiên Huế), `QNA` (Quảng Nam), `KH` (Khánh Hòa), `LD` (Lâm Đồng), `KG` (Kiên Giang).
2. **5 Roles RBAC:**
   `super_admin`, `content_admin`, `province_editor`, `moderator`, `user`.
3. **Permissions:**
   Đầy đủ 14 permissions: `destination:read`, `destination:write`, `restaurant:read`, `restaurant:write`, `local_food:read`, `local_food:write`, `itinerary:read`, `itinerary:write`, `user:manage`, `report:moderate`, `audit:read`, `crawler:manage`, `maps_quota:read`, `image:upload`.
4. **Seed Bootstrap Admin User:**
   - Email: `admin@tripflow.vn` (hoặc từ biến môi trường `BOOTSTRAP_ADMIN_EMAIL`)
   - Mật khẩu: BCrypt hash của mật khẩu admin (mặc định `Admin@TripFlow2026!`)
   - Role: `super_admin`
5. **Nạp Dữ liệu Mở Catalog (`catalog_extra.json` & `rest_stops_extra.json`):**
   - Đọc file JSON từ `data/catalog_extra.json`. Thêm các Destination và Restaurant chưa có (kiểm tra theo `(province_id, name)` và khoảng cách `<= 100m`).
   - Giữ nguyên ảnh Wikimedia/Unsplash, thumbnail, tác giả (`credit_author`), giấy phép (`license_type`) và `source_url`.
   - Nạp `rest_stops_extra.json`: 50 điểm trạm xăng Petrolimex/PV Oil, trạm sạc EV VinFast, trạm dừng chân cao tốc.
   - Tổng cộng sau khi nạp: **168 Destinations / 77 Restaurants / 50 Rest Stops / 10 Provinces**.
6. **Thuật toán Đồng bộ Sequence PostgreSQL Bắt buộc:**
```csharp
public static async Task ResetPostgresSequencesAsync(TripFlowDbContext db)
{
    var tableNames = new[]
    {
        "provinces", "categories", "destinations", "destination_images",
        "local_foods", "restaurants", "rest_stops", "users", "roles",
        "permissions", "itineraries", "itinerary_stops", "trips",
        "trip_days", "trip_stops", "expenses", "place_reviews",
        "favorites", "content_reports", "audit_logs",
        "sms_otp_verifications", "search_history", "crawl_jobs"
    };

    foreach (var table in tableNames)
    {
        try
        {
            var sql = $"SELECT setval(pg_get_serial_sequence('{table}', 'id'), COALESCE(MAX(id), 1), MAX(id) IS NOT NULL) FROM {table};";
            await db.Database.ExecuteSqlRawAsync(sql);
        }
        catch
        {
            // Bảng không có sequence hoặc khóa chính tổng hợp -> bỏ qua
        }
    }
}
```

---

## 5. THIẾT KẾ AUTHENTICATION & SECURITY CHUẨN XÁC 100% (PHASE 3)

### 5.1. Luồng Xác thực SĐT + OTP SMS (Mobile Client)
- **POST `/api/v1/auth/otp/send`**:
  - Request DTO: `{ "phone": string, "full_name": string? }`
  - Validation: Số điện thoại Việt Nam 10 chữ số (Regex: `^(03|05|07|08|09)\d{8}$`). Báo lỗi 400 nếu sai: `{"detail": "Số điện thoại không đúng định dạng di động Việt Nam..."}`.
  - Rate Limiting 60s: Kiểm tra lần gửi OTP gần nhất của số này trong `sms_otp_verifications`. Nếu `< 60s`, trả 429: `{"detail": "Mã OTP vừa được gửi. Vui lòng đợi {retry_after} giây trước khi yêu cầu mã mới."}`.
  - Sinh mã ngẫu nhiên 6 số (`RandomNumberGenerator`). Trong môi trường Dev (khi cấu hình `DEV_OTP_ENABLED=true`), trả về `debug_otp` trong response.
  - Thời hạn mã: 5 phút (300 giây). Lưu bản ghi vào `sms_otp_verifications`.
  - Response:
    ```json
    {
      "phone": "0901234567",
      "message": "Mã xác thực OTP 6 số đã được gửi qua tin nhắn SMS tới số điện thoại của bạn.",
      "expires_in_seconds": 300,
      "debug_otp": "123456"
    }
    ```
- **POST `/api/v1/auth/otp/verify`**:
  - Request DTO: `{ "phone": string, "otp_code": string, "full_name": string? }`
  - Kiểm tra bản ghi chưa sử dụng (`is_used == false`), chưa quá 5 phút, số lần thử `< 5`.
  - Nếu mã sai: Tăng `attempts += 1`. Trả lỗi 400: `{"detail": "Mã xác thực OTP không chính xác. Bạn còn {5 - attempts} lần thử."}`.
  - Nếu mã đúng: Đánh dấu `is_used = true`.
  - Tìm User theo `phone`. Nếu chưa có: Tạo mới user với email `{phone}@tripflow.vn`, role `user`.
  - Cấp JWT Bearer Token chuẩn.
  - Response:
    ```json
    {
      "access_token": "eyJhbGciOi...",
      "token_type": "bearer",
      "user": {
        "id": 1,
        "email": "0901234567@tripflow.vn",
        "phone": "0901234567",
        "full_name": "Phạm Tấn Tài",
        "role": "user",
        "permissions": ["destination:read", "restaurant:read", "local_food:read", "itinerary:read"],
        "created_at": "2026-11-10T02:00:00Z"
      }
    }
    ```

### 5.2. Luồng Đăng nhập Mật khẩu + 2FA TOTP (Admin Web)
- **POST `/api/v1/auth/login`**:
  - Request DTO: `{ "email": string, "password": string, "otp_code": string? }`
  - Khóa tài khoản: Nếu `failed_login_attempts >= 5` và `locked_until > now`, trả 423: `{"detail": "Tài khoản đang tạm khoá do đăng nhập sai nhiều lần. Vui lòng thử lại sau {minutes} phút."}`.
  - Kiểm tra mật khẩu bằng `BCrypt.Net.BCrypt.Verify(password, user.HashedPassword)`.
  - Nếu sai mật khẩu: Tăng `failed_login_attempts`. Nếu đủ 5 lần thì gán `locked_until = now + 15 phút`. Trả 401.
  - Nếu `totp_enabled == true`:
    - Nếu `otp_code` rỗng: Trả 401: `{"detail": "2FA_REQUIRED: Nhập mã 6 số từ ứng dụng xác thực."}`.
    - Dùng `OtpNet.Totp` xác thực secret với tolerance `VerificationWindow(previous: 1, future: 1)`. Nếu sai trả 401: `{"detail": "Mã 2FA không đúng hoặc đã hết hạn."}`.
  - Thành công: Reset `failed_login_attempts = 0`, ghi Audit Log (nếu là admin), cấp JWT token.

### 5.3. 2FA TOTP Endpoints
- `GET /api/v1/auth/2fa/status` -> `{"enabled": user.TotpEnabled}`
- `POST /api/v1/auth/2fa/setup`:
  - Sinh Base32 secret: `KeyGeneration.GenerateRandomKey(20)`. Lưu vào `user.TotpSecret`.
  - Trả về: `{"secret": secret, "otpauth_url": $"otpauth://totp/TripFlow:{user.Email}?secret={secret}&issuer=TripFlow"}`
- `POST /api/v1/auth/2fa/enable`: Xác nhận mã 6 số từ ứng dụng Google Authenticator. Nếu đúng: `user.TotpEnabled = true`.
- `POST /api/v1/auth/2fa/disable`: Xác nhận mã 6 số. Nếu đúng: `user.TotpEnabled = false; user.TotpSecret = null;`.

### 5.4. Quyền Riêng Tư & Xóa Dữ Liệu Cá Nhân (GDPR-Style)
- `GET /api/v1/auth/me/export`: Xuất toàn bộ JSON thông tin profile, trips, itineraries, reviews, favorites, search_history của người dùng.
- `DELETE /api/v1/auth/account?confirm=DELETE`:
  - Nếu `confirm != "DELETE"`, trả 400: `{"detail": "Nhập confirm=DELETE để xác nhận xoá tài khoản."}`.
  - Xóa toàn bộ dữ liệu cá nhân cascade (stops, days, expenses, trips, itineraries, reviews, favorites, searches) và xóa User.

---

## 6. THUẬT TOÁN ĐỊA LÝ & HÀNH LANG TUYẾN ĐƯỜNG — BIKER CORRIDOR SEARCH (PHASE 4)

### 6.1. Nguyên lý Bounding Box & Chiếu Hình Học Điểm - Tuyến (Point-to-Line)
Để tìm các nhà hàng, cây xăng, điểm dừng nghỉ nằm trong bán kính hành lang (Corridor Radius, mặc định 2km) mà không làm chậm hệ thống:

```
Tuyến đường Polyline: [P0] -----> [P1] -----> [P2] -----> [P3]
                                   |
                             d (vuông góc) <= Corridor Radius (2km)
                                   |
                                   v
                             [POI / Nhà hàng]
```

1. **Bước 1 — Bounding Box sơ bộ trên Database:**
   - Tìm `min_lat`, `max_lat`, `min_lng`, `max_lng` của tất cả điểm polyline.
   - Mở rộng thêm delta: `delta_lat = radius_km / 111.32`, `delta_lng = radius_km / (111.32 * cos(mid_lat))`.
   - Truy vấn SQL tận dụng B-Tree Index:
     `WHERE latitude BETWEEN min_lat AND max_lat AND longitude BETWEEN min_lng AND max_lng`.
2. **Bước 2 — Chiếu Hình Học Vuông Góc Chính Xác (Thuần C#, Siêu Tốc):**
   - Đổi tọa độ sang hệ phẳng chuẩn địa phương với tâm là `(ref_lat, ref_lng)` của tuyến đường:
     $x = (lng - ref\_lng) \times 111.32 \times \cos(ref\_lat)$  
     $y = (lat - ref\_lat) \times 111.32$
   - Với mỗi đoạn thẳng $[A, B]$ trên polyline và điểm POI $P$:
     - Vector $\vec{AB} = B - A$, vector $\vec{AP} = P - A$.
     - Hệ số chiếu: $t = \frac{\vec{AP} \cdot \vec{AB}}{|\vec{AB}|^2}$.
     - Điểm chiếu $Q$ bị clamp $t \in [0, 1]$: $Q = A + t \times \vec{AB}$.
     - Khoảng cách vuông góc: $d = |P - Q|$.
   - Nếu khoảng cách nhỏ nhất $d_{min} \le corridor\_radius\_km$:
     - Tính phần trăm tiến độ dọc tuyến: `route_progress_pct = (cumulative_len_to_Q / total_line_len) * 100`.
     - Tính cự ly lệch đường (detour): `detour_distance_km = d * 2`.
     - Ước tính thời gian lệch đường: `estimated_detour_mins = max(2, (int)(d * 2 / 0.4) + 1)`.

### 6.2. Các Endpoints Hành lang & Địa điểm:
- **`GET /api/v1/places/nearby`**:
  - Hỗ trợ các loại `kinds`: `food`, `cafe`, `hotel`, `gas`, `ev`, `rest`, `sight`.
  - Phân loại chất lượng: `hidden_gem`, `top_rated`, `popular`, `normal`.
  - Lọc rating, giờ mở cửa (`open_now`), khoảng giá (`max_price`), sắp xếp theo `distance`, `rating`, `quality`, `price`.
  - Cache phản hồi vào bảng `place_cache` trong 24 giờ.
- **`GET /api/v1/places/suggest`**:
  - Tìm kiếm chuỗi không dấu (chuyển đổi ký tự tiếng Việt có dấu sang không dấu bằng `StringNormalization` + loại bỏ dấu phụ Unicode `NonSpacingMark`).
  - Gợi ý đồng thời cả Destination (`d_{id}`) và Restaurant (`r_{id}`).
- **`POST /api/v1/places/along-route`**:
  - Nhận toạ độ xuất phát, điểm đến, `corridor_radius_km` và `kinds`.
  - Trả về danh sách điểm dừng nghỉ (`stops`), số lượng (`count`), cự ly tuyến (`route_distance_km`).
- **`POST /api/v1/restaurants/corridor-search` & `GET /api/v1/restaurants/on-route`**:
  - Bọc Rate Limit 10 req/phút/IP.
  - Trả về danh sách quán ăn nằm dọc hành lang tuyến đường.

---

## 7. CÁC MODULE CHUYẾN ĐI, CHI PHÍ, ĐÁNH GIÁ & QUẢN TRỊ (PHASE 5)

### 7.1. Chuyến Đi (Trips) & Khách Vãng Lai (`X-Guest-Token`)
- Khi người dùng chưa đăng nhập: Client gửi header `X-Guest-Token: <UUID>`.
- `Trip` lưu `guest_token`. Khi truy vấn danh sách hoặc chi tiết chuyến đi, nếu user chưa login thì chỉ trả về chuyến có `guest_token` trùng khớp.
- Chức năng:
  - `POST /api/v1/trips` & `GET /api/v1/trips`
  - `GET /api/v1/trips/{id}`, `PUT /api/v1/trips/{id}`, `DELETE /api/v1/trips/{id}`
  - `POST /api/v1/trips/{id}/duplicate`: Nhân bản chuyến đi sang tài khoản hiện tại.
  - `POST /api/v1/trips/{id}/share`: Sinh `share_token` (Base64 URL safe) chia sẻ lộ trình công khai.
  - Quản lý điểm dừng: `POST /days/{day}/stops`, `DELETE /stops/{id}`, `PUT /days/{day}/reorder`.
  - `POST /api/v1/trips/{id}/generate` & `GET /api/v1/trips/{id}/ai-status`: Tự động sinh lịch trình grounded từ danh thắng và nhà hàng có thật trong DB.

### 7.2. Quản Lý Chi Phí Chuyến Đi (Expenses & Budget Summary)
- `GET /api/v1/trips/{id}/expenses`, `POST`, `PUT`, `DELETE`.
- `GET /api/v1/trips/{id}/budget-summary`:
  - Tổng ngân sách dự kiến (`budget_amount`).
  - Tổng đã chi tiêu (`total_spent`).
  - Phân bổ theo từng danh mục: `fuel`, `food`, `hotel`, `ticket`, `other`.
  - Cảnh báo vượt ngân sách nếu `total_spent > budget_amount`.

### 7.3. Đánh Giá Địa Điểm (Reviews Module)
- `GET /api/v1/reviews/{place_key}`
- `POST /api/v1/reviews/{place_key}` (Nếu đã login thì mỗi user chỉ 1 đánh giá, gửi lại sẽ cập nhật).
- `GET /api/v1/reviews/{place_key}/summary`:
  - Điểm trung bình `avg_rating`.
  - Số lượt đánh giá `review_count`.
  - Biểu đồ phân bổ sao `distribution`: `{"1": 0, "2": 0, "3": 1, "4": 5, "5": 12}`.
  - Cờ `hidden_gem = avg >= 4.5 && count >= 3 && count <= 200`.

### 7.4. Quản Trị Hệ Thống (Admin Endpoints)
- `GET /api/v1/admin/dashboard`:
  - Tổng số tỉnh thành, địa điểm, quán ăn, đặc sản, lịch trình mẫu, người dùng, báo cáo chờ duyệt.
  - Phân bổ nguồn dữ liệu (`internal`, `partner`, `api_provider`).
  - Trạng thái hạn mức Goong Maps API (`maps_api_quota`).
  - Danh sách 12 nhật ký quản trị mới nhất (`recent_audit_logs`).
- `POST /api/v1/admin/upload-image`: Tích hợp Cloudinary CDN upload.
- Toàn bộ CRUD cho Admin: Provinces, Destinations, LocalFoods, Restaurants, Itineraries, Users, Reports, AuditLogs.
- Crawl Jobs: Quản lý tiến trình cào dữ liệu ngầm.

---

## 8. CẤU HÌNH JSON SERIALIZATION & ERROR ENVELOPE TRIỆT ĐỂ (PHASE 6)

### 8.1. Cấu hình Program.cs Chuẩn Mực
```csharp
var builder = WebApplication.CreateBuilder(args);

// 1. JSON Options: SnakeCaseLower + StringEnumConverter
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
        options.JsonSerializerOptions.DictionaryKeyPolicy = JsonNamingPolicy.SnakeCaseLower;
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.SnakeCaseLower));
        options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
    })
    .ConfigureApiBehaviorOptions(options =>
    {
        // Custom 400 Bad Request cho Validation Errors trả về {"detail": "..."}
        options.InvalidModelStateResponseFactory = context =>
        {
            var errors = context.ModelState.Values
                .SelectMany(v => v.Errors)
                .Select(e => e.ErrorMessage)
                .ToList();
            var detailMessage = string.Join("; ", errors);
            return new BadRequestObjectResult(new { detail = detailMessage });
        };
    });
```

### 8.2. Error Envelope Middleware (Bảo Vệ Client Khỏi Crash)
```csharp
public class ErrorEnvelopeMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ErrorEnvelopeMiddleware> _logger;

    public ErrorEnvelopeMiddleware(RequestDelegate next, ILogger<ErrorEnvelopeMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);

            // Xử lý các mã lỗi 401, 403, 404 không có body
            if (context.Response.StatusCode == StatusCodes.Status401Unauthorized && !context.Response.HasStarted)
            {
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsJsonAsync(new { detail = "Vui lòng đăng nhập để tiếp tục." });
            }
            else if (context.Response.StatusCode == StatusCodes.Status403Forbidden && !context.Response.HasStarted)
            {
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsJsonAsync(new { detail = "Từ chối truy cập (403 Forbidden): Không có quyền thực hiện." });
            }
        }
        catch (BadHttpRequestException ex)
        {
            context.Response.StatusCode = ex.StatusCode;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new { detail = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled Exception: {Message}", ex.Message);
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new { detail = "Đã xảy ra lỗi máy chủ nội bộ. Vui lòng thử lại sau." });
        }
    }
}
```

---

## 9. QUY TRÌNH KIỂM THỬ TÍCH HỢP & DEFINITION OF DONE (DOD) (PHASE 7)

### 9.1. Kế hoạch Bộ Test .NET (`TripFlow.Tests`) — Tối thiểu 40 Test Cases
1. **Auth Tests (8 tests):**
   - TC-AUTH-01: Gửi OTP tới SĐT Việt Nam hợp lệ -> Nhận mã OTP.
   - TC-AUTH-02: Gửi OTP tới SĐT sai định dạng -> Báo lỗi 400 kèm `detail`.
   - TC-AUTH-03: Gửi OTP 2 lần trong 60 giây -> Báo lỗi 429 Too Many Requests.
   - TC-AUTH-04: Xác thực OTP đúng -> Cấp JWT Token và thông tin User.
   - TC-AUTH-05: Xác thực OTP sai -> Báo lỗi 400 và đếm số lần còn lại.
   - TC-AUTH-06: Đăng nhập Admin đúng email/password -> Trả JWT Token.
   - TC-AUTH-07: Đăng nhập sai 5 lần -> Khóa tài khoản 15 phút (423 Locked).
   - TC-AUTH-08: Xác thực 2FA TOTP đúng và sai.
2. **Catalog & Pagination Tests (8 tests):**
   - TC-CAT-01: `GET /destinations?page_size=100` -> `total >= 100`, có `items`.
   - TC-CAT-02: `GET /destinations/{id}` -> Đúng thông tin kèm `related_destinations`.
   - TC-CAT-03: `GET /restaurants?page_size=100` -> `total >= 60`.
   - TC-CAT-04: Lọc nhà hàng theo ẩm thực `cuisine_type`.
   - TC-CAT-05: `GET /provinces` -> Đủ 10 tỉnh thành.
   - TC-CAT-06: `GET /local-foods` -> Danh sách đặc sản.
   - TC-CAT-07: Báo cáo sai thông tin địa điểm `POST /destinations/{id}/report`.
   - TC-CAT-08: Phân trang trang 2, kích thước trang.
3. **Places & Corridor Search Tests (8 tests):**
   - TC-COR-01: `GET /places/nearby?kinds=gas` -> `total >= 1`.
   - TC-COR-02: `POST /places/along-route` với polyline Hà Nội -> `count >= 1`.
   - TC-COR-03: `GET /places/suggest?q=hoi an` -> Trả về danh sách gợi ý.
   - TC-COR-04: `GET /places/suggest` tìm không dấu tiếng Việt ("sai gon" -> ra "Sài Gòn").
   - TC-COR-05: `POST /restaurants/corridor-search` tìm quán trong hành lang 2km.
   - TC-COR-06: Kiểm tra cự ly lệch đường `detour_distance_km` và `route_progress_pct`.
   - TC-COR-07: Thêm và xóa lịch sử tìm kiếm `search_history`.
   - TC-COR-08: Tải lại từ cache trong 24h không bị mất.
4. **Trips & Expenses Tests (8 tests):**
   - TC-TRIP-01: Tạo chuyến đi với `X-Guest-Token`.
   - TC-TRIP-02: Người khác không có guest token -> Trả 404 Not Found.
   - TC-TRIP-03: Thêm điểm dừng vào Ngày 1.
   - TC-TRIP-04: Đổi thứ tự điểm dừng `reorder`.
   - TC-TRIP-05: Chia sẻ chuyến đi nhận `share_token`.
   - TC-TRIP-06: Thêm chi phí vào chuyến đi `POST /expenses`.
   - TC-TRIP-07: Tính toán `budget-summary` tổng tiền đã tiêu và cảnh báo vượt ngân sách.
   - TC-TRIP-08: Sinh lịch trình tự động `POST /generate`.
5. **Reviews & Admin Tests (8 tests):**
   - TC-REV-01: Viết review cho địa điểm `POST /reviews/{place_key}`.
   - TC-REV-02: Tóm tắt phân bổ sao `GET /reviews/{place_key}/summary`.
   - TC-ADM-01: `GET /admin/dashboard` thống kê đủ các mục KPI.
   - TC-ADM-02: User thường gọi Admin API -> Báo 403 Forbidden.
   - TC-ADM-03: Admin thêm mới Destination.
   - TC-ADM-04: Admin cập nhật quyền cho User `PUT /users/{id}/role`.
   - TC-ADM-05: Ghi nhận Audit Log sau mỗi thao tác quản trị.
   - TC-ADM-06: Endpoint `/health/ready` kiểm tra DB thật trả `{"database": "ok"}`.

### 9.2. Kiểm Thử Khách Tuyến (External Validation)
1. Chạy `tools/smoke_test.py`:
   ```bash
   python tools/smoke_test.py --base-url http://127.0.0.1:8000
   ```
   Bắt buộc đạt **7/7 PASS**:
   - `[PASS] GET /health — status=ok`
   - `[PASS] GET /health/ready — database=ok`
   - `[PASS] GET /destinations (>=100) — total=168`
   - `[PASS] GET /restaurants (>=60) — count=77`
   - `[PASS] GET /places/nearby?kinds=gas — gas>=1`
   - `[PASS] POST /places/along-route — stops>=1`
   - `[PASS] GET /places/suggest?q=hoi an — items>=1`
2. Chạy `flutter test`: Đạt **14/14 test cases PASS**.
3. Chạy `npm run build` trong `admin-web`: Đạt **build thành công không lỗi**.

---

## 10. KẾ HOẠCH DỌN DẸP & DI CHUYỂN DỰ ÁN (PHASE 8)

Khi toàn bộ các tiêu chí DoD đã được đáp ứng 100%:
1. Đảm bảo tag git `archive/fastapi` đã có trên remote.
2. Xóa bỏ backend cũ bằng Python trong thư mục `backend/`.
3. Đổi tên thư mục `backend-dotnet` thành `backend`.
4. Cập nhật `docker-compose.yml`:
   - Dịch vụ `backend` trỏ Dockerfile sang .NET 10 Web API.
   - Healthcheck gọi `http://127.0.0.1:8000/health/ready`.
5. Cập nhật tài liệu `README.md` phản ánh đúng 100% kiến trúc Backend ASP.NET Core .NET 10, Entity Framework Core và PostgreSQL.

---

## 11. BẢNG PHÂN CÔNG & HƯỚNG DẪN CODER AGENT (ACTION PLAN)

| Bước | Nhiệm vụ chi tiết | File / Thư mục đích |
| :---: | :--- | :--- |
| **Bước 1** | Hoàn thiện Solution và cài đặt NuGet packages cho `TripFlow.Api.csproj` và tạo `TripFlow.Tests.csproj`. | `backend-dotnet/TripFlow.Api.csproj`<br>`backend-dotnet/TripFlow.Tests/TripFlow.Tests.csproj` |
| **Bước 2** | Triển khai toàn bộ 22 Entity Models và cấu hình Fluent API trong `TripFlowDbContext`. | `backend-dotnet/Models/Entities/*.cs`<br>`backend-dotnet/Data/TripFlowDbContext.cs` |
| **Bước 3** | Triển khai Database Seeder Idempotent (10 tỉnh, 168 địa điểm, 77 quán ăn, 50 điểm nghỉ chân) và SQL Reset Sequences. | `backend-dotnet/Data/DatabaseSeeder.cs`<br>`backend-dotnet/Data/SeederExtensions.cs` |
| **Bước 4** | Triển khai AuthService, TokenService, SmsService, Bcrypt, Otp.NET và AuthController đầy đủ các endpoints. | `backend-dotnet/Services/*`<br>`backend-dotnet/Controllers/AuthController.cs` |
| **Bước 5** | Triển khai GeoService (Bounding Box + Point-to-Line Projection) và PlacesService, MapsService. | `backend-dotnet/Services/GeoService.cs`<br>`backend-dotnet/Controllers/PlacesController.cs` |
| **Bước 6** | Triển khai TripsController, ExpensesController, ReviewsController, FavoritesController, AssistantController, HealthController. | `backend-dotnet/Controllers/*.cs` |
| **Bước 7** | Triển khai AdminController đầy đủ (Dashboard KPI, Upload, Catalog CRUD, User Roles, Audit Logs, Crawl Jobs). | `backend-dotnet/Controllers/AdminController.cs` |
| **Bước 8** | Cấu hình Program.cs: SnakeCaseLower, StringEnumConverter, ErrorEnvelopeMiddleware, CORS, Swagger. | `backend-dotnet/Program.cs`<br>`backend-dotnet/Middleware/ErrorEnvelopeMiddleware.cs` |
| **Bước 9** | Viết và chạy >= 40 Unit & Integration Tests trong `TripFlow.Tests`. | `backend-dotnet/TripFlow.Tests/*.cs` |
| **Bước 10** | Chạy `tools/smoke_test.py` pass 7/7, Flutter test 14/14, Admin Web build OK. Dọn dẹp và cập nhật README. | `tools/smoke_test.py`<br>`README.md` |

---
*Bản kế hoạch được phê duyệt bởi **Planner Agent (Brain)**. Chuyển giao ngay cho **Coder Agent** để hiện thực hóa.*
