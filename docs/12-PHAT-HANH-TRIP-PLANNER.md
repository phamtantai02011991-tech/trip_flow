# 12 — Xác nhận phát hành Trip Planner

Ngày: 07/11/2026
Phạm vi: bản **Trip Planner** — lập lộ trình, tìm quán ăn, điểm nghỉ chân dọc đường.

---

## 1. Đã hoàn thành

| Hạng mục | Bằng chứng |
|---|---|
| Lập lộ trình | Planner + bản đồ corridor; API `/restaurants/corridor-search` |
| Tìm quán ăn | 77 quán/cà phê, lọc theo tỉnh/đánh giá/đặc trưng |
| Điểm nghỉ chân | 50 cây xăng/sạc EV + chip Nghỉ chân; API `/places/along-route` |
| 10 tỉnh | 168 địa điểm, phủ Hà Nội → Phú Quốc |
| Ảnh thật | **164/220 bản ghi** có ảnh Wikimedia + giấy phép; 144/156 địa điểm |
| Tìm kiếm | Tìm hợp nhất địa điểm/quán ăn/đặc sản, hỗ trợ không dấu |
| Booking demo | **Tự ẩn ở bản release** (`showDemoBooking = !kReleaseMode`) |
| Pháp lý | Điều khoản, Chính sách riêng tư, Giấy phép ảnh trong app |
| Bảo mật | JWT Keychain/Keystore, lockout 5 lần, 2FA TOTP admin |
| Migration | Alembic baseline + 2FA; tự chạy khi container start |
| Quyền riêng tư | Xuất dữ liệu + xoá tài khoản |

## 2. Kiểm chứng phát hành

| Kiểm tra | Kết quả |
|---|---|
| Backend pytest (SQLite) | **40/40 pass** |
| Backend pytest (PostgreSQL 16.2) | **36/36 pass** |
| Flutter test | **14/14 pass** |
| `dart analyze` | **0 error, 0 warning** (91 info) |
| Flutter web release | **Build thành công** |
| Admin web build | **Thành công** (1545 modules) |
| Docker Compose | **Postgres 15 + backend + admin chạy thật**, backend/admin healthy |
| Smoke test trên Docker | **7/7 PASS** (`http://127.0.0.1:8000`) |
| App boot release | **0 console error** |

Smoke test cuối:

```text
[PASS] health, ready
[PASS] destinations = 168
[PASS] restaurants = 77
[PASS] nearby gas = 6
[PASS] along-route = 4
[PASS] suggest "hoi an" = 8
```

## 3. Hạn chế đã biết (không chặn phát hành planner)

- **OTP SMS thật** cần cấu hình `ESMS_API_KEY`/`ESMS_SECRET_KEY`; code/payload đã test mock.
- **56/220 bản ghi** chưa có ảnh đúng (chủ yếu quán ăn nhỏ).
- **Booking thật** (phòng/vé/tour, thanh toán, e-voucher) chưa có — đã ẩn khỏi release.
- **IP/VPN allowlist** cho admin chưa có.
- **Backup/giám sát tự động** có script/quy trình nhưng chưa bật hạ tầng thật.
- **ĐKKD, hoá đơn, hotline thật** cần bổ sung trước khi chạy quảng cáo/thu tiền.

## 4. Điều kiện go-live tối thiểu

- [ ] `.env` production: `SECRET_KEY`, PostgreSQL, `SEED_DEMO=0`, admin bootstrap.
- [ ] Cấu hình eSMS thật và test OTP.
- [ ] `REQUIRE_ADMIN_2FA=1` sau khi toàn bộ admin đã bật TOTP.
- [ ] Backup `pg_dump` hằng ngày + giám sát `/health/ready`.
- [ ] Điền ĐKKD/hotline/email hỗ trợ vào trang pháp lý.
- [ ] Chạy `tools/smoke_test.py` trên domain thật.

## 5. Kết luận

Bản **Trip Planner** đã đạt mục tiêu: lập lộ trình, tìm quán ăn và điểm nghỉ chân
dọc đường cho 10 tỉnh, dữ liệu thật có giấy phép, tìm kiếm/lọc hoàn chỉnh,
booking demo đã ẩn, kiểm thử và build thành công.

Các hạng mục còn lại thuộc vận hành thương mại (SMS key, backup, pháp lý doanh nghiệp,
thanh toán) — không nằm trong phạm vi bản Trip Planner này.
