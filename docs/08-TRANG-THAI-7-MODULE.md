# 08 — Trạng thái 7 module (đối chiếu yêu cầu)

> ⚠️ **Tài liệu này đã lỗi thời một phần (01/11/2026).** Danh sách "Chưa làm" bên dưới không còn đúng:
> nhiều mục đã được triển khai, đồng thời phát sinh lỗi bảo mật/khởi động đã được sửa trong đợt kiểm toán 06/11/2026.
> Xem trạng thái chuẩn tại [`09-KIEM-TOAN-TRIEN-KHAI.md`](09-KIEM-TOAN-TRIEN-KHAI.md).

Cập nhật: 01/11/2026 · Ký hiệu: ✅ xong · 🟡 một phần · ⬜ chưa làm

| # | Module | Backend | Flutter | Ghi chú |
|---|---|---|---|---|
| 1 | Tạo chuyến đi | ✅ | ✅ | Wizard 3 bước: chọn thành phố (toạ độ thật), sở thích, ngày/người/phương tiện |
| 2 | AI tạo lộ trình | ✅ | ✅ | Màn tiến trình 3 bước thật + kết quả trên bản đồ + "Tạo lại AI" |
| 3 | Bản đồ & điểm dừng | 🟡 | ✅ | Bản đồ thật, marker đánh số, polyline, chạm marker mở chi tiết. Backend còn dùng khoảng cách chim bay ×1.25 |
| 4 | AI Travel Assistant | ✅ | ✅ | Chat + gợi ý nhanh + hiển thị hành động đã thực thi; mở bằng nút ✨ ở màn tổng quan lộ trình |
| 5 | Tìm kiếm gần đây | ✅ | ✅ | Tab "Gần đây": bản đồ tối, 6 loại địa điểm, bán kính 1/3/5/10 km, danh sách + sheet chi tiết |
| 6 | Quản lý chuyến đi | ✅ | ✅ | Danh sách + lọc, tổng quan, chia sẻ link, xoá điểm dừng, đổi thứ tự (nút lên/xuống trong sheet điểm dừng) |
| 7 | Chi phí chuyến đi | ✅ | ✅ | Màn chi phí: tổng quan ngân sách, thanh tiến độ, theo loại, thêm/xoá khoản chi (vuốt để xoá) |

---

## Luồng "quanh đây" — cách xếp hạng (mới)

Backend tính `quality_score` + `quality_label` cho từng POI trong `places_service._quality`:

| Nhãn | Điều kiện | Ý nghĩa |
|---|---|---|
| `hidden_gem` | rating ≥ 4.5, 20–400 review, giá ≤ 120k **hoặc** loại quán nhỏ (từ khoá `hẻm`, `vỉa hè`, `bình dân`, `chợ`…) | "Quán ruột" địa phương |
| `top_rated` | rating ≥ 4.6 và ≥ 300 review | Được đánh giá cao, đã nổi |
| `popular` | ≥ 800 review | Rất đông |
| `normal` | còn lại | |

- `sort_by=quality` (mặc định của app) xếp theo `quality_score`, phá hoà bằng khoảng cách.
- Lọc thêm: `max_price` (VND), `min_rating`, `open_now`, bán kính 1–10 km.
- UI hiển thị `4.8 (127) · Quán ruột` và số quán ruột trong bán kính.

> **Nguồn rating:** hiện lấy từ DB TripFlow (dữ liệu seed/admin). Muốn có rating như Google Maps phải cấu hình
> `GOONG_API_KEY` (Goong Place Detail trả `rating`) hoặc Google Places API. **Không** cào Google Maps vì vi phạm điều khoản.

---

## API đã có (tổng 24 endpoint mới)

```
# Module 1, 6
GET    /api/v1/trips?status=
POST   /api/v1/trips
GET    /api/v1/trips/{id}
PUT    /api/v1/trips/{id}
DELETE /api/v1/trips/{id}
POST   /api/v1/trips/{id}/duplicate
POST   /api/v1/trips/{id}/share
POST   /api/v1/trips/{id}/days/{n}/stops
DELETE /api/v1/trips/{id}/stops/{sid}
PUT    /api/v1/trips/{id}/days/{n}/reorder

# Module 2
POST   /api/v1/trips/{id}/generate
GET    /api/v1/trips/{id}/ai-status

# Module 4
POST   /api/v1/assistant/chat

# Module 5
GET    /api/v1/places/nearby?lat=&lng=&radius_km=&kinds=&min_rating=&open_now=&sort_by=
GET    /api/v1/places/suggest?q=
GET    /api/v1/places/history
POST   /api/v1/places/history
DELETE /api/v1/places/history/{id}
DELETE /api/v1/places/history

# Module 7
GET    /api/v1/trips/{id}/expenses
POST   /api/v1/trips/{id}/expenses
PUT    /api/v1/trips/{id}/expenses/{eid}
DELETE /api/v1/trips/{id}/expenses/{eid}
GET    /api/v1/trips/{id}/budget-summary
```

---

## Ràng buộc "không bịa dữ liệu" — đã hiện thực ở 3 chỗ

1. **Module 2**: AI chỉ nhận danh sách ứng viên (`d_<id>`, `r_<id>` từ DB) và trả `place_id`; `validate_plan()` loại mọi id lạ, ghi lại số lượng vào `generation_meta_json.hallucinations_removed`.
2. **Module 4**: cùng cơ chế; thêm nữa AI **không tự ghi DB** — backend kiểm tra `place_id`/`stop_id` rồi mới gọi `trip_service`.
3. **Module 5**: kết quả luôn có trường `source` (`catalog`), và trả `note` nói rõ loại địa điểm nào cần Goong/Google Places. Không sinh POI giả như crawler cũ.

---

## Chưa làm (thứ tự ưu tiên)

| Ưu tiên | Việc | File dự kiến |
|---|---|---|
| 1 | Viết test backend cho 3 module mới (chưa chạy được pytest ở sandbox) | `tests/test_trips.py`, `test_places.py`, `test_expenses.py`, `test_assistant.py` |
| 2 | `/maps/directions` (Goong V2) + cache, bỏ khoảng cách chim bay | `services/maps_service.py`, `endpoints/maps.py` |
| 3 | UI: danh sách chuyến, tổng quan lộ trình, wizard 3 bước | `features/trip/*`, `features/planner/*` |
| 4 | UI: Nearby (map tối), Assistant (chat), Expenses | `features/nearby/*`, `features/assistant/*`, `features/expenses/*` |
| 5 | Streaming SSE cho assistant + lịch sử hội thoại trong DB | `assistant_service.py`, `models/ai.py` |
| 6 | Sửa 8 lỗi bảo mật cũ (IDOR itineraries, OTP hardcode…) | xem `01-KIEN-TRUC.md §7` |
