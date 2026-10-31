# 07 — Nhật ký quá trình code (phiên 01/11/2026)

> Mục đích: ghi lại **đã làm gì, đo được gì, chạy được gì, còn gì** để người tiếp theo (hoặc bạn ở phiên sau) đọc là hiểu ngay.

---

## 1. Việc đã hoàn thành trong phiên

| # | Việc | Kết quả |
|---|---|---|
| 1 | Dọn dẹp dự án | 428,53 MB → 4,18 MB (xem `06-DON-DEP.md`) |
| 2 | Kiểm kê toàn bộ mã nguồn | 36 file Flutter (~17.500 dòng), 51 file backend, 58 endpoint cũ |
| 3 | Lập bộ kế hoạch 7 phase | `docs/00` → `docs/06` |
| 4 | Xác minh API bằng số liệu thật | `docs/04a` |
| 5 | **Cấu hình Gemini key thật** | `backend/.env` (gitignored), test 60 model, đo độ trễ |
| 6 | **Code Module 1/2/6 (backend)** | 5 file mới: model, schema, service, AI service, endpoint |
| 7 | **Design token + theme mới** | `lib/ui/tokens/app_tokens.dart`, `lib/core/theme/app_theme.dart` |
| 8 | **Bản đồ thật** | `lib/features/map/trip_flow_map.dart` (flutter_map + tile Goong) |
| 9 | Kiểm tra biên dịch | Backend: 9/9 file parse OK · Flutter: `dart analyze` **0 error** |

---

## 2. Kết quả đo Gemini bằng key của bạn (quan trọng)

- Key hợp lệ: `GET /v1beta/models` → **HTTP 200**, **60 model**.
- Model text khả dụng: `gemini-2.5-flash`, `gemini-3.5-flash`, `gemini-3.6-flash`, `gemini-3.7-flash`, `gemini-3.8-flash`, `gemini-3.1-flash-lite`, `gemini-3.1-pro-preview`, `gemini-4-argon`…
- **Đo độ trễ thật** (cùng prompt, `maxOutputTokens=1024`, tắt suy luận):

| Model | Thời gian | Ghi chú |
|---|---|---|
| `gemini-3.8-flash` + thinkingBudget=0 | **140 giây** | Không dùng được cho UI |
| `gemini-3.8-flash` + thinkingLevel=low | 80 giây | Vẫn quá chậm |
| `gemini-3.5-flash` + thinkingBudget=0 | **7,1 giây** | ✅ chọn cho tạo lộ trình |
| `gemini-3.1-flash-lite` + thinkingBudget=0 | **2,8 giây** | ✅ chọn cho chat |

→ Kết luận: **không dùng model "mới nhất"**; `thinkingBudget: 0` là bắt buộc. Code đã set sẵn trong `gemini_client.generate_json`.

---

## 3. File đã tạo/sửa

### Backend (mới)

| File | Nội dung |
|---|---|
| `app/models/trip.py` | 4 bảng: `trips`, `trip_days`, `trip_stops`, `expenses` + 5 enum |
| `app/schemas/trip.py` | `TripCreate/Update/Out`, `TripStopIn/Out`, `TripDayOut`, `TripTotals`, `GenerateRequest` |
| `app/services/trip_service.py` | CRUD, nhân bản, chia sẻ, thêm/xoá/đổi thứ tự điểm dừng, tính tổng km/phút/chi phí |
| `app/services/ai/gemini_client.py` | Gọi Gemini HTTP thuần, tự chọn model, `thinkingBudget=0`, xử lý SAFETY/MAX_TOKENS/429/timeout |
| `app/services/ai/plan_service.py` | **Grounded AI**: gom ứng viên → prompt → validate `place_id` → tự tính km/giờ/tiền |
| `app/api/v1/endpoints/trips.py` | 11 endpoint (CRUD + stops + reorder + share + generate + ai-status) |
| `app/services/ai/__init__.py` | Package marker |

### Backend (sửa)

| File | Thay đổi |
|---|---|
| `app/core/config.py` | Thêm loader `.env` (trước đây **`.env` bị bỏ qua hoàn toàn**), thêm 8 biến Gemini/cache |
| `app/api/v1/router.py` | Đăng ký `/trips` |

### Flutter (mới)

| File | Nội dung |
|---|---|
| `lib/ui/tokens/app_tokens.dart` | `AppColors`, `AppSpace`, `AppRadii`, `AppShadow`, `AppText` — nguồn duy nhất |
| `lib/features/map/trip_flow_map.dart` | `FlutterMap` thật: tile Goong, marker ảnh tròn + đuôi nhọn, polyline 2 lớp (trắng + san hô), chế độ tối |

### Flutter (sửa)

| File | Thay đổi |
|---|---|
| `lib/core/theme/app_theme.dart` | Dựng lại từ token: nền kem, CTA san hô, card bo 24, sheet bo 32. Giữ hằng số `primaryTeal`… để không phá 12 file cũ |

---

## 4. API mới (đã đăng ký)

| Method | Path | Chức năng |
|---|---|---|
| GET | `/api/v1/trips` | Danh sách chuyến (của tôi; khách chỉ thấy chuyến đã chia sẻ) |
| POST | `/api/v1/trips` | Tạo chuyến + sinh sẵn các ngày rỗng |
| GET/PUT/DELETE | `/api/v1/trips/{id}` | Chi tiết / sửa / xoá (kiểm tra chủ sở hữu, trả 404) |
| POST | `/api/v1/trips/{id}/duplicate` · `/share` | Nhân bản · tạo link chia sẻ |
| POST | `/api/v1/trips/{id}/days/{n}/stops` | Thêm điểm dừng |
| DELETE | `/api/v1/trips/{id}/stops/{sid}` | Xoá điểm dừng (tự đánh lại thứ tự) |
| PUT | `/api/v1/trips/{id}/days/{n}/reorder` | Kéo-thả sắp xếp |
| **POST** | **`/api/v1/trips/{id}/generate`** | **AI tạo lộ trình (grounded)** |
| GET | `/api/v1/trips/{id}/ai-status` | Model/token/chi phí của lần tạo |

---

## 5. Cách chạy (máy bạn)

```powershell
# 1) Backend
cd D:\trip_flow\backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt          # cần mạng
uvicorn app.main:app --reload --port 8000
# Mở http://localhost:8000/docs

# 2) Thử tạo lộ trình AI
# POST /api/v1/trips
# { "title":"Đà Lạt 3 ngày", "origin_name":"TP.HCM", "origin_lat":10.7769, "origin_lng":106.7009,
#   "destination_name":"Đà Lạt", "destination_lat":11.9404, "destination_lng":108.4583,
#   "province_id":8, "total_days":3, "party_size":2, "vehicle":"motorbike",
#   "budget_level":"balanced", "preferences":["nature","food"] }
# Rồi POST /api/v1/trips/{id}/generate  (cần đăng nhập: /auth/login → Bearer token)

# 3) Flutter
cd D:\trip_flow
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

---

## 6. Kiểm chứng đã chạy được / chưa chạy được

| Kiểm chứng | Kết quả |
|---|---|
| `GET /v1beta/models` với key thật | ✅ 200, 60 model |
| `:generateContent` + `responseSchema` | ✅ 200, JSON đúng schema |
| Đo độ trễ 4 cấu hình model | ✅ có số thật (bảng §2) |
| Parse cú pháp 9 file backend | ✅ OK |
| `dart analyze lib` | ✅ **0 error** (58 info: deprecated/unused) |
| `pytest` | ❌ **chưa chạy được** — máy thiếu `sqlmodel`, `pip install` bị treo do mạng sandbox |
| `flutter run` | ❌ chưa chạy — `flutter` treo trong sandbox (cần bạn chạy ở terminal thật) |

> Vì `pytest` chưa chạy, code backend **mới chỉ được kiểm tra cú pháp**, chưa chứng minh chạy đúng. Việc đầu tiên khi bạn mở máy: `pip install -r requirements.txt` rồi `pytest -q`.

---

## 7. Việc tiếp theo (ưu tiên giảm dần)

| # | Việc | File chính | Ước lượng |
|---|---|---|---|
| 1 | Chạy `pytest` + sửa lỗi thật của module trips/AI | `backend/tests/test_trips.py` (chưa viết) | 0,5 ngày |
| 2 | Màn Flutter: danh sách chuyến + tổng quan lộ trình (dùng `TripFlowMap`) | `features/trip/*` | 2 ngày |
| 3 | Wizard 3 bước + màn "AI đang tạo" | `features/planner/*` | 2 ngày |
| 4 | API + màn chi phí (Module 7) | `services/expense_service.py`, `features/expenses/*` | 2 ngày |
| 5 | Trợ lý chat SSE + tool-calling (Module 4) | `services/ai/assistant_service.py` | 3 ngày |
| 6 | Nearby + lịch sử tìm kiếm (Module 5) | `services/places_service.py` | 2 ngày |
| 7 | Sửa 8 lỗi bảo mật + xoá dữ liệu giả | xem `01-KIEN-TRUC.md §7` | 2 ngày |
| 8 | Áp design system cho 9 màn còn lại | `features/*` | 4 ngày |

Chi tiết từng bước (kèm code mẫu): `docs/05-LO-TRINH-CODE.md`.

---

## 7b. Phiên 2 — UI Module 1/2/3/6 (cùng ngày)

### Quyết định kỹ thuật quan trọng

| Vấn đề | Quyết định | Lý do |
|---|---|---|
| `go_router`, `geolocator` | **Không dùng** | Không có trong pub cache offline; thêm vào sẽ khiến `pub get` treo. Dùng `Navigator` + chọn thành phố có toạ độ thật thay cho GPS |
| GPS | Hoãn | Cần plugin + quyền nền tảng; hiện dùng 12 thành phố phổ biến với toạ độ thật, nhập tay vẫn dùng được |
| Điều hướng chi phí | Bottom sheet tính từ `est_cost` thật | Tránh route `/expenses` chưa tồn tại |

### File mới

| File | Nội dung |
|---|---|
| `lib/core/models/trip.dart` | `Trip`, `TripDay`, `TripStop`, `TripTotals` + `fromJson` an toàn kiểu |
| `lib/data/trips_api.dart` | 9 method gọi `/trips`; timeout 120s cho endpoint AI; dịch lỗi sang tiếng Việt |
| `lib/state/trips_provider.dart` | `tripsProvider` (danh sách) + `tripDetailProvider` (family theo id) |
| `lib/features/trip/trip_list_screen.dart` | Danh sách chuyến, lọc theo trạng thái, skeleton/empty/error, FAB tạo chuyến |
| `lib/features/trip/trip_overview_screen.dart` | Bản đồ thật 55% + sheet kéo được + pill theo ngày + card điểm dừng + tổng km/giờ/tiền + chia sẻ + tạo lại AI + sheet chi phí |
| `lib/features/planner/planner_wizard_screen.dart` | Wizard 3 bước + màn tiến trình AI (3 bước thật) + xử lý lỗi |

### Sửa

| File | Thay đổi |
|---|---|
| `lib/main.dart` | Tab 3 đổi từ `ItineraryScreen` sang `TripListScreen`, thêm import |
| `backend/app/services/trip_service.py` | Khách chưa đăng nhập thấy chuyến `user_id IS NULL` (phục vụ demo, có ghi chú) |

### Kiểm chứng

- `dart analyze lib` → **0 error** (70 info, phần lớn là deprecated API ở file cũ).
- Backend: parse cú pháp OK.

### Còn lại

1. Màn **Nearby** (Module 5) — dùng `GET /places/nearby` + `TripFlowMap(dark: true)`.
2. Màn **Assistant** (Module 4) — chat + hiển thị `actions_applied`.
3. Màn **Chi phí** (Module 7) — CRUD chi phí thực tế + biểu đồ.
4. UI kéo-thả/xoá điểm dừng (Module 6) — API đã có `reorder`, `deleteStop`.
5. `/maps/directions` để thay khoảng cách chim bay bằng tuyến đường thật.

---

## 8. Cảnh báo bảo mật
- Key Gemini đã xuất hiện trong chat → **coi như đã lộ**. Sau khi test xong, vào AI Studio **xoá key này và tạo key mới**, chỉ dán vào `backend/.env` (file đã gitignore).
- `backend/.env` chứa `SECRET_KEY` và `GEMINI_API_KEY`: **không** commit, **không** gửi qua chat/nhóm.
- Nếu push repo lên GitHub: kiểm tra `git status` không có `.env`, `.research/` (đã ignore).
