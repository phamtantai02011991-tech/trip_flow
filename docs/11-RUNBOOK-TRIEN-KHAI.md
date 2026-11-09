# 11 — Runbook triển khai production (Trip Planner)

Cập nhật: 07/11/2026
Phạm vi: backend FastAPI + PostgreSQL, admin web React, app Flutter (web/Android/iOS).

> Mục tiêu: đưa bản **Trip Planner** (lập lộ trình – tìm quán ăn – điểm nghỉ chân) lên môi trường thật
> mà không phát hành booking giả.

---

## 1. Điều kiện bắt buộc trước khi deploy

| # | Hạng mục | Trạng thái / ghi chú |
|---|---|---|
| 1 | PostgreSQL 15+ | Bắt buộc; SQLite chỉ dùng dev. Đã test 35/35 trên PostgreSQL 16.2 |
| 2 | `SECRET_KEY` ngẫu nhiên ≥ 48 ký tự | Backend từ chối chạy production nếu dùng key mặc định |
| 3 | `SEED_DEMO=0` | Không tạo tài khoản demo `Admin@123` |
| 4 | `BOOTSTRAP_ADMIN_EMAIL/PASSWORD` | Tạo admin đầu tiên, mật khẩu ≥ 12 ký tự |
| 5 | eSMS hoặc SMS gateway | OTP đăng nhập không hoạt động nếu chưa cấu hình |
| 6 | Domain + TLS | API và Admin phải chạy HTTPS |
| 7 | `CORS_ORIGINS` | Chỉ domain thật, không dùng `*` |
| 8 | Backup Postgres | `pg_dump` hằng ngày, lưu ngoài máy chủ |
| 9 | Giám sát uptime | `/health` + `/health/ready` |
| 10 | Pháp lý | Điều khoản, chính sách riêng tư, hotline thật, giấy phép ảnh |

**Bảo mật token:** JWT được lưu trong Keychain/Keystore qua `flutter_secure_storage`
(Android minSdk 23). Token cũ trong Hive tự động được migrate và xoá khỏi plaintext khi mở app.

**Chống brute-force:** sai mật khẩu 5 lần → tài khoản bị khoá 15 phút (HTTP 423).

**2FA admin (TOTP):** đăng nhập admin → banner vàng “Thiết lập 2FA” → quét khoá thủ công
trong Google Authenticator/Authy → nhập mã 6 số để bật. API tương ứng:
`POST /auth/2fa/setup`, `POST /auth/2fa/enable`.

**Bắt buộc 2FA:** sau khi toàn bộ admin đã setup, đặt `REQUIRE_ADMIN_2FA=1`.
Mọi API `/api/v1/admin/*` sẽ trả 403 `2FA_SETUP_REQUIRED` nếu tài khoản chưa bật 2FA.

**Booking demo:** bản release tự ẩn 3 dịch vụ đặt phòng/vé/tour (`AppConfig.showDemoBooking = !kReleaseMode`).
Muốn bật lại cho demo: build với `--dart-define=SHOW_DEMO_BOOKING=true`.

---

## 2. Biến môi trường production

Tạo `.env` từ [`.env.deploy.example`](../.env.deploy.example):

```env
ENVIRONMENT=production
SECRET_KEY=<chuỗi ngẫu nhiên 48+ ký tự>
POSTGRES_PASSWORD=<mật khẩu mạnh>
DATABASE_URL=postgresql+psycopg2://postgres:<password>@db:5432/tripflow
CORS_ORIGINS=https://admin.tripflow.vn

SEED_DEMO=0
BOOTSTRAP_ADMIN_EMAIL=admin@tripflow.vn
BOOTSTRAP_ADMIN_PASSWORD=<mật khẩu mạnh >=12 ký tự>

SMS_PROVIDER=esms
ESMS_API_KEY=...
ESMS_SECRET_KEY=...
ESMS_BRANDNAME=TripFlow

GOONG_API_KEY=...
GOONG_MAPTILES_KEY=...
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
GEMINI_API_KEY=...
```

Sinh `SECRET_KEY`:

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

---

## 3. Deploy bằng Docker Compose

```bash
cp .env.deploy.example .env
# sửa .env
docker compose --env-file .env build
docker compose --env-file .env up -d
docker compose ps
```

Kiểm tra:

```bash
curl -fsS https://api.tripflow.vn/health
curl -fsS https://api.tripflow.vn/health/ready
```

- Admin: `https://admin.tripflow.vn`
- API docs (nếu muốn mở): `https://api.tripflow.vn/docs` — nên chặn ở production.

### Lần đầu khởi động

Backend tự chạy `alembic upgrade head` khi container khởi động, sau đó seed catalog mở
(idempotent) và tạo admin từ `BOOTSTRAP_ADMIN_*`. DB cũ do `create_all` tạo sẽ được
`stamp` baseline tự động (xem `app/db/migrate.py`).
Đăng nhập admin ngay, **đổi mật khẩu bootstrap**, tạo tài khoản nhân sự theo vai trò.

> Ghi chú kỹ thuật: migration nằm ở `backend/alembic/versions/`; entrypoint tự chạy
> `upgrade head`. Khi sửa model, tạo migration mới bằng
> `alembic revision --autogenerate -m "..."` trước khi deploy.

---

## 4. Build & phát hành app

### Web

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.tripflow.vn/api/v1 \
  --dart-define=GOONG_MAP_TILES_KEY=<key> \
  --dart-define=SUPPORT_HOTLINE=<hotline>
```

### Android

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.tripflow.vn/api/v1 \
  --dart-define=GOONG_MAP_TILES_KEY=<key>
```

- Cần keystore riêng, bật `INTERNET`, HTTPS.
- Kiểm tra `android/app/build.gradle` ký release trước khi upload Play Console.

### iOS

```bash
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.tripflow.vn/api/v1
```

- Cần Apple Developer, provisioning profile, ATS (chỉ HTTPS).

---

## 5. Smoke test sau deploy (bắt buộc)

Chạy tự động:

```bash
python tools/smoke_test.py --base-url https://api.tripflow.vn
```

Kỳ vọng: **7/7 PASS** (health, ready, destinations, restaurants, gas, along-route, suggest).

| # | Kiểm tra | Kỳ vọng |
|---|---|---|
| 1 | `GET /health` | `status=healthy` |
| 2 | `GET /health/ready` | `database=ok` |
| 3 | Đăng nhập admin bootstrap | 200, role `super_admin` |
| 4 | `GET /api/v1/destinations?page_size=100` | ≥ 100 địa điểm |
| 5 | `GET /api/v1/restaurants` | ≥ 70 quán |
| 6 | `GET /api/v1/places/nearby?lat=21.0288&lng=105.8525&kinds=gas` | có cây xăng |
| 7 | `POST /api/v1/places/along-route` | có điểm nghỉ dọc tuyến |
| 8 | Gửi OTP thật | nhận SMS, xác thực thành công |
| 9 | App: tìm “bun cha” | ra kết quả quán |
| 10 | App: mở Bản đồ lộ trình | thấy quán + điểm nghỉ |
| 11 | Admin: sửa 1 địa điểm | app cập nhật sau khi refresh |
| 12 | Booking demo trên bản release | **không hiển thị** |

---

## 6. Backup & khôi phục

```bash
# Cách 1: script có sẵn (giữ 7 bản, kiểm tra file rỗng)
BACKUP_DIR=/backup tools/backup_postgres.sh

# Cách 2: thủ công
docker exec tripflow_postgres_db pg_dump -U postgres tripflow \
  | gzip > /backup/tripflow-$(date +%F).sql.gz

# Restore
gunzip -c /backup/tripflow-2026-11-07.sql.gz \
  | docker exec -i tripflow_postgres_db psql -U postgres -d tripflow
```

Giữ tối thiểu 7 bản gần nhất; kiểm tra restore định kỳ mỗi tháng.

---

## 7. Rollback

```bash
# Quay lại image trước
docker compose down
docker compose --env-file .env up -d --build
```

Nếu lỗi do dữ liệu: restore bản backup gần nhất rồi mới khởi động lại backend.
Luôn giữ tag image của bản đang chạy để rollback nhanh.

---

## 8. Giám sát & log

- Uptime: ping `/health/ready` mỗi 60 giây.
- Log backend: `docker logs -f tripflow_backend_api`.
- Log admin/nginx: `docker logs -f tripflow_admin_web`.
- Cảnh báo khi: 5xx > 1%, OTP fail > 10%, DB connections > 80%.
- Sentry/telemetry: chưa tích hợp — nên thêm trước khi tăng người dùng.

---

## 9. Những gì CHƯA có (không được hứa với khách)

- Thanh toán, đơn hàng, hoàn huỷ, e-voucher thật.
- Push notification/email giao dịch.
- Đặt phòng/vé/tour thật (release đã ẩn).
- Chấm điểm/đánh giá có xác thực giao dịch.
- CDN ảnh thật (đang dùng Wikimedia 1280px).
- Đa ngôn ngữ, dark mode, accessibility đầy đủ.

---

## 10. Checklist trước khi bấm deploy

- [ ] `.env` production đã điền, không commit.
- [ ] `SEED_DEMO=0`, admin bootstrap đã đổi mật khẩu.
- [ ] `SECRET_KEY` ngẫu nhiên.
- [ ] OTP gửi/nhận thật thành công.
- [ ] `CORS_ORIGINS` đúng domain.
- [ ] Backup + giám sát đã bật.
- [ ] App release build ẩn booking demo.
- [ ] Đã chạy smoke test 12 mục.
- [ ] Có người trực và kênh hỗ trợ khách.
