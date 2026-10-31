# 04a — Kết quả xác minh API (số liệu thật)

> **Ngày kiểm tra:** 31/10/2026 · **Phương pháp:** `fetch()` của Node 22 (vì `web_fetch` của agent lỗi `EAI_FAIL ipv4only.arpa` trong sandbox; `curl`/`Invoke-WebRequest` lỗi TLS). Dữ liệu thô lưu ở `.research/` (đã gitignore).
>
> Mọi con số dưới đây **đọc trực tiếp từ trang chính thức**, không suy đoán.

---

## 1. Gemini — model & giá (đã xác minh)

Nguồn: <https://ai.google.dev/gemini-api/docs/pricing?hl=en> và <https://ai.google.dev/gemini-api/docs/models?hl=en>

### 1.1 Bảng giá (USD / 1 triệu token)

| Model ID | Free tier | Input | Output (gồm thinking) | Ghi chú |
|---|---|---|---|---|
| `gemini-3.8-flash` | ✅ Có | **$0,75** (đến 31/12/2026) → $1,50 từ 01/01/2027 | **$3,75** → $7,50 | "Most intelligent Flash" — khuyến nghị chính |
| `gemini-3.6-flash` | ✅ Có | $0,75 → $1,50 | $3,75 → $7,50 | Thế hệ trước, cùng giá |
| `gemini-3.1-flash-lite` | ✅ Có | **$0,25** | **$1,50** | Rẻ nhất cho chat/khối lượng lớn |
| `gemini-3.5-flash-lite` | ✅ Có | $0,30 | $2,50 | |
| `gemini-4-argon` | ❌ **Không** | $2,00 → $4,00 (từ 01/12/2026) | $10,00 → $20,00 | Flagship reasoning, **quá đắt** cho app này |
| `gemini-2.5-flash` | ✅ Có | $0,30 (text/ảnh/video) · $1,00 (audio) | (bảng ghi cùng khung) | Đời cũ, vẫn còn |
| `gemini-2.5-flash-lite` | ✅ Có | $0,10 | $0,40 | Rẻ nhất tuyệt đối |

> ⚠️ `gemini-2.5-flash-image` (Nano Banana) **đã deprecate, tắt 15/03/2027** — không dùng cho dự án mới.

### 1.2 Quyết định cho TripFlow

| Use case | Model | Lý do |
|---|---|---|
| Tạo lộ trình JSON (Module 2) | `gemini-3.8-flash` | Có free tier, structured output tốt, giá $0,75/$3,75 |
| Chat assistant (Module 4) | `gemini-3.1-flash-lite` | Rẻ nhất ($0,25/$1,50), đủ cho hội thoại + tool-calling |
| Vision (chụp menu/biển hiệu) | `gemini-3.8-flash` (multimodal) | Không cần model riêng |
| Dự phòng khi hết quota | `gemini-3.6-flash` (cùng giá) | Cùng thế hệ, cùng schema |

**Ước tính chi phí** (giả định: 1 lần tạo lộ trình ≈ 3.000 token vào + 2.500 token ra; 1 tin chat ≈ 1.200 vào + 400 ra):

| Khối lượng/tháng | Lộ trình | Chat | Chi phí xấp xỉ |
|---|---|---|---|
| 1.000 người dùng, mỗi người 2 lộ trình + 20 tin | 2.000 lần | 20.000 tin | 2.000×(3k×0,75 + 2,5k×3,75)/1e6 ≈ **$23,3** + 20.000×(1,2k×0,25 + 0,4k×1,5)/1e6 ≈ **$18,0** → **~$41/tháng** |
| 100 người dùng (đồ án) | 200 | 2.000 | **~$4,1/tháng** — nằm trong free tier nếu chia nhỏ theo ngày |

> Free tier có giới hạn RPM/TPM/RPD theo model; bảng số cụ thể trên trang rate-limits được render động nên **chưa trích được** — mở <https://ai.google.dev/gemini-api/docs/rate-limits> và ghi lại 3 số (RPM/TPM/RPD) cho 2 model đã chọn.

### 1.3 Structured output — xác nhận hỗ trợ

Nguồn: <https://ai.google.dev/gemini-api/docs/structured-output?hl=en>

| Trường | Hỗ trợ | Ghi chú |
|---|---|---|
| `required` (mảng string tên property) | ✅ | Đúng như tài liệu cũ |
| `anyOf` | ✅ | Có ví dụ chính thức cho schema điều kiện |
| `enum`, `items`, `properties`, `nullable` | ✅ | |
| `minItems` / `maxItems` | ✅ | **Được thực thi** |
| `additionalProperties` | ✅ | Boolean hoặc schema |
| `minimum` / `maximum` | ⚠️ | Tài liệu ghi: một số ràng buộc được **chuẩn hoá** thay vì trả lỗi, không phải lúc nào cũng enforce → phải validate lại ở backend |
| Schema quá lớn (`maxItems` lớn, lồng sâu) | ❌ | Có thể bị từ chối → giữ schema phẳng, `maxItems` nhỏ |

→ Kế hoạch `docs/04-API-TICH-HOP.md §3` vẫn đúng: schema phẳng, `maxItems` rõ ràng, **validate lại** bằng Pydantic.

---

## 2. Goong Maps (đã xác minh)

Nguồn: <https://help.goong.io/kb/rest-api-v2/> (Directions V2, Autocomplete V2, Place Detail V2, Geocode V2) · <https://goong.io/bang-gia/>

### 2.1 Endpoint chính thức

| Dịch vụ | Endpoint | Tham số chính |
|---|---|---|
| Directions **V2** | `GET https://rsapi.goong.io/v2/direction` | `origin=lat,lng`, `destination=lat,lng`, `vehicle=car\|bike\|truck`, `api_key`, (waypoint) |
| Directions **V1** (đang dùng trong code) | `GET https://rsapi.goong.io/Direction` | như trên |
| Autocomplete V2 | `GET https://rsapi.goong.io/v2/place/autocomplete` | `input`, `location=lat,lng`, `api_key`, `has_deprecated_administrative_unit` |
| Autocomplete V1 | `GET https://rsapi.goong.io/Place/AutoComplete` | `input`, `location`, `api_key` |
| Place Detail V2 | `GET https://rsapi.goong.io/v2/place/detail` | `place_id`, `api_key` |
| Place Detail V1 | `GET https://rsapi.goong.io/place/detail` | `place_id`, `api_key` |
| Nearby | `GET https://rsapi.goong.io/Place/Nearby` | `location=lat,lng`, `radius` (m), `api_key` — đã kiểm tra tồn tại (403 `API_KEY_MISSING` khi không key) |
| Geocode V2 | `GET https://rsapi.goong.io/v2/geocode` | `address`, `api_key` |
| Tile style | `https://tiles.goong.io/assets/{style}.json?api_key=<MAP_TILES_KEY>` | style: `goong_map_web` (đang dùng), `goong_map_highlight`, `goong_satellite` |

Response Directions (V2) có: `routes[].legs[].distance.value` (mét), `legs[].duration.value` (giây), `routes[].overview_polyline.points` (encoded) — khớp `GeoUtils.decodePolyline` hiện có.

### 2.2 Giá (USD / 1.000 request)

| Dịch vụ | < 100k/tháng | 100k–200k | 200k–500k |
|---|---|---|---|
| Map Loads | $3,00 | $2,75 | $2,50 |
| **Directions** | **$2,50** | $2,15 | $2,00 |
| **Autocomplete** | **$1,40** | $1,10 | $1,00 |
| SingleSearch + PlaceDetail | $7,00 | $6,25 | $5,50 |
| ACSession + PlaceDetail | $8,00 | $6,50 | $5,75 |
| PlaceDetail | $7,00 | $6,25 | $5,50 |
| Reverse Geocoding | $1,50 | $1,35 | $1,20 |

**Free credit: $100/tháng**, trần 30.000 request/tháng, 5 request/giây, ~1.000 map loads.

### 2.3 Ước tính cho 1.000 người dùng/tháng

| Hoạt động | Số request | Chi phí |
|---|---|---|
| 2.000 lượt tạo lộ trình × 1 direction | 2.000 | $5,00 |
| 10.000 lần autocomplete | 10.000 | $14,00 |
| 4.000 map loads | 4.000 | $12,00 |
| 2.000 place detail | 2.000 | $14,00 |
| **Tổng** | 18.000 | **$45,00 — nằm trong $100 free credit** ✅ |

→ Với đồ án/demo, Goong **miễn phí**; chỉ cần bật cache 24h để không đốt quota.

---

## 3. Package Flutter (đã xác minh trên pub.dev hôm nay)

| Package | Bản mới nhất | Ngày phát hành | Ghi chú |
|---|---|---|---|
| `flutter_map` | **8.3.2** | 27/08/2026 | pubspec đang ghi `^6.1.0` → **phải nâng** (API v7+ khác v6) |
| `latlong2` | **0.10.1** | 27/04/2026 | pubspec đang `^0.9.1` → nâng |
| `go_router` | **18.1.2** | 29/10/2026 | dùng cho routing |
| `geolocator` | **14.1.2** | 19/10/2026 | GPS |
| `google_generative_ai` | 0.4.7 | **17/04/2025** | **18 tháng không cập nhật** → xác nhận quyết định không dùng SDK, gọi qua backend |
| `url_launcher` | 6.3.3 | 02/10/2026 | mở Google Maps, gọi điện |
| `intl` | 0.20.3 | 25/06/2026 | format tiền/ngày |

### Điều chỉnh cần làm trong `pubspec.yaml`

```yaml
dependencies:
  flutter_map: ^8.3.2      # từ ^6.1.0 — API MapOptions/TileLayer đổi
  latlong2: ^0.10.1        # từ ^0.9.1
  go_router: ^18.1.2       # mới
  geolocator: ^14.1.2      # mới
  url_launcher: ^6.3.3     # mới
  intl: ^0.20.3            # mới
  # cupertino_icons: bỏ (0 import)
```

> **Lưu ý flutter_map 8:** `MapOptions(initialCenter:, initialZoom:)`, `TileLayer(urlTemplate:)`, `MarkerLayer`, `PolylineLayer`, `RichAttributionWidget` — code mẫu trong `docs/05-LO-TRINH-CODE.md §P2.3` đã viết theo API này.

---

## 4. Google Maps Platform (một phần)

- Danh sách SKU Places API (Mới) lấy được: `Nearby Search Pro`, `Nearby Search Enterprise`, `Place Details Essentials`, `Place Details Pro`, `Autocomplete`, `Autocomplete Session Usage`, `Text Search Pro/Enterprise`, `Photos`.
- **Bảng giá số cụ thể chưa trích được** (render bằng JS). Cần mở <https://mapsplatform.google.com/pricing/> và đọc tay nếu muốn dùng Google Places.

**Kết luận:** với đồ án, **không cần Google Places** — Goong đã có Nearby + Place Detail + Autocomplete với free credit $100/tháng. Chỉ bật Google Places nếu cần ảnh/đánh giá phong phú, và khi đó phải đọc lại điều khoản cache.

---

## 5. Việc còn phải xác minh (danh sách ngắn)

| # | Việc | Cách làm |
|---|---|---|
| 1 | RPM/TPM/RPD free tier của `gemini-3.8-flash` và `gemini-3.1-flash-lite` | Mở trang rate-limits, ghi 3 số mỗi model |
| 2 | Giá Google Places (nếu dùng) | Đọc bảng SKU |
| 3 | Chất lượng polyline Goong thực tế | Gọi thử 1 tuyến với key thật, so với Google Maps |
| 4 | `goong_map_web` style có còn hỗ trợ không | Gọi tile với key thật, xem HTTP 200 hay 403 |

Ghi kết quả vào chính file này (mục "Đã xác minh bổ sung") để lần sau không phải tra lại.
