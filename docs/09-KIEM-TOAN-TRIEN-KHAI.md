# 09 — Kiểm toán toàn diện & mức độ sẵn sàng triển khai kinh doanh

**Ngày kiểm toán:** 06/11/2026
**Phạm vi:** toàn bộ monorepo `D:\trip_flow` (Flutter app, FastAPI backend, React Admin, hạ tầng Docker)
**Người thực hiện:** kiểm toán độc lập, chạy lại thực tế trên máy — không dựa vào báo cáo cũ.

---

## 1. Kết luận điều hành

**Hệ thống hiện tại = MVP kỹ thuật chạy được, CHƯA đủ điều kiện go-live thương mại.**

| Câu hỏi | Trả lời ngắn |
|---|---|
| Hệ thống có chạy hoàn toàn không? | **Có, ở mức MVP**: backend khởi động, seed DB, 71 endpoint; app Flutter build được; admin build được. |
| Các luồng đã giống app business chưa? | **Chưa.** Luồng khám phá/lập lộ trình tạm ổn; luồng **đặt phòng – vé – tour – thanh toán – hoàn huỷ – thông báo** hoàn toàn chưa có thật. |
| Có deploy được ngay không? | **Chưa.** Thiếu SMS thật, thanh toán, đơn hàng, giám sát, backup, pháp lý; và tồn tại lỗi bảo mật P0 vừa được vá một phần. |
| Tài liệu cũ có đáng tin? | **Không.** README/review_report tuyên bố "22/22 PASSED, 1.200+ điểm đến, 63 tỉnh" trong khi dữ liệu thật là 28 điểm đến/10 tỉnh và test từng fail. |

### 1.1. Bằng chứng kiểm chứng (chạy thật, không suy đoán)

| Hạng mục | Lệnh | Kết quả thực tế |
|---|---|---|
| Backend test | `python -m pytest` | **40 passed** (catalog/10 tỉnh/ảnh/điểm nghỉ/along-route/privacy/lockout/2FA/migration/eSMS) |
| Backend runtime | `uvicorn app.main:app` + gọi API | `/health`, `/health/ready` OK; login admin OK; 10 provinces; 8 destinations HCM; 15 POI nearby; tạo trip + chi phí + budget OK; OpenAPI **71 paths** |
| Flutter analyze | `dart analyze lib test` | **0 error, 0 warning**, 85 info/deprecation |
| Flutter test | `flutter test` | **14/14 passed** |
| Flutter build | `flutter build web --release` | **Built build\web** thành công |
| Admin build | `npm run build` | **1545 modules**, bundle 417 KB (gzip 116 KB) thành công |
| Docker compose | `docker compose up -d --build` | ✅ **Đã build & chạy thật**: Postgres 15 healthy, backend healthy (`/health/ready`), admin web 200 |
| PostgreSQL trong Docker | `tripflow_postgres_db` | ✅ 168 địa điểm / 77 quán ăn / 50 điểm nghỉ sau seed |

---

## 2. Những gì đã sửa trong phiên kiểm toán này

### 2.1. Lỗi chặn khởi động (P0) — backend không thể tạo DB

**Triệu chứng:** `python -m pytest` fail ngay khi seed:
`ValueError: Datetime values must have timezone information` → không thể INSERT bất kỳ bản ghi nào.

**Nguyên nhân:** `requirements.txt` để `sqlmodel>=0.0.16`, môi trường cài `sqlmodel 0.0.48` + `SQLAlchemy 2.1.3`.
Từ bản mới, SQLModel map mọi field `datetime` sang `UTCDateTime` và **bắt buộc** giá trị phải có timezone,
trong khi toàn bộ code dùng `datetime.utcnow()` (naive).

**Đã sửa:**
- Toàn bộ model (`models.py`, `trip.py`, `place.py`, `review.py`, `crawl_job.py`) dùng
  `datetime.now(timezone.utc)`.
- Toàn bộ service/endpoint/seed chuyển sang UTC có timezone (auth, admin, crawler, itinerary, trip, expense, maps, places, AI planner).
- Thêm `app/core/time.py` (`utcnow()`, `as_utc()`) và chuẩn hoá `arrive_at` / `spent_at` do client gửi lên.
- Ghim phiên bản chính xác trong `backend/requirements.txt` (thay vì `>=`).

**Kết quả:** seed + 71 endpoint + 21 test chạy được.

### 2.2. Lỗi bảo mật P0

| Lỗi | Mức | Đã sửa |
|---|---|---|
| **IDOR lịch trình**: `GET/PUT/DELETE /itineraries/{id}`, thêm stop, smart-meal không kiểm tra chủ sở hữu; khách chưa đăng nhập thấy **toàn bộ** lịch trình | P0 | Thêm `get_current_user`, `_require_itinerary_owner`, trả 404 khi không phải chủ; guest chỉ thấy template công khai |
| **Chuyến của khách vãng lai ai biết ID cũng xem/sửa** | P0 | Thêm `guest_token` theo thiết bị (`X-Guest-Token`); list/get/update/delete đều kiểm tra chủ sở hữu |
| **Sync ghi đè lịch trình người khác** qua `server_id` | P0 | Chỉ update khi `existing.user_id == current_user.id`, ngược lại tạo bản mới |
| **OTP lộ mã**: `/auth/otp/send` luôn trả `debug_otp` | P0 | Chỉ trả khi `DEV_OTP_ENABLED=1` **và** không phải production |
| **Bypass OTP ở app**: mất mạng → nhập **bất kỳ 6 số** hoặc `888999` là đăng nhập thành công bằng token giả | P0 | Xoá hoàn toàn fallback; app báo lỗi kết nối, xác thực chỉ do server quyết định |
| **Admin auto-login Super Admin** khi mở web | P0 | Bắt buộc đăng nhập; không còn user mặc định |
| **Admin login mock**: backend tắt → đăng nhập bằng email demo + **mật khẩu bất kỳ** | P0 | Chỉ bật khi `VITE_DEMO_MODE=true`; production tắt mặc định |
| **Seed tài khoản demo** (`Admin@123`…) luôn chạy, kể cả production | P0 | Gate bằng `SEED_DEMO`; production dùng `BOOTSTRAP_ADMIN_EMAIL/PASSWORD` |
| **CORS `*` + credentials** | P1 | Đọc `CORS_ORIGINS`, danh sách method/header cụ thể |
| **SECRET_KEY mặc định ở production** | P1 | Từ chối khởi động nếu production + secret mặc định |
| **Log OTP ra console/log** | P1 | Bỏ mã khỏi log; chỉ log số điện thoại đã che |

### 2.3. Lỗi dữ liệu / logic

| Lỗi | Đã sửa |
|---|---|
| Chống trùng lặp crawler dùng `ILIKE`; SQLite không fold chữ Việt → `CƠM` ≠ `Cơm` | Thêm so sánh `str.casefold()` chuẩn Unicode |
| App không đồng bộ backend khi mở | `MainNavigationShell.initState` gọi `syncFromBackend()` (mock chỉ còn là fallback) |
| Token đăng nhập không được gắn vào Trips/Places/Assistant API | Thêm `authInterceptor()` dùng chung + `AppConfig.authToken` |
| `syncItineraryToBackend` fail vẫn đánh dấu "đã đồng bộ" | Chỉ đánh dấu khi server trả thành công |
| `TripFlowAppState` bỏ qua `dioClient` truyền vào (không test được) | Dùng đúng client được inject |
| Tìm tỉnh theo mô tả gây nhiễu ("Phú Quốc" ra 2 tỉnh) | Chỉ tìm theo tên/mã/vùng |
| UI ghi "63 tỉnh", "1.200+ điểm đến", "#1 Việt Nam", "100% xác minh" | Sửa thành số liệu thật: 10 tỉnh, 28 điểm đến, "dữ liệu biên tập" |

### 2.4. Hạ tầng triển khai

- `backend/Dockerfile`: Python 3.12, user không root, healthcheck `/health/ready`.
- `admin-web/Dockerfile` + `nginx.conf`: build tĩnh, reverse proxy `/api` → backend, SPA fallback, nén gzip.
- `docker-compose.yml`: Postgres bắt buộc password, backend healthcheck, admin chờ backend healthy, **không** mở cổng DB.
- `.env.deploy.example` (root) + `backend/.env.example` + `admin-web/.env.example`.
- `.dockerignore` cho backend/admin (tránh copy `node_modules`, `.env`).
- API mới `/health/ready` kiểm tra kết nối DB.

### 2.5. Kiểm thử

- Thêm `backend/tests/test_modules.py` (6 test): trips CRUD + chi phí + budget, itinerary auth/IDOR, places nearby, cô lập chuyến khách vãng lai, OTP không lộ mã, health/readiness.
- Cập nhật test cũ theo hành vi bảo mật mới (itinerary cần đăng nhập, OTP không trả mã).
- Flutter: thêm fake API client để test luồng OTP thành công mà không cần backend thật.
- Kết quả: backend 40/40, Flutter 14/14.

---

## 3. Bản đồ hiện trạng hệ thống

### 3.1. Kiến trúc thực tế

```
Flutter (lib/)
 ├─ Catalog cũ (home, provinces, destinations, foods, restaurants, services)
 │    └─ TripFlowAppState + MockDataRepository ──(sync 1 chiều)──> FastAPI catalog
 │         ⚠️ phần lớn vẫn đọc mock; backend chỉ ghi đè khi sync thành công
 ├─ Module mới (trips, nearby, assistant, expenses, reviews)
 │    └─ TripsApi / PlacesApi / AssistantApi ──> FastAPI (bắt buộc backend)
 └─ Auth
      └─ OTP SMS (server) — không còn bypass offline

FastAPI (backend/app/)
 ├─ 15 router, 71 path: auth, provinces, destinations, foods, restaurants,
 │   itineraries, favorites, admin, crawler, trips, expenses, places,
 │   assistant, maps, reviews
 ├─ SQLModel + SQLite (dev) / PostgreSQL 16 (prod, đã test 36/36)
 ├─ AI: Gemini (planner + assistant) — cần API key hợp lệ
 └─ Maps: OSRM routing (miễn phí), Goong tiles/key — chưa cấu hình

React Admin (admin-web/)
 └─ 11 trang CRUD + RBAC + audit; gọi API thật, demo mode tắt mặc định
```

### 3.2. Dữ liệu thật trong DB seed

| Thực thể | Số lượng |
|---|---|
| Tỉnh/thành | 10 |
| Địa điểm du lịch | 28 |
| Nhà hàng/quán ăn | 26 |
| Đặc sản | 24 |
| Lịch trình mẫu | 11 |
| Tài khoản demo | 5 (chỉ khi `SEED_DEMO=1`) |

> README cũ ghi "63 tỉnh, 1.200+ điểm đến" — **không đúng**.

---

## 4. Trạng thái từng module (theo luồng người dùng)

Ký hiệu: ✅ chạy thật · 🟡 một phần/demo · 🔴 chưa có

| # | Luồng nghiệp vụ | Backend | App | Admin | Đánh giá |
|---|---|---|---|---|---|
| 1 | Đăng ký / đăng nhập OTP | ✅ API, rate limit 60s, 5 lần thử | ✅ UI OTP | — | 🟡 Cần SMS gateway thật; chưa có refresh token, logout phía server |
| 2 | Khám phá tỉnh/địa điểm/đặc sản | ✅ CRUD + đọc | 🟡 mock-first, sync khi mở app | ✅ | 🟡 Ảnh hotlink Wikimedia/Unsplash, rating tĩnh từ seed |
| 3 | Tìm quán ăn dọc lộ trình (corridor) | ✅ Goong/Shapely + fallback | ✅ | ✅ | 🟡 Phụ thuộc Goong key; chưa có dữ liệu giao thông thật |
| 4 | Tạo chuyến đi (wizard) | ✅ CRUD | ✅ | — | ✅ Hoạt động; khách vãng lai vẫn tạo được (xem P1) |
| 5 | AI lập lộ trình | ✅ grounded + validate | ✅ | — | 🟡 Cần Gemini key; prompt/model chưa được kiểm thử với key thật |
| 6 | Bản đồ & chỉ đường | ✅ OSRM/Goong | ✅ flutter_map | — | 🟡 Tile đang dùng key demo (400), OSRM public không SLA |
| 7 | Quản lý chuyến đi, chia sẻ | ✅ share token | 🟡 | — | 🟡 Chưa có trang public xem link chia sẻ trên web |
| 8 | Chi phí chuyến đi | ✅ | ✅ | — | ✅ |
| 9 | Trợ lý AI | ✅ Gemini + fallback rule | ✅ | — | 🟡 Fallback offline chỉ là rule-based, không phải AI |
| 10 | Đánh giá của người dùng | ✅ API reviews | 🟡 | 🔴 không có duyệt review | 🟡 Có `is_hidden` nhưng không có endpoint/admin để ẩn |
| 11 | Báo cáo sai thông tin | ✅ | ✅ | ✅ | ✅ |
| 12 | **Đặt khách sạn** | 🔴 | 🔴 demo local | 🔴 | **Không có đơn hàng, tồn kho, giá, thanh toán** |
| 13 | **Đặt vé xe/tàu/máy bay** | 🔴 | 🔴 demo local | 🔴 | **Mã E-Ticket sinh bằng `DateTime.now()`, mất khi tắt app** |
| 14 | **Đặt tour** | 🔴 | 🔴 demo local | 🔴 | **Voucher giả, không gửi email/SMS** |
| 15 | **Thanh toán** | 🔴 | 🔴 | 🔴 | **Không có cổng thanh toán nào** |
| 16 | **Hoàn huỷ / đổi chỗ** | 🔴 | 🔴 | 🔴 | Chưa có |
| 17 | **Thông báo (email/push/SMS)** | 🔴 | 🔴 | 🔴 | Chưa có |
| 18 | Quản trị nội dung & RBAC | ✅ | — | ✅ | 🟡 10 request song song khi mở, chưa phân trang |
| 19 | Audit log | ✅ | — | ✅ | ✅ |
| 20 | Phân tích kinh doanh (doanh thu, booking) | 🔴 | — | 🔴 | Dashboard chỉ đếm nội dung |

**Kết luận luồng:** 8/20 luồng chạy thật; 8 luồng một phần; 4 luồng thương mại cốt lõi (đặt chỗ, thanh toán, hoàn huỷ, thông báo) **chưa tồn tại**.

---

## 5. So sánh với ứng dụng business (Booking/Klook/TripAdvisor)

| Năng lực bắt buộc của app du lịch thương mại | TripFlow hiện tại |
|---|---|
| Tìm kiếm & lọc theo ngày/giá/tiện ích | 🟡 Lọc theo tỉnh/loại/rating; **không lọc theo ngày, tồn kho, giá thật** |
| Tồn kho & giá theo ngày (availability) | 🔴 Không có |
| Giỏ hàng / đơn hàng / trạng thái đơn | 🔴 Không có |
| Thanh toán (VNPay/MoMo/ZaloPay/thẻ) | 🔴 Không có |
| Xác nhận tự động + e-voucher/e-ticket thật | 🔴 Mã sinh local, không lưu server |
| Hoàn huỷ/refund theo chính sách | 🔴 Không có |
| Đối tác & đối soát tài chính | 🔴 Không có |
| Đánh giá chỉ từ khách đã mua | 🔴 Không xác thực |
| Thông báo giao dịch | 🔴 Không có |
| Hỗ trợ khách hàng (chat/ticket) | 🔴 Hotline 1900 6868 là số minh hoạ |
| Phân quyền nhân sự & audit | ✅ Có, khá tốt |
| Bảo mật dữ liệu cá nhân | 🟡 JWT đã chuyển vào Keychain/Keystore (`flutter_secure_storage`), có migrate khỏi Hive; vẫn thiếu chính sách quyền riêng tư |
| Tuân thủ pháp lý (điều khoản, hoá đơn, ĐKKD) | 🟡 Đã có Điều khoản/Riêng tư/Giấy phép ảnh trong app; còn thiếu ĐKKD, hoá đơn, luật sư rà soát |

> **Điểm mạnh thực sự của TripFlow** không phải "super app đặt dịch vụ" mà là **công cụ lập lộ trình + tìm quán ăn dọc đường**. Nên định vị sản phẩm theo hướng này trước, rồi mới mở rộng sang booking.

---

## 6. Danh sách việc còn thiếu — ưu tiên để go-live

### P0 — Chặn go-live (bắt buộc trước khi mở cho khách)

| # | Việc | Ghi chú/đầu ra |
|---|---|---|
| P0-1 | ✅ **PostgreSQL + Alembic baseline** | 36/36 test pass trên PostgreSQL 16.2; baseline 26 bảng + migration 2FA, tự chạy khi container khởi động. Đã sửa 2 lỗi chỉ lộ trên Postgres: sequence sau seed ID tường minh, thứ tự xoá trip/days |
| P0-2 | 🟡 **eSMS — code đã kiểm thử, chưa có key thật** | Payload/endpoint/error xử lý đã có test mock; simulator bị chặn ở production. Cần key + brandname để gửi thật |
| P0-3 | ✅ **Đã làm — Quyền riêng tư dữ liệu** | `GET /auth/me/export` xuất JSON; `DELETE /auth/account?confirm=DELETE` xoá tài khoản + lịch trình/chuyến đi/đánh giá/yêu thích/lịch sử; UI trong Profile |
| P0-4 | ✅ **Đã làm — Lưu JWT an toàn** | Token nằm trong `flutter_secure_storage` (Keychain/Keystore); tự migrate token cũ khỏi Hive và xoá khỏi plaintext |
| P0-5 | ✅ **Đã làm — Bỏ booking khỏi bản phát hành** | Release tự ẩn Khách sạn/Vé/Tour (`showDemoBooking = !kReleaseMode`), hiện banner “đang hoàn thiện” |
| P0-6 | 🟡 **Bảo mật admin** | Lockout + **2FA TOTP** + UI setup trong admin + cờ `REQUIRE_ADMIN_2FA` chặn API quản trị nếu chưa bật. Cần IP/VPN + bật cờ sau khi admin setup |
| P0-7 | 🟡 **Pháp lý — một phần** | Đã có màn Điều khoản sử dụng, Chính sách riêng tư, Giấy phép ảnh/bản đồ trong app (Profile). Còn thiếu ĐKKD, hoá đơn, hotline thật và luật sư rà soát |
| P0-8 | **Backup & khôi phục** | `pg_dump` hằng ngày + lưu ngoài máy; chưa có |
| P0-9 | **Giám sát & log tập trung** | Healthcheck có, nhưng chưa có Sentry/metrics/alert |

### P1 — Cần cho vận hành nghiệp vụ (1–3 tuần sau go-live)

| # | Việc |
|---|---|
| P1-1 | Đơn hàng booking thật: bảng `orders`, `order_items`, trạng thái, thanh toán, hoàn tiền |
| P1-2 | Tích hợp thanh toán VNPay/MoMo/ZaloPay + webhook idempotent |
| P1-3 | Email/SMS xác nhận + push notification (FCM) |
| P1-4 | Trang quản trị đơn hàng/doanh thu/đối soát; phân trang + tìm kiếm |
| P1-5 | Duyệt/ẩn đánh giá; báo cáo review; chống spam |
| P1-6 | Upload ảnh thật lên Cloudinary (hiện chỉ nhận URL), xử lý ảnh lỗi |
| P1-7 | Refresh token + đăng xuất phía server + thu hồi phiên |
| P1-8 | Định vị GPS thật (`geolocator`) thay toạ độ cố định HCMC |
| P1-9 | CI/CD (lint + test + build) và môi trường staging |
| P1-10 | Rate limit login/register/verify; CAPTCHA; khoá tài khoản |
| P1-11 | Sửa đồng bộ lịch trình bị nhân bản (lưu `server_id`/`client_offline_id`) |
| P1-12 | Goong Maps key thật + fallback tile OSM có kiểm soát |

### P2 — Tăng trưởng & hoàn thiện

- Mở rộng lên 63 tỉnh, dữ liệu >1.000 điểm đến (cần đội nội dung + nguồn hợp pháp).
- Cá nhân hoá gợi ý, lịch sử, offline đầy đủ cho module mới.
- Đa ngôn ngữ (EN), accessibility, dark mode.
- Phân tích hành vi (Firebase/Mixpanel), A/B testing.
- Đối tác tự cập nhật (partner portal), hợp đồng & đối soát.
- Tối ưu hiệu năng: phân trang admin, cache ảnh, CDN.

---

## 7. Checklist triển khai (deploy)

### 7.1. Biến môi trường bắt buộc

```env
ENVIRONMENT=production
SECRET_KEY=<chuỗi ngẫu nhiên 48+ ký tự>        # bắt buộc, không dùng mặc định
DATABASE_URL=postgresql+psycopg2://user:pass@host:5432/tripflow
CORS_ORIGINS=https://admin.tenmien.vn
SEED_DEMO=0
BOOTSTRAP_ADMIN_EMAIL=admin@tenmien.vn
BOOTSTRAP_ADMIN_PASSWORD=<mật khẩu mạnh >=12 ký tự>
SMS_PROVIDER=esms
ESMS_API_KEY=... ; ESMS_SECRET_KEY=... ; ESMS_BRANDNAME=...
GOONG_API_KEY=... ; GOONG_MAPTILES_KEY=...
CLOUDINARY_CLOUD_NAME=... ; CLOUDINARY_API_KEY=... ; CLOUDINARY_API_SECRET=...
GEMINI_API_KEY=...
```

### 7.2. Trình tự

1. Tạo `.env` từ `.env.deploy.example`; **không commit**.
2. `docker compose up -d db` → chờ healthy.
3. `docker compose build backend admin-web` → `up -d`.
4. Kiểm tra `GET /health/ready` = 200; đăng nhập admin bằng tài khoản bootstrap.
5. Đổi mật khẩu bootstrap ngay; tạo tài khoản nhân sự theo vai trò.
6. Cấu hình tên miền + TLS (Caddy/Nginx/Cloudflare) cho API và admin.
7. Test OTP thật với 1 số điện thoại; test tạo trip, đăng lịch trình.
8. Bật backup Postgres + giám sát uptime.
9. Build app mobile: `flutter build appbundle --dart-define=API_BASE_URL=https://api.tenmien.vn/api/v1`
   (Android cần `INTERNET`, HTTPS, signing key; iOS cần ATS exception nếu dùng HTTP nội bộ).
10. Kiểm thử smoke trên thiết bị thật (Android/iOS), sau đó phát hành.

### 7.3. Điều kiện "Definition of Done" cho business

- [ ] Không còn màn hình nào sinh mã đặt chỗ giả (hoặc đã thay bằng API thật).
- [ ] Đơn hàng/thanh toán/hoàn tiền có thể tra cứu trong admin.
- [ ] OTP/booking gửi được SMS/email thật.
- [ ] Postgres + migration + backup + restore đã diễn tập.
- [ ] Không còn secret mặc định, không còn tài khoản demo.
- [ ] Có điều khoản, chính sách riêng tư, hotline thật.
- [ ] Load test 200 req/s catalog & 20 booking/phút không lỗi.
- [ ] Có dashboard lỗi/uptime và người trực.

---

## 8. Rủi ro pháp lý & dữ liệu (đặc biệt lưu ý)

1. **Crawler Google Maps** (`backend/app/services/crawler/google_maps.py`) — vi phạm Điều khoản dịch vụ Google.
   Chỉ nên dùng cho nghiên cứu nội bộ; **đã chặn tự động ở production** trừ khi đặt `ENABLE_GOOGLE_CRAWLER=1`
   sau khi có thoả thuận dữ liệu.
2. **Ảnh hotlink** từ Wikimedia/Unsplash: cần kiểm tra giấy phép từng ảnh, hoặc tải lên Cloudinary có ghi nguồn.
3. **Rating/review mẫu** đang gắn nhãn "Google Maps" nhưng là dữ liệu seed — gây hiểu nhầm và có thể vi phạm.
4. **Dữ liệu cá nhân**: số điện thoại, lịch trình, vị trí. Cần chính sách riêng tư, cơ chế xoá tài khoản/dữ liệu.
5. **Hotline 1900 6868** là số minh hoạ — không được hiển thị cho khách thật nếu chưa đăng ký.
6. **Đặt dịch vụ khi chưa có đối tác**: nếu phát hành, khách có thể hiểu là đã đặt thật → rủi ro kiện/tranh chấp.

---

## 9. Lộ trình đề xuất để đạt mức "deploy business"

| Giai đoạn | Thời lượng | Mục tiêu |
|---|---|---|
| **G0 — Ổn định hạ tầng** | 3–5 ngày | Postgres + migration, eSMS, secrets, backup, monitoring, CI, đóng các mục P0 còn lại |
| **G1 — Ra mắt bản "Trip Planner"** | 2 tuần | Bỏ/ẩn booking demo; tập trung khám phá + lập lộ trình + tìm quán dọc đường; mời 100–300 user thử |
| **G2 — Booking thật (1 loại dịch vụ)** | 4–6 tuần | Chọn 1 dọc: khách sạn **hoặc** tour; đơn hàng + thanh toán + xác nhận + huỷ |
| **G3 — Mở rộng** | 6–8 tuần | Thêm vé xe/tàu, đối tác, đối soát, đánh giá có xác thực, push notification |
| **G4 — Mở rộng địa lý** | liên tục | 63 tỉnh, nội dung hợp pháp, đa ngôn ngữ |

> Khuyến nghị thẳng: **đừng gọi là "super app đặt dịch vụ" ở bản phát hành đầu** khi chưa có booking thật.
> Định vị "TripFlow — Lập lộ trình & tìm quán ăn dọc đường" sẽ trung thực và bán được hơn.

---

## 10. Phụ lục — file đã thay đổi trong phiên này

**Backend**
- `app/models/{models,trip,place,review,crawl_job}.py`
- `app/core/{config,time}.py`
- `app/main.py`
- `app/api/v1/endpoints/{auth,itineraries,trips,admin,admin_crawler}.py`
- `app/services/{sms_service,itinerary_service,trip_service,expense_service,maps_service,places_service,ingestion_service}.py`
- `app/services/ai/plan_service.py`
- `app/services/crawler/normalizer.py`
- `app/db/seed_db.py`
- `tests/test_api.py`, `tests/test_modules.py` (mới)
- `requirements.txt`, `Dockerfile`, `.dockerignore`, `.env.example`

**Flutter**
- `lib/main.dart`
- `lib/core/config/app_config.dart`
- `lib/core/storage/offline_cache_service.dart` (guest token)
- `lib/core/network/{dio_client,auth_interceptor}.dart` (auth_interceptor mới)
- `lib/core/utils/app_state.dart`
- `lib/data/{trips_api,places_api,assistant_api}.dart`
- `lib/features/auth/{login_screen,register_screen,otp_verification_screen}.dart`
- `lib/features/home/widgets/brand_identity_header.dart`
- `test/widget_test.dart`

**Admin**
- `src/services/api/client.js`
- `src/hooks/useAuth.jsx`
- `src/app/App.jsx`
- `src/pages/auth/LoginPage.jsx`
- `Dockerfile`, `nginx.conf`, `.dockerignore`, `.env.example` (mới)

**Hạ tầng & tài liệu**
- `docker-compose.yml`, `.env.deploy.example` (mới)
- `README.md` (đính chính trạng thái)
- `docs/09-KIEM-TOAN-TRIEN-KHAI.md` (tài liệu này)
- `docs/10-CATALOG-DU-LIEU-THAT.md` (catalog 10 tỉnh)

---

## 11. Cập nhật đợt 2 — Trip Planner + catalog thật (06/11/2026)

Sau khi chốt hướng "làm app lập lộ trình – tìm quán ăn – điểm nghỉ chân", đã bổ sung:

- **Catalog thật 10 tỉnh**: 220 bản ghi nghiên cứu,
  **164 ảnh Wikimedia có giấy phép**, seed thành **168 địa điểm + 77 quán ăn/cà phê + 50 điểm nghỉ chân**.
- **Điểm nghỉ chân**: chip "Nghỉ chân" trả quán cà phê + công viên/điểm ngắm cảnh;
  đã thêm bảng `rest_stops` sẵn sàng cho cây xăng/sạc EV khi có dữ liệu OSM ổn định.
- Pipeline tự động: OpenStreetMap Nominatim (toạ độ) → Wikipedia (mô tả) → Wikimedia Commons (ảnh),
  có kiểm tra bbox thành phố, chống trùng 100 m, lọc ảnh sai chủ đề.
- Ảnh được ghi công tác giả + giấy phép ở màn chi tiết; không dùng ảnh giả khi thiếu nguồn.
- Nearby lấy tâm theo tỉnh đang chọn (trước đây cố định TP.HCM); tự tải đủ địa điểm (sửa lỗi phân trang 20).
- Bản đồ nền tự chuyển sang OpenStreetMap khi chưa có Goong key (trước đây tile demo 403).
- Ẩn hotline giả `1900 6868`; chỉ hiện khi cấu hình `SUPPORT_HOTLINE`.
- **Tìm kiếm hợp nhất** địa điểm + quán ăn + đặc sản (màn Tìm kiếm mới từ ô search trang chủ).
- **Booking demo tự ẩn ở bản release** (`AppConfig.showDemoBooking = !kReleaseMode`), chỉ bật ở dev/demo.
- **Điểm nghỉ chân dọc tuyến**: API `/places/along-route` + mục gợi ý trong màn Bản đồ lộ trình.
- **CI GitHub Actions** (backend/Flutter/admin) + **runbook production** tại
  [11-RUNBOOK-TRIEN-KHAI.md](11-RUNBOOK-TRIEN-KHAI.md).
- Chi tiết kỹ thuật & quy trình thêm dữ liệu: [10-CATALOG-DU-LIEU-THAT.md](10-CATALOG-DU-LIEU-THAT.md).
