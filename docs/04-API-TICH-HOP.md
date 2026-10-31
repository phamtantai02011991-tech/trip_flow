# 04 — Tích hợp API thật (Gemini · Goong · Places · OSM · Weather)

> **Nguyên tắc số 1: không bịa số liệu.** Giá, model và quota dưới đây **đã được xác minh ngày 31/10/2026** từ trang chính thức — chi tiết + nguồn ở [`04a-KET-QUA-XAC-MINH.md`](04a-KET-QUA-XAC-MINH.md).

---

## 0. Trạng thái xác minh

| Hạng mục | Trạng thái | Giá trị đã chốt |
|---|---|---|
| Endpoint Gemini `:generateContent` | ✅ Đã xác minh | `POST /v1beta/models/{model}:generateContent` |
| `responseSchema` (OpenAPI subset) | ✅ Đã xác minh | `required` là mảng string; hỗ trợ `anyOf`, `enum`, `minItems/maxItems`, `additionalProperties` |
| Function calling | ✅ Đã xác minh | `tools.functionDeclarations` + vòng lặp `functionResponse`, tool song song được |
| Model + giá Gemini | ✅ **Đã xác minh** | `gemini-3.8-flash`: $0,75 vào / $3,75 ra cho 1M token, **có free tier** (đến 31/12/2026) |
| Model chat rẻ | ✅ **Đã xác minh** | `gemini-3.1-flash-lite`: $0,25 / $1,50 |
| Endpoint Goong | ✅ **Đã xác minh** | V2: `/v2/direction`, `/v2/place/autocomplete`, `/v2/place/detail`, `/v2/geocode`; V1 vẫn dùng được |
| Giá Goong | ✅ **Đã xác minh** | Directions $2,50/1.000 · Autocomplete $1,40/1.000 · **free credit $100/tháng, 30.000 request** |
| Giá Google Places | ⚠️ Chưa trích được | Bảng render JS — chỉ cần nếu chọn Google Places |
| RPM/TPM/RPD free tier Gemini | ⚠️ Chưa trích được | Bảng động; mở trang rate-limits ghi tay 3 số |

> **Không hardcode model.** Dùng env + `GET /v1beta/models` (xem §4.1) để app không chết khi Google đổi lineup — ví dụ hiện tại đã có `gemini-4-argon`, `gemini-3.8-flash`, `gemini-3.6-flash`, `gemini-3.1-flash-lite`.

---

## 1. Chọn nhà cung cấp bản đồ

| Tiêu chí | Goong Maps | Google Maps Platform | OSM (Overpass + OSRM + tile) |
|---|---|---|---|
| Dữ liệu Việt Nam | ✅ Rất tốt (bản địa) | ✅ Tốt | ⚠️ Trung bình, thiếu POI nhỏ |
| Có sẵn key miễn phí | ✅ Có gói dùng thử | ⚠️ Cần thẻ + billing | ✅ Không key |
| Chỉ đường | ✅ `/Direction` | ✅ Routes API | ✅ OSRM demo (chỉ test) |
| Ảnh địa điểm | ❌ | ✅ Place Photos (có điều kiện lưu trữ) | ⚠️ Wikimedia |
| Rủi ro pháp lý | Thấp | Trung bình (điều khoản cache) | Thấp (ODbL, phải ghi nguồn) |
| Chi phí | **Cần xác minh** | **Cần xác minh** | Miễn phí nhưng bị rate-limit |

**Quyết định:** dùng **Goong** làm chính (tile + directions + autocomplete), **OSM/Overpass** làm fallback khi hết quota hoặc mất mạng, **Google Places** chỉ bật khi có key (để lấy giờ mở cửa/ảnh chính xác). Tất cả đi qua backend — **client không giữ key**.

---

## 2. Cấu hình (env) — không hardcode

```dotenv
# backend/.env
GEMINI_API_KEY=                     # bắt buộc ở production
GEMINI_API_BASE=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL_PLANNER=               # rỗng → backend tự chọn model đầu tiên hỗ trợ generateContent
GEMINI_MODEL_CHAT=
GEMINI_MODEL_VISION=
GEMINI_TIMEOUT_SECONDS=60
GEMINI_MAX_OUTPUT_TOKENS_PLANNER=8192

GOONG_API_KEY=                      # REST key (directions, autocomplete)
GOONG_MAPTILES_KEY=                 # key riêng cho tile
GOONG_BASE_URL=https://rsapi.goong.io
GOONG_TIMEOUT_SECONDS=8

GOOGLE_PLACES_API_KEY=              # tuỳ chọn
MAPS_PROVIDER=goong                 # goong | google | osm
PLACES_CACHE_TTL_HOURS=24
MAPS_DAILY_BUDGET_LIMIT=500         # số request/ngày, đếm THẬT trong DB

# Flutter --dart-define
API_BASE_URL=http://10.0.2.2:8000/api/v1
```

**Quy tắc:** `AppConfig` (Flutter) **không chứa** bất kỳ key nào. Chỉ `API_BASE_URL` + cờ debug.

---

## 3. Hợp đồng "AI không bịa" (quan trọng nhất tài liệu này)

### 3.1 Vấn đề

Nếu đưa Gemini câu "lên lịch trình 3 ngày Đà Lạt", model sẽ **tự sinh** tên quán, địa chỉ, toạ độ, giờ mở cửa. Không kiểm chứng được → dữ liệu sai, nguy hiểm (chỉ đường tới nơi không tồn tại).

### 3.2 Hợp đồng 5 bước

```
B1. Backend gom ỨNG VIÊN THẬT (C):
    - destinations trong DB tỉnh đích (rating, category, hours, price)
    - restaurants dọc tuyến (corridor search + SFCS) — tối đa 25
    - POI nearby theo sở thích (Places/Goong) — tối đa 25
    - trạm nghỉ/xăng/sạc dọc tuyến — tối đa 10
    Mỗi item: { "id": "d_12" | "r_9" | "p_ChIJ...", "name", "kind", "lat", "lng",
                "rating", "open_hours", "price_hint", "dist_from_route_km" }

B2. Prompt CHỈ chứa C + ràng buộc:
    "Chỉ được chọn các địa điểm có trong DANH SÁCH. Không tạo địa điểm mới.
     Không tự bịa toạ độ, giờ mở cửa, giá, khoảng cách.
     Trả JSON theo schema: days[].stops[].place_id, arrive, stay_min, reason."

B3. Gemini trả JSON (responseMimeType=application/json + responseSchema).

B4. VALIDATE (hàng rào):
    - Mọi place_id phải ∈ C. Cái nào lạc → loại bỏ + log "hallucinated: X".
    - Không có stop nào → retry 1 lần với prompt nhấn mạnh; vẫn lỗi → fallback rule-based.
    - Tổng thời gian mỗi ngày ≤ 14h, số stop/ngày ≤ 8, không trùng địa điểm.

B5. Backend TỰ TÍNH:
    - travel_mins / distance_km: Directions API (không tin số AI đưa)
    - est_cost: bảng giá nội bộ (vé, ăn, xăng theo km × đơn giá nhiên liệu)
    - arrive_at: cộng dồn từ giờ khởi hành + travel + stay
    - Nếu AI trả "arrive" lệch > 60 phút so với tính toán → dùng số backend.
```

### 3.3 Schema trả về (Pydantic → map sang Gemini dialect)

```python
class AiStop(BaseModel):
    place_id: str
    arrive: str          # "09:30"
    stay_min: int = Field(ge=15, le=240)
    reason: str = Field(max_length=160)   # giải thích ngắn, không chứa số liệu bịa

class AiDay(BaseModel):
    day: int
    title: str
    stops: list[AiStop] = Field(min_length=1, max_length=8)

class AiPlan(BaseModel):
    summary: str = Field(max_length=400)
    days: list[AiDay]
    tips: list[str] = Field(default_factory=list, max_length=5)  # thời tiết, hành lý
```

Chuyển sang `responseSchema`: `type: OBJECT/ARRAY/STRING/INTEGER`, `properties`, `required` (mảng string), `propertyOrdering`. **Không** dùng `$ref`, `$defs`, `additionalProperties` (Gemini không hỗ trợ).

### 3.4 Prompt mẫu (rút gọn)

```text
Bạn là chuyên gia lập lịch trình du lịch Việt Nam.
CHUYẾN ĐI: {origin} → {destination}, {days} ngày, {party} người,
phương tiện {vehicle}, ngân sách {budget}, sở thích: {prefs}.
GIỜ KHỞI HÀNH: {start_time}. Vận tốc trung bình tham chiếu: {avg_speed} km/h.

DANH SÁCH ĐỊA ĐIỂM ĐƯỢC PHÉP CHỌN (chỉ chọn trong đây):
[{"id":"d_3","name":"Hồ Xuân Hương","kind":"sight","lat":11.94,"lng":108.44,
  "rating":4.6,"hours":"06:00-18:00","price":0},
 {"id":"r_8","name":"Bánh căn Nhà Chung","kind":"food","lat":11.93,"lng":108.43,
  "rating":4.4,"hours":"07:00-22:00","price":45000}, ...]

YÊU CẦU:
1. Không tạo địa điểm ngoài danh sách. Không suy đoán toạ độ/giờ/giá.
2. Mỗi ngày 4–6 điểm, có ăn sáng/trưa/tối, chèn nghỉ khi chặng > 2 giờ.
3. Ưu tiên sở thích người dùng; giữ thời gian di chuyển thực tế.
4. Trả về JSON đúng schema. Trường "reason" ≤ 20 từ, không chứa số liệu.
```

---

## 4. Gemini — chi tiết triển khai

### 4.1 Gọi HTTP thuần (không SDK, không key ở client)

```python
# backend/app/integrations/gemini_client.py
import httpx
from app.core.config import settings

class GeminiClient:
    def __init__(self) -> None:
        self._base = settings.GEMINI_API_BASE        # .../v1beta
        self._key  = settings.GEMINI_API_KEY
        self._models: list[dict] | None = None

    async def _resolve_model(self, prefer: str | None) -> str:
        """Không hardcode model: chọn model đầu tiên hỗ trợ generateContent."""
        if prefer:
            return prefer
        if self._models is None:
            async with httpx.AsyncClient(timeout=10) as c:
                r = await c.get(f"{self._base}/models", headers=self._headers())
                r.raise_for_status()
                self._models = r.json().get("models", [])
        usable = [m for m in self._models
                  if "generateContent" in m.get("supportedGenerationMethods", [])]
        if not usable:
            raise RuntimeError("Không có model generateContent khả dụng")
        return usable[0]["name"].removeprefix("models/")

    def _headers(self) -> dict[str, str]:
        return {"x-goog-api-key": self._key, "Content-Type": "application/json"}

    async def generate_json(self, prompt: str, schema: dict, model: str | None = None,
                            max_tokens: int = 8192) -> dict:
        name = await self._resolve_model(model or settings.GEMINI_MODEL_PLANNER)
        body = {
            "contents": [{"role": "user", "parts": [{"text": prompt}]}],
            "generationConfig": {
                "responseMimeType": "application/json",
                "responseSchema": schema,
                "temperature": 0.4,
                "maxOutputTokens": max_tokens,
            },
            "safetySettings": [
                {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
                {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
                {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"},
                {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"},
            ],
        }
        url = f"{self._base}/models/{name}:generateContent"
        async with httpx.AsyncClient(timeout=settings.GEMINI_TIMEOUT_SECONDS) as c:
            r = await c.post(url, headers=self._headers(), json=body)
            r.raise_for_status()
            data = r.json()

        cand = (data.get("candidates") or [{}])[0]
        if cand.get("finishReason") == "MAX_TOKENS":
            raise ValueError("Output bị cắt (MAX_TOKENS) — tăng maxOutputTokens")
        if cand.get("finishReason") == "SAFETY":
            raise ValueError("Bị chặn bởi safety filter")
        text = "".join(p.get("text", "") for p in cand["content"]["parts"])
        return json.loads(text)
```

> Đường dẫn `:generateContent` trả JSON. Với chat streaming, dùng `:streamGenerateContent?alt=sse` và proxy bằng `StreamingResponse(media_type="text/event-stream")`.

### 4.2 Chat có tool-calling (Module 4)

Tools cho model: `search_places(query, lat, lng, kind)`, `add_stop(trip_id, day, place_id, arrive, stay_min)`, `remove_stop(trip_id, stop_id)`, `move_stop(trip_id, stop_id, day, order)`, `set_budget(trip_id, amount)`.

Vòng lặp:

```python
async def chat_turn(session, user_text: str, trip_id: str | None) -> AsyncIterator[str]:
    contents = load_history(session) + [user_msg(user_text)]
    for _ in range(5):                      # chống loop
        resp = await gemini.generate(contents, tools=TOOLS)
        parts = resp["candidates"][0]["content"]["parts"]
        fn_calls = [p["functionCall"] for p in parts if "functionCall" in p]
        if not fn_calls:
            for p in parts:
                if "text" in p: yield p["text"]
            contents.append(resp["candidates"][0]["content"])
            break
        contents.append(resp["candidates"][0]["content"])          # role model
        results = [{"functionResponse": {"name": fc["name"],
                    "response": run_tool(fc, session.user_id, trip_id)}} for fc in fn_calls]
        contents.append({"role": "user", "parts": results})         # nhiều tool song song
```

**Bắt buộc:** mọi `run_tool` kiểm tra owner (`trip.user_id == session.user_id`) trước khi ghi DB.

### 4.3 Lỗi cần xử lý (không được crash app)

| Trường hợp | Xử lý |
|---|---|
| `finishReason: SAFETY` | Trả 200 với `{status:"blocked", message:"..."}`, UI hiện fallback |
| `finishReason: MAX_TOKENS` | Retry 1 lần với `maxOutputTokens` cao hơn, rồi fallback rule-based |
| 429 / quota | Backoff luỹ thừa, trả `{status:"busy"}` sau 3 lần; UI "AI đang bận, thử lại sau 1 phút" |
| 400 schema sai | Log body + schema, **không** retry (lỗi code) |
| JSON không parse được | Retry 1 lần với `temperature: 0.1`, rồi fallback |
| Timeout | Huỷ, báo lỗi mạng, giữ draft |

### 4.4 Chi phí — chỉ đo, không đoán

- Lưu `tokens_in`, `tokens_out` (từ `usageMetadata`) vào `AiMessage` mỗi lượt.
- `GET /admin/ai-usage?from=&to=` trả tổng token, số lượt, **chi phí tính theo bảng giá đọc từ env** (`GEMINI_PRICE_IN_PER_M`, `GEMINI_PRICE_OUT_PER_M`) — giá do người triển khai điền sau khi xác minh, **không hardcode**.
- Hạn mức: mỗi user 5 lần tạo lộ trình/ngày (đếm trong DB), chat 20 tin/phút.

---

## 5. Goong Maps — đã xác minh từ help.goong.io

| Mục | Giá trị (đã kiểm tra) |
|---|---|
| Directions V2 | `GET https://rsapi.goong.io/v2/direction?origin=lat,lng&destination=lat,lng&vehicle=car|bike&api_key=…` |
| Directions V1 (code hiện tại) | `GET https://rsapi.goong.io/Direction?...` — vẫn hoạt động |
| Autocomplete V2 | `GET https://rsapi.goong.io/v2/place/autocomplete?input=…&location=lat,lng&api_key=…` |
| Place Detail V2 | `GET https://rsapi.goong.io/v2/place/detail?place_id=…&api_key=…` |
| Nearby | `GET https://rsapi.goong.io/Place/Nearby?location=lat,lng&radius=1000&api_key=…` |
| Geocode V2 | `GET https://rsapi.goong.io/v2/geocode?address=…&api_key=…` |
| Tile style | `https://tiles.goong.io/assets/{style}.json?api_key=<MAP_TILES_KEY>` — `goong_map_web`, `goong_map_highlight`, `goong_satellite` |
| Giá | Directions **$2,50/1.000** · Autocomplete **$1,40/1.000** · PlaceDetail $7,00/1.000 · Map load $3,00/1.000 |
| Miễn phí | **$100 credit/tháng**, trần 30.000 request/tháng, 5 req/giây |

**Việc phải làm với `goong_client.py`:**

1. **Xoá** `_generate_smart_urban_polyline` (sinh polyline giả). Không có key → trả lỗi `MAPS_UNAVAILABLE`, không giả vờ.
2. Response polyline thật: `routes[0].overview_polyline.points` (encoded) → decode bằng `GeoUtils.decodePolyline` đã có.
3. Cache theo `(origin, destination, vehicle, waypoints)` trong `place_cache` TTL 24h.
4. Đếm request thật vào bảng `api_usage` (không dùng `_daily_calls=18` giả).
5. Nếu `GOONG_API_KEY` rỗng và `MAPS_PROVIDER=osm` → dùng OSRM (§7).
6. Dùng **V2** cho endpoint mới (`/v2/direction`) vì đây là API hiện hành; V1 chỉ để tương thích.

> **Lưu ý giá:** 18.000 request/tháng ước tính cho 1.000 người dùng ≈ **$45**, vẫn nằm trong $100 free credit. Bật cache 24h là đủ để không vượt.

---

## 6. Google Places API (New) — tuỳ chọn

| Thao tác | Endpoint (cấu trúc tin cậy) |
|---|---|
| Nearby | `POST https://places.googleapis.com/v1/places:searchNearby` |
| Text search | `POST https://places.googleapis.com/v1/places:searchText` |
| Details | `GET https://places.googleapis.com/v1/places/{place_id}` |
| Autocomplete | `POST https://places.googleapis.com/v1/places:autocomplete` |

- Bắt buộc header `X-Goog-Api-Key` + `X-Goog-FieldMask` (chỉ xin trường cần: `places.id,places.displayName,places.location,places.rating,places.userRatingCount,places.regularOpeningHours,places.priceLevel,places.formattedAddress,places.internationalPhoneNumber`). **Không** xin `places.photos` hàng loạt (tốn SKU).
- Điều khoản: **không** cache lâu dài nội dung Places ngoài giới hạn cho phép; dự án này cache 24h trong `place_cache` cho mục đích hiển thị — **phải đọc lại điều khoản** trước khi phát hành. Nếu không chắc, dùng Goong cho tên/giờ/giá và chỉ dùng Places cho ảnh.
- Giá theo SKU: **CHƯA XÁC MINH**; bật `MAPS_DAILY_BUDGET_LIMIT` thật trong DB.

---

## 7. Phương án miễn phí (fallback)

| Dịch vụ | Endpoint | Lưu ý |
|---|---|---|
| OSM tile | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | **Chỉ dev**; production phải dùng tile riêng (MapTiler/Stadia) hoặc Goong, vì policy OSM cấm tải nặng |
| Overpass | `POST https://overpass-api.de/api/interpreter` | Query mẫu bên dưới; có rate-limit, đừng gọi mỗi lần kéo map |
| OSRM | `https://router.project-osrm.org/route/v1/driving/{lng},{lat};{lng},{lat}?overview=full&geometries=polyline` | Demo server, không SLA — chỉ dev |
| Valhalla | `https://valhalla1.openstreetmap.de/route` | Như trên |

Query Overpass (tìm quanh 1 điểm):

```overpassql
[out:json][timeout:20];
(
  node["amenity"~"^(restaurant|cafe|fuel|charging_station)$"](around:3000,11.9404,108.4583);
  node["tourism"~"^(attraction|hotel|guest_house)$"](around:3000,11.9404,108.4583);
);
out body 60;
```

> Overpass trả về `tags.name`, `lat/lon`, `opening_hours` (chuỗi OSM) — **không** có rating, giá, ảnh. Vì vậy Nearby dùng Goong/Places là chính; Overpass chỉ để lấp chỗ trống.

---

## 8. Thời tiết & ảnh

- **Open-Meteo** (không cần key): `GET https://api.open-meteo.com/v1/forecast?latitude=..&longitude=..&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code&timezone=Asia%2FBangkok&forecast_days=5`. Miễn phí cho phi thương mại, **đọc điều khoản** nếu app thương mại.
- **Ảnh:** ưu tiên ảnh có license rõ trong DB (`LicenseType`, `CreditAuthor` đã có trong `DestinationImageModel`). Wikimedia Commons qua API cho ảnh địa danh; Unsplash cần tuân thủ attribution. **Không** lấy ảnh Google Places để lưu vĩnh viễn (vi phạm điều khoản).

---

## 9. Script xác minh (chạy trên máy có mạng)

```powershell
# 1) Gemini: model khả dụng + giới hạn token
$key = $env:GEMINI_API_KEY
curl.exe -s "https://generativelanguage.googleapis.com/v1beta/models" `
  -H "x-goog-api-key: $key" |
  ConvertFrom-Json | Select-Object -ExpandProperty models |
  Select-Object name, inputTokenLimit, outputTokenLimit, supportedGenerationMethods |
  Format-Table -AutoSize

# 2) Gemini: thử structured output 1 lần
'{"contents":[{"role":"user","parts":[{"text":"Trả JSON {\"ok\":true}"}]}],
  "generationConfig":{"responseMimeType":"application/json",
  "responseSchema":{"type":"OBJECT","properties":{"ok":{"type":"BOOLEAN"}},
  "required":["ok"]}}}' | Out-File body.json -Encoding utf8
curl.exe -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent" `
  -H "x-goog-api-key: $key" -H "Content-Type: application/json" -d "@body.json"

# 3) Giá & rate limit (đọc tay, ghi lại số)
#    https://ai.google.dev/gemini-api/docs/pricing
#    https://ai.google.dev/gemini-api/docs/rate-limits

# 4) Goong: directions + tile
curl.exe -s "https://rsapi.goong.io/Direction?origin=10.7769,106.7009&destination=11.9404,108.4583&vehicle=car&api_key=$env:GOONG_API_KEY"
curl.exe -s -o tile.png "https://tiles.goong.io/assets/goong_map_web.json?api_key=$env:GOONG_MAPTILES_KEY"

# 5) OSRM (fallback)
curl.exe -s "https://router.project-osrm.org/route/v1/driving/106.7009,10.7769;108.4583,11.9404?overview=full&geometries=polyline"

# 6) Open-Meteo
curl.exe -s "https://api.open-meteo.com/v1/forecast?latitude=11.94&longitude=108.45&daily=temperature_2m_max&forecast_days=3&timezone=Asia%2FBangkok"
```

Kết quả ghi vào `docs/04a-KET-QUA-XAC-MINH.md` (bảng: model, giá vào/ra, RPM, RPD, tile OK?, directions OK?). Sau đó cập nhật `.env.example`.

---

## 10. Tổng hợp lỗi & thông điệp cho người dùng

| Mã | Khi nào | Thông điệp UI |
|---|---|---|
| `MAPS_UNAVAILABLE` | Không key/hết quota | "Chưa tải được bản đồ. Kiểm tra kết nối." |
| `AI_BUSY` | 429 | "Trợ lý đang bận, thử lại sau 1 phút." |
| `AI_BLOCKED` | Safety | "Nội dung bị chặn. Thử diễn đạt khác." |
| `AI_INVALID_PLAN` | Validate thất bại 2 lần | "Không tạo được lộ trình phù hợp. Dùng gợi ý mặc định?" |
| `PLACES_EMPTY` | Không có POI quanh | "Khu vực này chưa có dữ liệu địa điểm." |
| `OFFLINE` | Mất mạng | "Đang offline — hiển thị dữ liệu đã lưu." |
