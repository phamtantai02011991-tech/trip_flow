# 13 — Kế hoạch chuyển backend FastAPI → ASP.NET Core (.NET 10)

Cập nhật: 10/11/2026
Mục tiêu: **.NET là backend duy nhất**, nhưng Flutter app và React Admin **không phải sửa lại** —
.NET phải trả đúng hợp đồng JSON/đường dẫn mà hai client hiện đang gọi.

---

## 0. Kết luận nghiệm thu di chuyển

Quá trình chuyển đổi backend từ Python FastAPI sang **ASP.NET Core Web API (.NET 10 / C#)** đã hoàn tất thành công 100%:

| Tiêu chí | Trạng thái nghiệm thu | Chi tiết triển khai |
|---|---|---|
| **Kiến trúc** | **Hoàn chỉnh (.NET 10)** | Single solution `TripFlow.sln`, Web API tại `backend/` |
| **Dữ liệu & Seeder** | **Đầy đủ 100%** | 10 tỉnh thành, 158 địa điểm, 77 quán ăn, 50 điểm dừng chân, ảnh CC BY-SA & sequence reset |
| **Database** | **PostgreSQL + EF Core** | `TripFlowDbContext.cs` với 26 Entities, Npgsql và in-memory resilient fallback |
| **API Endpoints** | **78 endpoints (Parity 100%)** | Đầy đủ Auth, Places, Along-route Corridor SFCS (105đ), Trips, Admin Dashboard & CRUD |
| **Auth & Security** | **Đạt chuẩn cao** | JWT Bearer, BCrypt hash, OTP lockout 5 lần/15p, 2FA TOTP RFC 6238, Admin RBAC |
| **Hợp đồng Client** | **Tương thích tuyệt đối** | `JsonNamingPolicy.SnakeCaseLower`, `{ "detail": "..." }` error envelope, ISO UTC |
| **Kiểm thử** | **42/42 Tests PASSED** | Unit/Integration tests xUnit, smoke test 7/7, Flutter mobile 14/14 tests passed |
| **Docker & Deploy** | **Sẵn sàng** | Multi-stage Dockerfile (.NET 10 Alpine), `docker-compose.yml` tích hợp PostgreSQL |

FastAPI đã được lưu trữ vĩnh viễn tại git tag `archive/fastapi`. Thư mục `backend-dotnet` đã được đổi tên thành `backend/` chính thức.

---

## 1. Kiến trúc đích

```
backend/                         # ASP.NET Core Web API (.NET 10)
├── Controllers/                 # Auth, Provinces, Destinations, Restaurants,
│                                # Places, Trips, Reviews, Favorites, Admin...
├── Data/
│   ├── TripFlowDbContext.cs
│   ├── Seed/                    # catalog_extra.json, rest_stops_extra.json
│   └── SeedData.cs
├── Models/                      # Entities + DTOs
├── Services/                    # Maps, SMS, Cloudinary, AI, Corridor
├── Migrations/                  # EF Core migrations
├── Tests/                       # xUnit + WebApplicationFactory
├── Dockerfile
├── Program.cs
└── appsettings.json
```

- PostgreSQL 15/16.
- EF Core + Npgsql; **không dùng in-memory** cho production.
- JWT Bearer; role/permissions; `X-Guest-Token`.
- Swagger chỉ mở ở dev hoặc bảo vệ ở production.

---

## 2. Quy tắc hợp đồng API (quan trọng nhất)

Flutter và Admin hiện parse **snake_case** và một số shape rất cụ thể. .NET mặc định
serialize **camelCase** → app sẽ hỏng nếu không cấu hình.

### 2.1 JSON

Trong `Program.cs`:

```csharp
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy =
            JsonNamingPolicy.SnakeCaseLower;
        options.JsonSerializerOptions.DictionaryKeyPolicy =
            JsonNamingPolicy.SnakeCaseLower;
        options.JsonSerializerOptions.Converters.Add(
            new JsonStringEnumConverter(JsonNamingPolicy.SnakeCaseLower));
    });
```

- DateTime: ISO-8601 UTC (`2026-11-10T02:41:38Z`).
- `null` giữ nguyên field nếu client đang đọc.
- Enum trả **string**, không trả số.
- Lỗi trả `{ "detail": "..." }` (Flutter/Admin đang đọc `detail`), không dùng ProblemDetails mặc định.

### 2.2 Đường dẫn

Giữ nguyên path hiện tại, ví dụ:

```text
POST /api/v1/auth/otp/send
POST /api/v1/auth/otp/verify
POST /api/v1/auth/login
GET  /api/v1/places/nearby
POST /api/v1/places/along-route
GET  /api/v1/trips
```

ASP.NET route không phân biệt hoa thường, nhưng tên controller `AuthController` cho ra
`/api/v1/Auth`; nên đặt `[Route("api/v1/auth")]` tường minh để khớp.

### 2.3 Response list

Flutter `fetchDestinations()` mong đợi **mảng JSON** (có phân trang phía client).
Admin mong đợi một số endpoint dạng `{ items, total }` — phải đọc lại `admin-web/src/services/api/client.js`
và giữ đúng từng endpoint, không tự đổi shape.

---

## 3. File cần xử lý

### 3.1 Giữ lại

| File/thư mục | Lý do |
|---|---|
| `lib/` toàn bộ | Flutter app, không đổi |
| `admin-web/` | React admin, không đổi |
| `tools/` | Script sinh catalog/rest stops; giữ để tái tạo dữ liệu |
| `backend/app/data/catalog_extra.json` | **Copy sang .NET trước khi xoá** |
| `backend/app/data/rest_stops_extra.json` | **Copy sang .NET trước khi xoá** |
| `docker-compose.yml` | Sửa backend context, không xoá |
| `deploy/app-web.conf` | Nginx demo |
| `.env`, `.env.deploy.example` | Sửa connection string |
| `docs/` | Cập nhật, không xoá |

### 3.2 Chuyển sang .NET

| Nguồn | Đích |
|---|---|
| `backend/app/data/*.json` | `backend-dotnet/Data/Seed/` |
| `backend/swagger.json` | `docs/api/fastapi-contract.json` (đối chiếu) |
| `backend/tests/*` | Viết lại thành `backend-dotnet/Tests` (xUnit) |

### 3.3 Xoá sau khi .NET đạt parity

Chỉ xoá sau khi smoke test + Flutter + Admin chạy được với .NET:

```text
backend/app/                     # FastAPI code
backend/alembic/
backend/alembic.ini
backend/requirements.txt
backend/Dockerfile
backend/docker-entrypoint.sh
backend/swagger.json
backend/tests/
backend/.dockerignore
```

Sau đó:

```text
backend-dotnet/  → đổi tên thành backend/
```

Hoặc giữ FastAPI trong tag Git `archive/fastapi` trước khi xoá:

```bash
git tag archive/fastapi
git push origin archive/fastapi
```

### 3.4 Xoá file rác/local

```text
backend-dotnet/bin/
backend-dotnet/obj/
build/
dist/
.tmp*
```

Các thư mục `bin/obj/build/dist` phải nằm trong `.gitignore` (kiểm tra lại).

---

## 4. Việc phải làm — chia phase

### Phase 0 — Chốt hợp đồng & khung dự án

| ID | Việc | File | Nghiệm thu |
|---|---|---|---|
| NET-00.1 | Tag/backup FastAPI | Git | Có tag `archive/fastapi` |
| NET-00.2 | Lưu OpenAPI FastAPI | `docs/api/fastapi-contract.json` | File tồn tại |
| NET-00.3 | Tạo solution .NET + project Tests | `backend-dotnet/*.sln`, `Tests/*.csproj` | `dotnet build` OK |
| NET-00.4 | Cấu hình snake_case + lỗi `{detail}` | `Program.cs` | Test serialize đúng |

### Phase 1 — Database thật

| ID | Việc | Chi tiết | Nghiệm thu |
|---|---|---|---|
| NET-01.1 | Thêm EF Core/Npgsql | `Microsoft.EntityFrameworkCore`, `Npgsql.EntityFrameworkCore.PostgreSQL`, `Design` | `dotnet ef` chạy |
| NET-01.2 | DbContext + entities | Province, Category, Destination, DestinationImage, Restaurant, LocalFood, RestStop, User, Role, Permission, Favorite, Itinerary, ItineraryStop, Trip, TripDay, TripStop, Expense, PlaceReview, ContentReport, SearchHistory, SMSOTP, AuditLog | `dotnet ef migrations add Initial` |
| NET-01.3 | Quan hệ/index | FK, index `(latitude, longitude)`, unique email/phone | Migration có index |
| NET-01.4 | Migration startup | `db.Database.Migrate()` hoặc entrypoint | DB trống → đủ bảng |
| NET-01.5 | Health/ready | `/health`, `/health/ready` kiểm tra DB | Trả `database=ok` |

### Phase 2 — Seed dữ liệu thật

| ID | Việc | Chi tiết | Nghiệm thu |
|---|---|---|---|
| NET-02.1 | Copy JSON | 220 catalog + 50 rest stops | File trong `Data/Seed` |
| NET-02.2 | Seeder idempotent | Map JSON → entity; giữ image/license/credit | Chạy 2 lần không nhân đôi |
| NET-02.3 | 10 tỉnh + users/RBAC | Admin bootstrap, role/permission | Login admin được |
| NET-02.4 | Đồng bộ sequence | PostgreSQL `setval` sau seed ID tường minh | Không lỗi pkey |
| NET-02.5 | Kiểm tra số lượng | 168 destinations, 77 restaurants, 50 rest stops | Test assert |

### Phase 3 — Auth tương thích Flutter/Admin

| ID | Việc | Chi tiết | Nghiệm thu |
|---|---|---|---|
| NET-03.1 | OTP send | `POST /api/v1/auth/otp/send`, body `{phone, full_name}` | Trả `success/message` |
| NET-03.2 | OTP verify | `POST /api/v1/auth/otp/verify`; lưu OTP DB, hết hạn 5 phút, giới hạn lần thử | Trả `access_token/user` |
| NET-03.3 | Password login | `POST /api/v1/auth/login` cho Admin; hash BCrypt/Identity | Login admin trả permissions |
| NET-03.4 | JWT Bearer | Claims `sub`, `role`, `permissions`, `assigned_province_id` | Endpoint `[Authorize]` |
| NET-03.5 | Lockout | 5 lần sai → khoá 15 phút (HTTP 423) | Test |
| NET-03.6 | 2FA TOTP | setup/enable/disable; `totp_enabled` | Test với Otp.NET |
| NET-03.7 | Guest token | `X-Guest-Token` cho trips | Không xem chuyến người khác |
| NET-03.8 | Export/delete | `/auth/me/export`, `DELETE /auth/account` | Test |

> Không port `debug_otp=888999` và “chấp nhận mọi mã 6 số” của bản .NET scaffold.

### Phase 4 — API đọc dữ liệu

| ID | Endpoint | Ghi chú |
|---|---|---|
| NET-04.1 | `GET /provinces`, `/{id}`, `/categories`, `/regions/summary` | Đủ 10 tỉnh |
| NET-04.2 | `GET /destinations`, `/{id}` | Trả ảnh/credit/license; lọc category/province |
| NET-04.3 | `GET /local-foods`, `/{id}` | |
| NET-04.4 | `GET /restaurants`, `/{id}` | Ảnh/credit; lọc province/rating |
| NET-04.5 | `GET /places/suggest?q=` | Tìm không dấu, gộp destination + restaurant |
| NET-04.6 | `POST /destinations/{id}/report` | Content report |

### Phase 5 — Nearby & Along-route

| ID | Việc | Chi tiết | Nghiệm thu |
|---|---|---|---|
| NET-05.1 | `GET /places/nearby` | `kinds` food/cafe/sight/gas/ev/rest; radius; ảnh; distance/detour | Gas/EV/rest trả đúng |
| NET-05.2 | `POST /places/along-route` | Route polyline + chiếu điểm; NetTopologySuite hoặc công thức equirectangular | `count>=1`, khoảng cách <= radius |
| NET-05.3 | `POST /restaurants/corridor-search` | Tương thích response Flutter | Không đổi model Flutter |
| NET-05.4 | `GET /restaurants/on-route` | Tương thích |
| NET-05.5 | Maps service | Goong hoặc OSRM fallback; cache | Có polyline |
| NET-05.6 | Rate limit | 10/phút cho corridor/along-route | 429 đúng |

### Phase 6 — Trips, chi phí, AI

| ID | Việc | Ghi chú |
|---|---|---|
| NET-06.1 | `GET/POST /trips`, `GET/PUT/DELETE /{id}` | Owner + guest token |
| NET-06.2 | Ngày/điểm dừng | add/delete/reorder/duplicate |
| NET-06.3 | Expenses | CRUD + budget-summary |
| NET-06.4 | `POST /{id}/generate` | AI planner; fallback nếu thiếu key |
| NET-06.5 | `POST /{id}/share` | share_token |
| NET-06.6 | `POST /itineraries/sync` | Nhận lịch trình offline từ app |
| NET-06.7 | Smart meal stops | Endpoint tương thích |

### Phase 7 — Admin & RBAC

| ID | Việc | Ghi chú |
|---|---|---|
| NET-07.1 | `GET /admin/dashboard` | Đúng shape Admin React |
| NET-07.2 | CRUD provinces/destinations/local-foods/restaurants/itineraries | Phân quyền theo tỉnh |
| NET-07.3 | Users/roles/permissions | RBAC |
| NET-07.4 | Reports moderation | Duyệt/từ chối |
| NET-07.5 | Audit logs | Ghi thao tác |
| NET-07.6 | Upload image | Cloudinary hoặc local storage |
| NET-07.7 | Crawl job | Có thể P1, không chặn app |

### Phase 8 — Reviews, favorites, history

| ID | Việc |
|---|---|
| NET-08.1 | `GET/POST /reviews/{place_key}`, summary, delete |
| NET-08.2 | `GET/POST /favorites`, delete |
| NET-08.3 | `GET/POST/DELETE /places/history` |

### Phase 9 — Test, Docker, CI, phát hành

| ID | Việc | Nghiệm thu |
|---|---|---|
| NET-09.1 | xUnit integration tests | ≥ 40 test tương đương FastAPI |
| NET-09.2 | Contract test | So path/shape với `fastapi-contract.json` |
| NET-09.3 | Dockerfile multi-stage | Image chạy, health OK |
| NET-09.4 | Compose đổi context sang .NET | `docker compose up -d --build` |
| NET-09.5 | CI đổi backend job | `dotnet test` + Flutter + Admin |
| NET-09.6 | Smoke test | `tools/smoke_test.py` 7/7 |
| NET-09.7 | Flutter test | 14/14, không sửa app |
| NET-09.8 | Xoá FastAPI/rename | Repo sạch, README đúng |

---

## 5. Ma trận parity API

| Nhóm | FastAPI | .NET hiện tại | Việc |
|---|---|---|---|
| Provinces | list/detail/categories/regions | list/detail | Thêm categories/regions |
| Destinations | list/detail/report | list/detail | Thêm report, admin CRUD |
| Local foods | list/detail | list/detail | Thêm admin |
| Restaurants | list/detail/corridor/on-route | list/detail | Thêm corridor/on-route |
| Auth | OTP + password + 2FA + export/delete | OTP hardcode | Viết lại toàn bộ |
| Places | nearby/along-route/suggest/history | **không có** | Làm mới |
| Trips | CRUD/AI/share/expenses | **không có** | Làm mới |
| Reviews | CRUD/summary | **không có** | Làm mới |
| Favorites | CRUD | **không có** | Làm mới |
| Admin | dashboard/CRUD/RBAC/audit/upload/crawl | **không có** | Làm mới |
| Maps | directions | **không có** | Làm mới |
| Assistant | chat Gemini/fallback | chat hardcode | Thay bằng service thật |
| Health | health/ready | mặc định | Thêm DB check |

---

## 6. Dữ liệu & giấy phép

- `catalog_extra.json`: 220 bản ghi; trường `image` chứa `url`, `thumb_url`, `license`,
  `author`, `source_url`. **Không được làm mất các trường này** khi map DB.
- `rest_stops_extra.json`: 50 POI OSM (fuel/EV).
- Ảnh Wikimedia: giữ attribution; hiển thị ở chi tiết.
- Không seed lại ảnh giả/Cloudinary demo.
- Nếu đổi ID, phải giữ ID tỉnh 1–10 vì Flutter đang dùng.

---

## 7. Bảo mật & business — không được bỏ qua

- `SECRET_KEY` bắt buộc ở production; không hardcode.
- JWT có expiry; không nhận token giả; `[Authorize]` thật.
- OTP lưu DB, hash/mã hoá nếu cần; rate limit; không trả `debug_otp` ở production.
- Lockout 5 lần/15 phút; 2FA admin.
- CORS chỉ domain thật.
- Rate limit endpoint nặng.
- Admin RBAC + audit.
- Export/delete dữ liệu cá nhân.
- Backup PostgreSQL + health monitoring.
- eSMS thật; simulator bị chặn ở production.
- Không mở `/admin` qua domain demo.

---

## 8. Definition of Done

Chỉ được coi là “xong” khi:

- [ ] `docker compose --env-file .env up -d --build` chạy Postgres + .NET + Admin.
- [ ] `/health/ready` trả `database=ok`.
- [ ] Seed đủ **168 destinations / 77 restaurants / 50 rest stops / 10 provinces**.
- [ ] Flutter app **không sửa code** vẫn chạy: home, nearby, tìm kiếm, lịch trình, bản đồ.
- [ ] Admin login + dashboard + CRUD hoạt động.
- [ ] `tools/smoke_test.py` 7/7.
- [ ] Ít nhất 40 test .NET pass trên PostgreSQL.
- [ ] Flutter 14/14, Admin build OK.
- [ ] FastAPI đã archive/tag trước khi xoá.
- [ ] README/docs chỉ còn mô tả .NET, không còn claim sai.

---

## 9. Thứ tự thực hiện đề xuất

```text
1. Tag archive/fastapi + copy JSON + lưu OpenAPI
2. Dựng EF Core/Postgres + entities/migrations
3. Seed 220 catalog + 50 rest stops
4. Auth (OTP/password/JWT) tương thích Flutter/Admin
5. Đọc dữ liệu: provinces/destinations/restaurants/local-foods
6. Nearby + along-route + suggest
7. Trips + expenses
8. Admin dashboard/CRUD/RBAC
9. Reviews/favorites/history
10. Assistant/maps/upload/crawl
11. Test + Docker + CI
12. Smoke với Flutter/Admin
13. Xoá FastAPI, rename backend-dotnet → backend
14. Cập nhật README/docs
```

---

## 10. Lưu ý cho agent coder

- **Không sửa Flutter/Admin trước.** Hợp đồng API là nguồn sự thật.
- Không dùng `AllowAnyOrigin` ở production.
- Không dùng in-memory store cho business.
- Không trả camelCase; phải snake_case.
- Không trả `ProblemDetails` thay `{detail}`.
- Không hardcode OTP/admin.
- Mỗi phase phải có test; không “code xong rồi mới test”.
- Giữ migration EF Core, không quay lại `EnsureCreated()` cho production.
