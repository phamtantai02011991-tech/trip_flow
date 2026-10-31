# 03 — Đặc tả màn hình (12 màn)

> Mỗi màn: mục đích · dữ liệu vào · thành phần · hành vi · trạng thái · file đích.
> Token & component: xem [`02-DESIGN-SYSTEM.md`](02-DESIGN-SYSTEM.md).

---

## Danh sách màn hình

| # | Màn | Route | Ảnh | Trạng thái hiện tại |
|---|---|---|---|---|
| 1 | Onboarding | `/onboarding` | 8 | **chưa có** |
| 2 | Home | `/` | 1 | có, cần dựng lại |
| 3 | Nearby | `/nearby` | 4, 9 | **chưa có** (chỉ có corridor search) |
| 4 | Search | `/search` | 9 | có một phần (`destinations_screen`) |
| 5 | Planner wizard | `/plan/new` | 5 | có, thiếu 4 trường + validate |
| 6 | AI generating | `/plan/new/loading` | – | **chưa có** |
| 7 | Trip overview | `/trips/:id` | 2, 7 | có, bản đồ giả |
| 8 | Day timeline | `/trips/:id/day/:n` | 2 | có một phần (`itinerary_screen`) |
| 9 | Stop detail | `/trips/:id/stop/:sid` | 3 | có (`stop_detail_sheet`) |
| 10 | Expenses | `/trips/:id/expenses` | – | **chưa có** |
| 11 | Assistant | `/assistant` | 8 | **chưa có** |
| 12 | Profile & favorites | `/profile` | – | có, dọn lại |

---

## 1. Onboarding (`features/onboarding/onboarding_screen.dart`)

**Mục đích:** giới thiệu 3 giá trị (lập kế hoạch · tìm quanh đây · trợ lý AI) + xin quyền vị trí.

- **PageView 3 trang**, mỗi trang: ảnh minh hoạ nửa trên, tiêu đề `display`, mô tả `body`, chấm chỉ báo.
- Trang 3: nút "Bắt đầu" (coral, full width) + "Tôi đã có tài khoản" (text).
- Xin quyền vị trí **sau** khi bấm Bắt đầu, kèm giải thích trước (`showDialog` lý do).
- Lưu cờ `onboarding_done` vào Hive → lần sau vào thẳng Home.
- Không hiện lại khi đã đăng nhập.

**Trạng thái:** không có loading; lỗi quyền vị trí → vẫn cho vào app, "Gần đây" hiện `EmptyState` + nút "Bật vị trí".

---

## 2. Home (`features/home/home_screen.dart`)

**Dữ liệu:** `GET /itineraries?templates_only=true` (chuyến mẫu) · `GET /destinations?featured_only=true&page_size=8` · `GET /places/nearby?radius_km=5&limit=3` nếu có GPS.

| Khối | Nội dung | Hành vi |
|---|---|---|
| Header | "Chào, {tên}" + "Đi đâu tiếp theo?" + chuông | Chuông → `/notifications` (badge = số thông báo chưa đọc; **không** SnackBar giả) |
| Hero deck | 3 chuyến mẫu, ảnh thật từ DB | Chạm card → `/trips/:id` (chế độ xem mẫu); nút ↗ → chi tiết; vuốt → đổi card, dots cập nhật |
| Popular | 8 destination `is_featured` | Chạm → `DestinationDetailScreen`; "Xem tất cả" → `/search?cat=destination` |
| Gần bạn | 3 POI gần nhất | Chạm → bottom sheet ảnh 9 |
| CTA nổi | "Tạo chuyến mới" pill coral | → `/plan/new` |

**Không được:** hardcode giá chuyến (`350000`…). Giá lấy từ `Trip.budget_amount` hoặc ẩn nếu `null`.

**Trạng thái:** loading → skeleton 3 card + 3 tile; lỗi → banner offline + dữ liệu Hive; GPS tắt → ẩn khối "Gần bạn".

---

## 3. Nearby (`features/nearby/nearby_screen.dart`) — ảnh 4 & 9

**Dữ liệu:** `GET /places/nearby?lat&lng&radius_km&kinds=food,cafe,hotel,gas,ev,rest,sight&limit=40` + cache 24h.

**Bố cục:** map tối full-screen, sheet kéo được (min 42%, max 88%).

| Thành phần | Chi tiết |
|---|---|
| Search bar nổi | Tròn, có icon search + avatar phải; chạm → `/search` |
| Chip lọc | Nhà hàng · Cà phê · Khách sạn · Xăng · Sạc · Nghỉ chân · Tham quan — chọn nhiều, mặc định "Nhà hàng" |
| Bộ lọc nâng cao (bottom sheet) | Bán kính 1/3/5/10 km · Đánh giá ≥ 4.0 · Đang mở · Giá thấp→cao · Gần nhất |
| Marker | Pin màu theo `kind`, marker đang chọn to hơn 1.3× + pulse |
| Danh sách | `PlaceListTile`: ảnh 72, tên, rating + số review, "Đang mở cửa" (xanh) / "Đã đóng" (đỏ), khoảng cách + thời gian đi bộ/xe |
| Chi tiết (ảnh 9) | Ảnh 16:9 · tên · loại · giờ mở cửa · địa chỉ · 4 nút: Lưu · Gọi · Chỉ đường · Thêm vào chuyến |

**Hành vi:** kéo map → "Tìm khu vực này" (chip nổi giữa trên); chạm marker ↔ danh sách sync (item tương ứng tự scroll + highlight); GPS mặc định vị trí hiện tại, không có quyền → mặc định trung tâm tỉnh đang chọn.

**Hiệu năng:** chỉ gọi lại API khi di chuyển > 300 m hoặc đổi filter; debounce 400 ms.

---

## 4. Search (`features/search/search_screen.dart`)

- Search bar có nút back; gõ ≥ 2 ký tự → `GET /search/suggest?q=` (debounce 300 ms).
- **Khi chưa gõ:** "Tìm gần đây" (5 item từ `/search/history`) + "Danh mục" (grid 6 icon: Địa điểm, Quán ăn, Cà phê, Khách sạn, Xăng/Sạc, Nghỉ chân).
- Kết quả nhóm theo loại: Địa điểm · Quán ăn · Tỉnh thành; mỗi nhóm ≤ 5 + "Xem thêm".
- Chạm kết quả → ghi vào lịch sử (`POST /search/history`) → mở chi tiết.
- Xoá 1 item lịch sử (icon ×) hoặc "Xoá tất cả" (có xác nhận).

---

## 5. Planner wizard (`features/planner/planner_wizard_screen.dart`) — ảnh 5

**3 bước**, state giữ trong `PlannerDraft` (Riverpod), không mất khi back.

| Bước | Trường | Validate |
|---|---|---|
| 1 | Điểm đi (GPS hoặc nhập, autocomplete) · Điểm đến (autocomplete hoặc "Để AI gợi ý") | Bắt buộc có điểm đi; điểm đến có thể trống nếu chọn "AI gợi ý"; điểm đi ≠ điểm đến |
| 2 | Sở thích (chọn nhiều, **không tick sẵn**) · Ngân sách (Tiết kiệm/Trung bình/Thoải mái + số tiền tuỳ chọn) · Ghi chú tự do | ≥ 1 sở thích nếu muốn AI gợi ý điểm đến |
| 3 | Số ngày (1–14) · Ngày khởi hành (date picker) · Số người (1–20) · Phương tiện | Ngày khởi hành ≥ hôm nay; số ngày ≥ 1 |

**Kết thúc:** `POST /trips` (draft) → `POST /trips/{id}/generate` → `/plan/new/loading` → `/trips/{id}`.

**Ghi chú:** GPS lấy được thì prefill điểm đi nhưng vẫn cho sửa; "Chọn trên bản đồ" mở map chọn toạ độ.

---

## 6. AI generating (`features/planner/ai_generating_screen.dart`)

- Hiển thị 4 bước **thật** theo SSE/progress từ backend: `route` (đang tìm tuyến đường) → `candidates` (đang tìm điểm dừng) → `schedule` (đang xếp lịch) → `cost` (đang tính chi phí).
- Mỗi bước có icon + trạng thái (chờ/đang/xong), không phải animation giả — backend trả `event: progress`.
- Có nút "Huỷ" (gọi `DELETE`/abort) sau 3 giây.
- Lỗi → nút "Thử lại" + "Dùng lộ trình gợi ý mặc định" (rule-based, ghi rõ nguồn).

---

## 7. Trip overview (`features/trip/trip_overview_screen.dart`) — ảnh 2 & 7

**Dữ liệu:** `GET /trips/{id}` (kèm days, stops, tổng chi phí, polyline cached).

| Vùng | Chi tiết |
|---|---|
| Map (55%) | `FlutterMap` tile sáng · polyline coral 4px (viền trắng) · `PhotoMarker` từng stop · camera `fitCamera` toàn tuyến |
| Header nổi | Back tròn · "Tổng quan lộ trình" · tên chuyến · menu "…" (Đổi tên, Nhân bản, Chia sẻ, Lưu trữ, Xoá) |
| Sheet | Ngày đi / Ngày về + "Đổi" · `DayPill` · danh sách `StopCard` ngang |
| StopCard | Ảnh, giờ "07:00 – 10:00", tên, loại + khoảng cách, kéo-thả để đổi thứ tự (long-press) |
| Chân sheet | Tổng: `2 ngày · 320 km · 1.450.000đ` + nút "Chi phí" → `/expenses` |
| Tablet | Layout 2 cột: panel 380 trái + map phải (ảnh 7); thêm card thời tiết |

**Hành vi:** chạm stop → `/stop/:sid`; kéo stop trong ngày → `PUT /trips/{id}/days/{d}/reorder`; đổi ngày → map chỉ hiện stop của ngày đó (`fitCamera` lại).

**Trạng thái:** đang tối ưu thứ tự → banner "Đang sắp xếp lại lộ trình…"; lỗi mạng → dùng bản Hive + nhãn "Bản lưu {thời gian}".

---

## 8. Day timeline (`features/trip/day_timeline_screen.dart`)

- Timeline dọc: giờ bên trái (cột 64, `caption`), đường nối dọc, chấm màu theo `kind`.
- Mỗi item: tên, địa chỉ 1 dòng, thời gian lưu lại, chi phí dự kiến, nút "…" (Sửa/Xoá/Thay thế).
- Giữa 2 stop: dòng "🚗 32 phút · 18,4 km" (từ `travel_mins_from_prev`), chạm → chỉ đường.
- `ReorderableListView` thật (hiện chưa có), kéo xong gọi API.
- Nút "+ Thêm điểm dừng": chọn từ Gần đây / Đã lưu / Tìm kiếm / Tự nhập.

---

## 9. Stop detail (`features/trip/stop_detail_screen.dart`) — ảnh 3

- Ảnh full-bleed + `Hero` từ card.
- Chip "Ngày {n}" + "Điểm dừng {k}".
- Tên lớn, rating + số review (từ Places), loại + khoảng cách từ vị trí hiện tại.
- Card trắng: địa chỉ, giờ mở cửa hôm nay, giá trung bình, SĐT.
- Hành động: **Chỉ đường** (mở Google/Apple Maps qua `url_launcher` với `geo:`/`https://www.google.com/maps/dir`), **Gọi** (`tel:`), **Thêm vào chuyến**, **Lưu**.
- Dải thumbnail ảnh thật; nếu không có ảnh → `PlaceholderImage` (không dùng URL demo giả).
- Ẩn nút "Chỉ đường"/"Gọi" nếu thiếu dữ liệu, thay bằng disable + tooltip lý do.

---

## 10. Expenses (`features/expenses/expenses_screen.dart`)

| Vùng | Chi tiết |
|---|---|
| Tổng quan | Donut chart: Xăng · Ăn uống · Khách sạn · Vé · Khác; giữa vòng: tổng đã chi / ngân sách |
| Thanh ngân sách | `LinearProgressIndicator` coral, đỏ khi vượt; chữ "Đã dùng 72% ngân sách" |
| Danh sách | Nhóm theo ngày, mỗi dòng: icon loại, tên, "Dự kiến"/"Thực tế" badge, số tiền, nút sửa/xoá |
| Thêm | `showModalBottomSheet`: loại (chips), số tiền (bàn phím số + format nghìn), ngày, ghi chú, "dự kiến/thực tế" |
| So sánh | Card "Dự kiến 1.850.000đ · Thực tế 1.420.000đ · Tiết kiệm 430.000đ" |

**Tính toán:** tổng theo loại/ngày làm ở backend (`GET /budget-summary`) để admin và app khớp số.

---

## 11. Assistant (`features/assistant/assistant_screen.dart`) — ảnh 8

- Khung chat: bong bóng user (coral, phải), AI (trắng viền line, trái), có `timestamp`.
- Streaming: hiện từng token; có nút "Dừng".
- Suggestion chips khi mới mở: "Lên lịch 3 ngày Đà Lạt", "Quán ăn gần đây", "Đi đâu tháng 11?".
- Khi AI chạy tool (thêm/xoá điểm dừng): hiện card hành động "Đã thêm **Bún chả Hương Liên** vào Ngày 2 lúc 12:00" + nút "Xem chuyến" / "Hoàn tác".
- Nút mic: ghi âm → gửi (P6; chưa có thì ẩn).
- Lịch sử: `GET /assistant/sessions`; menu "…" → đổi tên/xoá phiên.

---

## 12. Profile & favorites (`features/profile/profile_screen.dart`)

- Header: avatar, tên, SĐT, nút "Sửa".
- Nhóm: Chuyến đi của tôi (số lượng) · Đã lưu (3 tab: Địa điểm/Quán ăn/Ẩm thực) · Chi phí tổng · Cài đặt.
- Cài đặt: thông báo, đơn vị tiền (VND), ngôn ngữ (vi/en), **chế độ offline** (hiển thị thật: số bản ghi đã lưu), đăng xuất.
- **Xoá** 2 công tắc dev giả hiện tại (`L300`, `L321` "quyền vị trí"/"offline giả lập").

---

## Phụ lục: màn cũ cần xử lý

| File hiện tại | Xử lý |
|---|---|
| `features/provinces/provinces_screen.dart` | Giữ, gộp vào `/search` dạng chọn tỉnh |
| `features/destinations/destinations_screen.dart` | Giữ, đổi tên `destination_list_screen.dart`, dùng search chung |
| `features/restaurants/restaurants_screen.dart` | Gộp vào `/nearby` (chip Nhà hàng) |
| `features/local_foods/local_foods_screen.dart` | Giữ làm tab trong `/discover` |
| `features/maps/map_corridor_screen.dart` | **Xoá** sau khi Nearby + Trip overview hoàn thành (giữ tính năng corridor qua API) |
| `core/widgets/itinerary_timeline_card.dart` | Đã dead code → xoá |
| `features/itinerary/itinerary_screen.dart` | Tách thành `trip_list_screen.dart` + `day_timeline_screen.dart` |
| `features/auth/*` | Giữ, sửa OTP hardcode, bỏ email/pass điền sẵn |
