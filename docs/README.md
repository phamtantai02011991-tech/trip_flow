# TripFlow — Bộ tài liệu kế hoạch

Cập nhật: 31/10/2026 · Trạng thái: **P0 hoàn thành**, P1 sẵn sàng bắt đầu.

## Đọc theo thứ tự này

| # | Tài liệu | Dùng để |
|---|---|---|
| 1 | [`00-KE-HOACH-TONG-THE.md`](00-KE-HOACH-TONG-THE.md) | Hiểu hiện trạng, mục tiêu, 7 phase, tiêu chí nghiệm thu |
| 2 | [`01-KIEN-TRUC.md`](01-KIEN-TRUC.md) | Cây thư mục đích, schema DB mới, danh sách API, bảo mật |
| 3 | [`02-DESIGN-SYSTEM.md`](02-DESIGN-SYSTEM.md) | Token màu/chữ/bo góc + bộ component + cách dựng từng ảnh |
| 4 | [`03-MAN-HINH.md`](03-MAN-HINH.md) | Đặc tả 12 màn hình (dữ liệu, thành phần, hành vi, trạng thái) |
| 5 | [`04-API-TICH-HOP.md`](04-API-TICH-HOP.md) | Gemini/Goong/Places/OSM, hợp đồng "AI không bịa", script xác minh |
| 5b | [`04a-KET-QUA-XAC-MINH.md`](04a-KET-QUA-XAC-MINH.md) | **Số liệu thật đã kiểm tra 31/10/2026:** giá Gemini, giá Goong, version package |
| 6 | [`05-LO-TRINH-CODE.md`](05-LO-TRINH-CODE.md) | **Thực thi:** từng task, từng file, code mẫu, lệnh kiểm chứng |
| 7 | [`06-DON-DEP.md`](06-DON-DEP.md) | Đã xoá gì, giải phóng bao nhiêu, cách khôi phục môi trường |

## Bắt đầu code

1. Đọc `05-LO-TRINH-CODE.md` §P0 → làm 9 việc nhỏ (xoá OTP hardcode, dead code…).
2. Làm P1 (design system + router) — kết thúc phải `flutter analyze` sạch.
3. Trước P3, chạy script ở `04-API-TICH-HOP.md` §9 để chốt model Gemini + key Goong, ghi kết quả vào `docs/04a-KET-QUA-XAC-MINH.md`.

## Nguyên tắc không thoả hiệp

- **Không bịa dữ liệu:** LLM chỉ chọn trong danh sách ứng viên backend cung cấp; khoảng cách/thời gian/chi phí do backend tính.
- **Không hardcode model/giá/quota:** tất cả trong `backend/.env`.
- **Không key trong app:** Flutter chỉ gọi backend.
- **Không màu hardcode:** chỉ dùng `AppColors`.
- **Mỗi module có test:** `pytest` ≥ 35 test ở cuối dự án.

## Tình trạng xác minh số liệu API

**Đã xác minh 31/10/2026** (chi tiết + nguồn: [`04a-KET-QUA-XAC-MINH.md`](04a-KET-QUA-XAC-MINH.md)):

- `gemini-3.8-flash` — $0,75 vào / $3,75 ra cho 1M token (đến 31/12/2026), **có free tier**.
- `gemini-3.1-flash-lite` — $0,25 / $1,50 (rẻ nhất cho chat).
- `gemini-4-argon` — $2,00 / $10,00, **không có free tier** → không dùng.
- Goong Directions $2,50/1.000 · Autocomplete $1,40/1.000 · **free credit $100/tháng, 30.000 request**.
- Goong endpoint V2: `/v2/direction`, `/v2/place/autocomplete`, `/v2/place/detail`, `/v2/geocode`, `/Place/Nearby`.
- Package: `flutter_map` 8.3.2 · `go_router` 18.1.2 · `geolocator` 14.1.2 · `google_generative_ai` 0.4.7 (ngừng cập nhật 04/2025).

**Còn thiếu:** bảng RPM/TPM/RPD free tier Gemini (trang render động) và giá Google Places (bảng JS). Không ảnh hưởng kế hoạch vì đã chọn Goong + free tier.

> Ghi chú phương pháp: `web_fetch` của agent lỗi (`EAI_FAIL ipv4only.arpa`) trong sandbox, nên số liệu được lấy bằng `fetch()` của Node 22; dữ liệu thô lưu ở `.research/` (đã gitignore).
