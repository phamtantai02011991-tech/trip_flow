# TripFlow — Kế hoạch tổng thể (Master Plan)

> **Mục tiêu:** biến TripFlow thành ứng dụng "lập kế hoạch du lịch + tìm địa điểm quanh đây + trợ lý AI" đúng 7 module người dùng yêu cầu, giao diện đạt chuẩn 8 ảnh tham chiếu, **không còn dữ liệu bịa**, và dự án nhẹ — dễ build lại.
>
> **Trạng thái:** kế hoạch đã duyệt nội bộ · **Ngày lập:** 31/10/2026 · **Phiên bản:** 1.0

---

## 1. Hiện trạng sau khi kiểm kê

### 1.1 Con số thật (đo được, không phỏng đoán)

| Hạng mục | Số liệu | Nguồn |
|---|---|---|
| Tổng dung lượng trước dọn | 428,53 MB / 7.673 file | đo bằng PowerShell |
| Sau dọn | **4,18 MB** / ~1.500 file | `docs/06-DON-DEP.md` |
| Mã Flutter | 36 file / **~17.500 dòng** | kiểm kê `lib/` |
| Backend | 51 file / **59 endpoint** nghiệp vụ | kiểm kê `backend/` |
| Admin-web | 20 file React + 99 KB mock | `admin-web/src` |
| Bảng DB | 18 bảng (`models/models.py`) | kiểm kê backend |
| Test backend | 17 hàm test (TC-01→TC-23, thiếu TC-08, TC-17) | `backend/tests/test_api.py` |
| Bản ghi seed | 10 tỉnh · 28 destination · 26 restaurant · 24 local food · 11 lịch trình mẫu | `seed_db.py` |

### 1.2 Ba khoản nợ lớn nhất

**A. Bản đồ là giả.** `flutter_map` + `latlong2` có trong `pubspec.yaml` nhưng **0 import**. Toàn bộ bản đồ trong `map_corridor_screen.dart` và `smart_itinerary_result_screen.dart` là `CustomPainter` vẽ tay (`L346/L627`, `L423/L560/L600/L640`). Không có GPS thật, không có tile, không có marker chạm được → Module 3 hiện không tồn tại về mặt kỹ thuật.

**B. Dữ liệu bịa nằm rải rác, không phân biệt được với dữ liệu thật:**

| Vị trí | Dữ liệu bịa |
|---|---|
| `hero_trip_carousel.dart` L56–105 | 4 chuyến đi const, giá 350.000–520.000đ |
| `smart_itinerary_engine.dart` L644/677/682 | Chi phí cứng (ăn trưa 85k, nghỉ 35k, ăn tối 120k, `km*12000`), thời tiết hardcode |
| `dio_client.dart` L335/343/383 | OTP chấp nhận `888999` **hoặc bất kỳ mã 6 số nào** khi offline |
| `goong_client.py` | Không có key → sinh polyline giả nhưng gắn nhãn `"goong_maps"` |
| `maps_client.py` | `_daily_calls=18`, `_cache_hits=42` là số bịa hiển thị lên dashboard |
| `crawler/google_maps.py` | < 15 kết quả → sinh địa điểm giả `_build_realistic_local_places` |
| `cloudinary_service.py` | Thiếu key → trả URL `demo` nhưng báo `provider:"cloudinary"` |
| `trip_planner_wizard_screen.dart` L27–33 | Tick sẵn 5 sở thích, không kiểm tra origin ≠ destination |

**C. Thiếu 5/7 module ở backend.** Không có khái niệm "chuyến đi" (ngày đi/về, số người, ngân sách, phương tiện), **không có một dòng LLM nào**, không có trợ lý chat, không có lịch sử tìm kiếm, không có module chi phí. Ngoài ra có lỗi bảo mật nghiêm trọng: `GET/PUT/DELETE /itineraries/{id}` **không kiểm tra chủ sở hữu**, `DELETE` thậm chí không cần token.

### 1.3 Điểm mạnh cần giữ

- `geo_service.py`: haversine + bbox SQL + Shapely + **SFCS 105 điểm** (40 cự ly + 35 sao + 25 log10 reviews + 5 bonus) — công thức tốt, giữ nguyên.
- `normalizer.py`: chuẩn hoá text, validate toạ độ Việt Nam (8.18–23.39 / 102.14–109.46), parse "1,5k reviews".
- RBAC 3 bảng (`Role` ↔ `RolePermissionLink` ↔ `Permission`) đúng chuẩn.
- Offline-first: 4 Hive box + fallback 3 lớp (API → Hive → mock).
- 17 test backend phủ khá rộng, chạy bằng `pytest`.

---

## 2. Nguyên tắc thiết kế (ràng buộc kỹ thuật, không thoả hiệp)

1. **Một nguồn sự thật.** Mọi dữ liệu địa điểm/giờ mở cửa/toạ độ/giá đến từ backend + DB + API bản đồ. Không có mock nào được lọt vào build production.
2. **LLM không được bịa.** Gemini chỉ được **chọn – sắp xếp – giải thích** trong danh sách ứng viên do backend cung cấp (kèm `place_id` và dữ kiện). Backend kiểm tra lại từng `place_id`, rồi **tự tính** khoảng cách, thời gian, chi phí. Chi tiết: `docs/04-API-TICH-HOP.md §3`.
3. **Không hardcode model/con số API.** Model ID, giá, quota nằm trong env; backend đọc `GET /v1beta/models` để chọn model khả dụng.
4. **Mỗi module là một vertical slice.** Model → API → repository → state → UI, làm xong trọn vẹn một module rồi mới sang module kế.
5. **UI theo token, không theo màu hardcode.** Xoá dần 40+ mã màu rải rác trong `lib/`, thay bằng `AppColors`.
6. **Không thêm dependency nếu chưa dùng.** Mỗi package mới phải có ít nhất 1 import thật trong cùng PR.

---

## 3. Kiến trúc đích (tóm tắt)

```
Flutter (Riverpod + go_router + flutter_map + Hive)
   │  REST/JSON + SSE
   ▼
FastAPI  ── /trips  /itinerary-ai  /assistant  /places  /maps  /search  /expenses
   │
   ├── Postgres (Alembic migration)
   ├── Goong Maps (tiles, directions, autocomplete, place detail)
   ├── Gemini API (grounded generation + chat) — key chỉ ở server
   └── Redis/in-memory cache cho Places & Directions
```

Chi tiết: `docs/01-KIEN-TRUC.md`.

---

## 4. Bản đồ 8 ảnh tham chiếu → màn hình

| Ảnh | Nội dung | Màn hình TripFlow | File đích |
|---|---|---|---|
| 1 | Home "Where to Next?", 3D card deck, Popular Destination, pill nav đỏ | `HomeScreen` | `features/home/home_screen.dart` |
| 2 | Bản đồ + marker ảnh tròn, bottom sheet Arrival/Depart, Day pills, card điểm dừng nối nét đứt | `TripOverviewScreen` | `features/trip/trip_overview_screen.dart` |
| 3 | Ảnh full-screen, "2nd Stop", 4.9 (127), card 400 m, dải thumbnail +25 | `StopDetailScreen` | `features/trip/stop_detail_screen.dart` |
| 4 | Bản đồ tối + danh sách quán, chip Restaurant/Hotel/Gas/Coffee | `NearbyScreen` (dark mode) | `features/nearby/nearby_screen.dart` |
| 5 | Wizard "Create Plan with AI": 3 bước, chip sở thích, đếm ngày, chọn ngày | `PlannerWizardScreen` | `features/planner/planner_wizard_screen.dart` |
| 6 | Danh sách waypoint + kéo thả, tab phương tiện, "Search along the route" | `RouteBuilderScreen` | `features/planner/route_builder_screen.dart` |
| 7 | Tablet + weather + turn-by-turn | `TripOverviewScreen` (tablet) + `NavigationPreview` | `features/trip/*` |
| 8 | Onboarding, "Travelling Today?", AI Picks, trợ lý giọng nói "Mira" | `OnboardingScreen` + `AssistantScreen` | `features/onboarding/*`, `features/assistant/*` |
| 9 | Bản đồ + tìm kiếm + lịch sử + card địa điểm có nút Gọi/Chỉ đường | `NearbyScreen` + `SearchScreen` | `features/search/*` |

Chi tiết token màu/chữ/bo góc: `docs/02-DESIGN-SYSTEM.md`. Đặc tả từng màn: `docs/03-MAN-HINH.md`.

---

## 5. Bản đồ 7 module → phạm vi

| # | Module | Hiện có | Phải làm | Tài liệu |
|---|---|---|---|---|
| 1 | Tạo chuyến đi | Dialog tên + số ngày | `Trip` model (origin, destination, dates, party, vehicle, budget, prefs), wizard 3 bước | `03-MODULE.md §M1` |
| 2 | AI tạo lộ trình | Heuristic local, tối đa 3 ngày, chi phí cứng | `POST /trips/{id}/generate` grounded-Gemini, không giới hạn 3 ngày, có lý do chọn | `§M2` |
| 3 | Bản đồ & điểm dừng | `CustomPainter` giả | `flutter_map` + Goong tiles + marker ảnh + polyline thật + GPS | `§M3` |
| 4 | AI Travel Assistant | **Không có** | Chat SSE, tool-calling (thêm/xoá điểm dừng), lịch sử phiên | `§M4` |
| 5 | Tìm kiếm gần đây | Lọc client-side | Nearby API (bán kính 1/3/5/10 km), lịch sử tìm kiếm, gợi ý | `§M5` |
| 6 | Quản lý chuyến đi | Dropdown + Hive | CRUD trip, kéo thả điểm dừng, chia sẻ link, trạng thái | `§M6` |
| 7 | Chi phí chuyến đi | Chỉ ước tính trong engine | Bảng `expenses`, ngân sách, tổng theo ngày/loại, thực tế vs dự kiến | `§M7` |

---

## 6. Lộ trình 7 phase

| Phase | Nội dung | Kết quả bàn giao | Ước lượng |
|---|---|---|---|
| **P0** | Dọn dẹp + chuẩn hoá nền | 4,18 MB, `.gitignore` sạch, xoá dead code, xoá OTP hardcode | ✅ **xong** |
| **P1** | Design system + khung app | `ui/tokens`, `ui/components`, `go_router`, shell 5 tab mới | 2 ngày |
| **P2** | Bản đồ thật | `flutter_map` + Goong tiles + GPS + marker + polyline; xoá 2 `CustomPainter` | 2 ngày |
| **P3** | Module 1 + 3 + 6 (Trip CRUD + bản đồ + quản lý) | Bảng `trips/trip_days/trip_stops`, API CRUD, 3 màn hình | 4 ngày |
| **P4** | Module 2 (AI planner) | Endpoint grounded + `ai_service.dart` + màn kết quả | 3 ngày |
| **P5** | Module 4 + 5 (Assistant + Nearby) | Chat SSE, tool-calling, Nearby + lịch sử | 3 ngày |
| **P6** | Module 7 + hardening | Expenses, sửa IDOR, Alembic, admin thật | 3 ngày |

Tổng: **~17 ngày làm việc** (một người). Chi tiết từng task, từng file và code mẫu: `docs/05-LO-TRINH-CODE.md`.

---

## 7. Tiêu chí nghiệm thu (Definition of Done toàn dự án)

- [ ] `flutter analyze` → **0 error, 0 warning**.
- [ ] `pytest` → **≥ 35 test pass** (17 cũ + ≥ 18 mới cho trips/expenses/ai/places).
- [ ] Không còn `CustomPainter` nào vẽ bản đồ: `grep -r "class.*Painter" lib/` chỉ còn hiệu ứng trang trí.
- [ ] Không còn dữ liệu bịa: `grep -rn "888999\|demo_goong\|_daily_calls\|_build_realistic_local_places" lib/ backend/app/` → rỗng.
- [ ] Mỗi module có ≥ 1 test end-to-end từ app → API → DB.
- [ ] `flutter build web --release` < **60 giây**, bundle < **2 MB** (không tính ảnh).
- [ ] Bản đồ hiển thị tile Goong thật, marker chạm được, polyline khớp Directions API.
- [ ] AI trả lộ trình mà **100% `place_id` tồn tại** trong DB/Places — có test kiểm tra.
- [ ] Tài liệu API (`/docs`) mô tả đủ endpoint mới.

---

## 8. Rủi ro & cách xử lý

| Rủi ro | Mức | Xử lý |
|---|---|---|
| Không có key Goong/Gemini khi phát triển | Cao | Chế độ `DEMO_SEED=1` dùng dữ liệu seed **được đánh dấu rõ** `source:"seed"`, không giả vờ là live |
| Gemini đổi model/giá | Trung bình | Model trong env + `GET /v1beta/models`; không hardcode |
| Chi phí API vượt ngân sách | Trung bình | Cache Places/Directions 24h, rate-limit theo user, quota ngày có thật (đếm từ DB) |
| Refactor 17.500 dòng làm hỏng app | Cao | Làm theo vertical slice; giữ `AppState` cũ đến hết P5 rồi mới xoá |
| Bản đồ Goong hết quota | Trung bình | Fallback OSM tiles (`AppConfig.fallbackOsmTileUrlTemplate` đã có) |
| Thiếu máy chạy Postgres khi demo | Thấp | Giữ SQLite cho dev, Postgres cho Docker; Alembic chạy được cả hai |

---

## 9. Chỉ mục tài liệu

| File | Nội dung |
|---|---|
| [`01-KIEN-TRUC.md`](01-KIEN-TRUC.md) | Kiến trúc, cây thư mục đích, schema DB, luồng dữ liệu, bảo mật |
| [`02-DESIGN-SYSTEM.md`](02-DESIGN-SYSTEM.md) | Token màu/chữ/khoảng cách, bộ component, ánh xạ 8 ảnh |
| [`03-MAN-HINH.md`](03-MAN-HINH.md) | Đặc tả 12 màn hình: cấu trúc, widget, trạng thái, hành vi |
| [`04-API-TICH-HOP.md`](04-API-TICH-HOP.md) | Gemini/Goong/Places/OSRM/Open-Meteo, hợp đồng "không bịa", script kiểm tra |
| [`04a-KET-QUA-XAC-MINH.md`](04a-KET-QUA-XAC-MINH.md) | Số liệu thật đã kiểm tra: giá Gemini, giá Goong, version package |
| [`05-LO-TRINH-CODE.md`](05-LO-TRINH-CODE.md) | Backlog từng file + code mẫu + lệnh kiểm chứng |
| [`06-DON-DEP.md`](06-DON-DEP.md) | Báo cáo dọn dẹp P0, số liệu trước/sau |
