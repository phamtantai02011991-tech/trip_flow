# 01 — Kiến trúc kỹ thuật

> Đích: một kiến trúc **vertical slice** — mỗi module đi trọn từ DB → API → repository → state → UI — thay cho `AppState` god-object 849 dòng hiện tại.

---

## 1. Cây thư mục đích

### 1.1 Flutter

```
lib/
├── main.dart                      # chỉ bootstrap: init Hive, ProviderScope, TripFlowApp
├── app/
│   ├── app.dart                   # MaterialApp.router + theme
│   ├── router.dart                # go_router: ShellRoute 5 tab + push routes
│   ├── shell.dart                 # Scaffold + FloatingPillNav + IndexedStack
│   └── bootstrap.dart             # đọc env, init cache, warm-up
├── core/
│   ├── config/app_config.dart     # env + hằng số (giữ, bổ sung key mới)
│   ├── network/
│   │   ├── dio_client.dart        # giữ, BỎ fallback mock; chỉ API + cache
│   │   ├── api_result.dart        # Result<T> (ok/data/error) thay vì ném lỗi
│   │   └── interceptors.dart      # auth, retry, log
│   ├── storage/
│   │   ├── offline_cache_service.dart  # giữ
│   │   └── boxes.dart             # tên box tập trung
│   ├── models/                    # data_models.dart tách thành từng file
│   │   ├── province.dart destination.dart local_food.dart restaurant.dart
│   │   ├── trip.dart trip_day.dart trip_stop.dart expense.dart
│   │   ├── place.dart             # POI chung: cafe/hotel/gas/charging/rest_stop
│   │   └── chat.dart              # ChatMessage, ChatSession
│   ├── utils/
│   │   ├── geo_utils.dart         # giữ (bỏ buildRoutePolyline giả)
│   │   ├── money.dart             # VND format/parse
│   │   └── time.dart              # duration, ETA, "09:00"
│   └── errors/app_error.dart
├── ui/
│   ├── tokens/app_colors.dart  app_typography.dart  app_spacing.dart  app_radii.dart  app_shadows.dart
│   ├── components/
│   │   ├── app_card.dart  app_chip.dart  app_badge.dart  app_button.dart
│   │   ├── photo_marker.dart  section_header.dart  rating_pill.dart
│   │   ├── floating_pill_nav.dart  bottom_sheet_shell.dart  skeleton.dart
│   │   └── placeholder_image.dart   # thay ảnh lỗi, không dùng URL demo
│   └── theme/app_theme.dart       # build từ tokens
├── data/
│   ├── api/
│   │   ├── trips_api.dart  places_api.dart  maps_api.dart  ai_api.dart
│   │   ├── search_api.dart expenses_api.dart  auth_api.dart
│   ├── repositories/
│   │   ├── trip_repository.dart      # API + Hive, single source
│   │   ├── place_repository.dart
│   │   ├── ai_repository.dart
│   │   └── expense_repository.dart
│   └── local/
│       ├── trip_local_store.dart  search_history_store.dart  chat_local_store.dart
├── state/                          # Riverpod notifiers theo module
│   ├── trip_provider.dart  planner_provider.dart  nearby_provider.dart
│   ├── assistant_provider.dart  search_provider.dart  expense_provider.dart
│   └── session_provider.dart
└── features/
    ├── onboarding/  home/  discover/  nearby/  search/
    ├── planner/   (wizard, ai_generating, plan_result)
    ├── trip/      (overview, day_timeline, stop_detail, edit_stop)
    ├── expenses/  assistant/  favorites/  profile/  auth/
```

**Quy tắc:** `features/*` không được import trực tiếp `dio` hay Hive — chỉ qua `data/repositories`. `ui/*` không import `features/*`.

### 1.2 Backend

```
backend/app/
├── main.py                    # tạo app, CORS, lifespan, router
├── core/config.py             # pydantic-settings + .env
├── core/security.py           # JWT (python-jose), hash (passlib), dependency current_user
├── db/session.py  db/seed_db.py
├── models/
│   ├── models.py              # catalog + user/RBAC (giữ)
│   ├── trip.py                # Trip, TripDay, TripStop, Expense
│   ├── ai.py                  # AiSession, AiMessage
│   └── place.py               # PlaceCache, SearchHistory
├── schemas/
│   ├── schemas.py  trip.py  ai.py  place.py  expense.py
├── services/
│   ├── geo_service.py         # giữ SFCS
│   ├── itinerary_service.py   # giữ, tách smart-meal
│   ├── trip_service.py        # NEW: CRUD + tính toán ngày/giờ/chi phí
│   ├── ai/gemini_client.py    # NEW: HTTP thuần tới Gemini, không SDK
│   ├── ai/prompt_builder.py   # NEW: dựng prompt grounded từ ứng viên
│   ├── ai/plan_validator.py   # NEW: kiểm tra place_id, bỏ ảo giác
│   ├── places_service.py      # NEW: nearby/autocomplete/detail + cache
│   ├── maps_service.py        # NEW: directions + polyline
│   └── expense_service.py     # NEW: tổng hợp ngân sách
├── api/v1/
│   ├── router.py
│   └── endpoints/
│       ├── trips.py  itinerary_ai.py  assistant.py
│       ├── places.py  maps.py  search.py  expenses.py
│       └── (giữ) provinces destinations local_foods restaurants favorites auth admin
├── integrations/
│   ├── goong_client.py        # bỏ nhánh sinh polyline giả
│   ├── cloudinary_service.py  # bỏ URL demo giả
│   └── gemini_client.py
└── tests/  (mở rộng lên ≥ 35 test)
```

---

## 2. Quản lý state

### 2.1 Hiện tại (vấn đề)

`TripFlowAppState extends ChangeNotifier` (849 dòng) chứa **toàn bộ** app: tab, dữ liệu catalog, 3 loại favorite, lịch trình, báo cáo, auth, loading, cờ offline. 12 file bọc `AnimatedBuilder(animation: appState)`. `app_providers.dart` chỉ là service locator; `AppControllerNotifier` là code chết.

Hệ quả: mọi thay đổi rebuild cả cây, không test được, không cache theo màn.

### 2.2 Đích

```dart
// state/session_provider.dart
final sessionProvider = NotifierProvider<SessionNotifier, Session>(SessionNotifier.new);
class Session { final User? user; final bool isGuest; final bool isOnline; }

// state/trip_provider.dart — dữ liệu chuyến đi đang mở
final tripListProvider  = AsyncNotifierProvider<TripListNotifier, List<Trip>>(TripListNotifier.new);
final activeTripProvider = AsyncNotifierProvider.family<ActiveTripNotifier, Trip, String>(ActiveTripNotifier.new);

// state/nearby_provider.dart — phụ thuộc vị trí + bộ lọc
final nearbyFilterProvider = NotifierProvider<NearbyFilterNotifier, NearbyFilter>(NearbyFilterNotifier.new);
final nearbyResultsProvider = FutureProvider.autoDispose<List<Place>>((ref) async { ... });
```

**Chuyển đổi:** giữ `AppState` chạy song song (P1–P5), mỗi màn chuyển sang provider mới khi được viết lại; xoá `app_state.dart` ở cuối P5.

### 2.3 Quy ước bất đồng bộ

- Dùng `AsyncValue` của Riverpod cho mọi I/O; UI có 3 trạng thái: `Loading` (skeleton), `Error` (retry), `Data`.
- Không `try/catch` rồi trả mock. Lỗi mạng → hiện banner offline + dữ liệu Hive (có nhãn "Dữ liệu lưu offline, cập nhật lúc …").
- Repository trả `Result<T>`:

```dart
sealed class Result<T> { const Result(); }
class Ok<T> extends Result<T> { final T data; const Ok(this.data); }
class Failure<T> extends Result<T> { final AppError error; const Failure(this.error); }
```

---

## 3. Điều hướng

Thay `Navigator.push` rải rác bằng **go_router** (deep link cho tính năng chia sẻ lịch trình — Module 6).

```dart
// app/router.dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/',        builder: (_,__) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/nearby',  builder: (_,__) => const NearbyScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/trips',   builder: (_,__) => const TripListScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/assistant', builder: (_,__) => const AssistantScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_,__) => const ProfileScreen())]),
      ],
    ),
    GoRoute(path: '/plan/new',  builder: (_,__) => const PlannerWizardScreen()),
    GoRoute(path: '/trips/:tripId', builder: (_, s) => TripOverviewScreen(tripId: s.pathParameters['tripId']!),
      routes: [
        GoRoute(path: 'day/:day', builder: (_, s) => DayTimelineScreen(...)),
        GoRoute(path: 'stop/:stopId', builder: (_, s) => StopDetailScreen(...)),
        GoRoute(path: 'expenses', builder: (_, s) => ExpensesScreen(...)),
      ]),
    GoRoute(path: '/share/:token', builder: (_, s) => SharedTripScreen(token: s.pathParameters['token']!)),
  ],
);
```

| Route | Màn | Ghi chú |
|---|---|---|
| `/` | Home | tab 1 |
| `/nearby` | Nearby | tab 2 — bản đồ tối + danh sách (ảnh 4, 9) |
| `/trips` | Danh sách chuyến | tab 3 |
| `/assistant` | Chat AI | tab 4 (ảnh 8) |
| `/profile` | Cá nhân, favorites, chi phí tổng | tab 5 |
| `/plan/new` | Wizard 3 bước (ảnh 5) | |
| `/trips/:id` | Tổng quan lộ trình (ảnh 2, 7) | |
| `/share/:token` | Xem lịch trình được chia sẻ (public) | |

---

## 4. Schema DB (bổ sung)

Giữ 18 bảng cũ. Thêm 5 nhóm bảng mới. Tất cả dùng `SQLModel`, `created_at/updated_at`, và **Alembic** (xem §7).

```python
# models/trip.py
class TripStatus(str, Enum):
    draft = "draft"; planned = "planned"; active = "active"
    completed = "completed"; archived = "archived"

class VehicleType(str, Enum):
    motorbike = "motorbike"; car = "car"; coach = "coach"

class BudgetLevel(str, Enum):
    saver = "saver"; balanced = "balanced"; comfort = "comfort"

class Trip(SQLModel, table=True):
    __tablename__ = "trips"
    id: int | None = Field(default=None, primary_key=True)
    user_id: int | None = Field(default=None, foreign_key="users.id", index=True)
    title: str
    province_id: int | None = Field(default=None, foreign_key="provinces.id")
    origin_name: str
    origin_lat: float; origin_lng: float
    destination_name: str
    destination_lat: float; destination_lng: float
    start_date: date | None
    total_days: int = 1
    party_size: int = 2
    vehicle: VehicleType = VehicleType.motorbike
    budget_level: BudgetLevel = BudgetLevel.balanced
    budget_amount: int | None            # VND, người dùng nhập
    preferences_json: str = "[]"         # ["nature","food","beach","mountain","culture"]
    status: TripStatus = TripStatus.draft
    share_token: str | None = Field(default=None, unique=True, index=True)
    ai_generated: bool = False
    generation_meta_json: str = "{}"     # model, prompt_version, tokens, duration_ms
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class TripDay(SQLModel, table=True):
    __tablename__ = "trip_days"
    id: int | None = Field(default=None, primary_key=True)
    trip_id: int = Field(foreign_key="trips.id", index=True)
    day_number: int
    date: date | None
    title: str | None                    # "Ngày 1 · Hà Nội → Ninh Bình"
    note: str | None

class TripStop(SQLModel, table=True):
    __tablename__ = "trip_stops"
    id: int | None = Field(default=None, primary_key=True)
    trip_day_id: int = Field(foreign_key="trip_days.id", index=True)
    stop_order: int
    kind: str                            # destination | restaurant | cafe | hotel | gas | ev | rest | custom
    place_id: str | None                 # ID từ Places/Goong — BẮT BUỘC cho kind != custom
    ref_table: str | None                # "destinations" | "restaurants" | None
    ref_id: int | None
    name: str; address: str
    lat: float; lng: float
    arrive_at: datetime | None
    stay_mins: int = 60
    travel_mins_from_prev: int | None
    distance_km_from_prev: float | None
    est_cost: int | None
    note: str | None
    source: str = "manual"               # manual | ai | nearby | template
```

```python
# models/place.py
class PlaceCache(SQLModel, table=True):
    __tablename__ = "place_cache"
    id: int | None = Field(default=None, primary_key=True)
    provider: str                        # goong | google | osm
    place_id: str = Field(index=True)
    payload_json: str                    # raw response
    fetched_at: datetime
    expires_at: datetime                 # TTL 24h
    __table_args__ = (UniqueConstraint("provider", "place_id", name="uq_place_provider"),)

class SearchHistory(SQLModel, table=True):
    __tablename__ = "search_history"
    id: int | None = Field(default=None, primary_key=True)
    user_id: int | None = Field(default=None, foreign_key="users.id", index=True)
    query: str
    kind: str                            # text | category | place
    place_id: str | None
    lat: float | None; lng: float | None
    created_at: datetime
```

```python
# models/trip.py (tiếp) — chi phí
class ExpenseCategory(str, Enum):
    fuel = "fuel"; food = "food"; hotel = "hotel"; ticket = "ticket"; other = "other"

class Expense(SQLModel, table=True):
    __tablename__ = "expenses"
    id: int | None = Field(default=None, primary_key=True)
    trip_id: int = Field(foreign_key="trips.id", index=True)
    trip_day_id: int | None = Field(default=None, foreign_key="trip_days.id")
    category: ExpenseCategory
    title: str
    amount: int                          # VND, số nguyên
    planned: bool = False                # dự kiến hay thực tế
    spent_at: datetime | None
    paid_by: str | None
    note: str | None
    created_at: datetime
```

```python
# models/ai.py
class AiSession(SQLModel, table=True):
    __tablename__ = "ai_sessions"
    id: int | None = Field(default=None, primary_key=True)
    user_id: int | None = Field(default=None, foreign_key="users.id", index=True)
    trip_id: int | None = Field(default=None, foreign_key="trips.id")
    title: str = "Cuộc trò chuyện mới"
    model: str
    created_at: datetime; updated_at: datetime

class AiMessage(SQLModel, table=True):
    __tablename__ = "ai_messages"
    id: int | None = Field(default=None, primary_key=True)
    session_id: int = Field(foreign_key="ai_sessions.id", index=True)
    role: str                            # user | assistant | tool
    content: str
    tool_calls_json: str | None
    tokens_in: int = 0; tokens_out: int = 0
    created_at: datetime
```

### Quan hệ

```
User 1─n Trip 1─n TripDay 1─n TripStop
Trip 1─n Expense (0..1 TripDay)
User 1─n AiSession 1─n AiMessage
Trip 1─1 share_token (public read-only)
Favorite (đa hình) giữ nguyên
```

### Vì sao thêm `Trip` thay vì mở rộng `Itinerary`?

`Itinerary` hiện là "lịch trình mẫu" hoặc "lịch trình đã lưu" với 8 trường; thiếu ngày đi, số người, phương tiện, ngân sách, trạng thái, share. Mở rộng `Itinerary` sẽ phá 8 endpoint + 11 bản ghi seed + admin. Tạo `Trip` mới, giữ `Itinerary` làm **template** (dùng lại khi "Dùng mẫu này" → copy sang Trip), và viết migration chuyển `user_itineraries` cũ sang `trips` một lần.

---

## 5. Bề mặt API mới

| Method | Path | Chức năng | Auth |
|---|---|---|---|
| POST | `/trips` | Tạo chuyến (body: origin/dest/dates/party/vehicle/budget/prefs) | 👤 |
| GET | `/trips?status=` | Danh sách chuyến của tôi | 👤 |
| GET | `/trips/{id}` | Chi tiết + days + stops + tổng chi phí | 👤 (owner) |
| PUT | `/trips/{id}` | Sửa thông tin chuyến | 👤 (owner) |
| DELETE | `/trips/{id}` | Xoá | 👤 (owner) |
| PATCH | `/trips/{id}/status` | `draft→planned→active→completed` | 👤 (owner) |
| POST | `/trips/{id}/duplicate` | Nhân bản | 👤 (owner) |
| POST | `/trips/{id}/share` | Tạo `share_token`, trả URL | 👤 (owner) |
| GET | `/share/{token}` | Xem công khai (read-only) | 🔓 |
| POST | `/trips/{id}/generate` | **AI tạo lộ trình** (grounded) | 👤 + rate 5/ngày |
| POST | `/trips/{id}/regenerate` | Tạo lại với ghi chú điều chỉnh | 👤 |
| POST | `/trips/{id}/optimize` | Tối ưu thứ tự điểm dừng (TSP heuristic) | 👤 |
| POST | `/trips/{id}/days/{day}/stops` | Thêm điểm dừng | 👤 (owner) |
| PUT | `/trips/{id}/stops/{stopId}` | Sửa | 👤 (owner) |
| DELETE | `/trips/{id}/stops/{stopId}` | Xoá | 👤 (owner) |
| PUT | `/trips/{id}/days/{day}/reorder` | Kéo thả (mảng id) | 👤 (owner) |
| GET | `/trips/{id}/expenses` | Danh sách chi phí | 👤 (owner) |
| POST | `/trips/{id}/expenses` | Thêm chi phí | 👤 (owner) |
| PUT | `/trips/{id}/expenses/{eid}` | Sửa | 👤 (owner) |
| DELETE | `/trips/{id}/expenses/{eid}` | Xoá | 👤 (owner) |
| GET | `/trips/{id}/budget-summary` | Tổng/người, theo loại, dự kiến vs thực tế | 👤 (owner) |
| GET | `/places/nearby` | `lat,lng,radius_km,kinds[]` → POI | 🔓 + cache |
| GET | `/places/{place_id}` | Chi tiết POI (giờ mở cửa, ảnh, SĐT) | 🔓 + cache |
| GET | `/places/autocomplete?q=&lat=&lng=` | Gợi ý địa chỉ | 🔓 |
| GET | `/maps/directions` | `origin,dest,waypoints,vehicle` → polyline + legs | 🔓 + cache |
| POST | `/assistant/chat` | Chat SSE, tool-calling | 👤 + rate 20/phút |
| GET | `/assistant/sessions` · `/assistant/sessions/{id}` | Lịch sử | 👤 |
| POST | `/search/history` · `GET` · `DELETE /{id}` | Lịch sử tìm kiếm | 👤? |
| GET | `/search/suggest?q=` | Gộp destination + food + restaurant + place | 🔓 |

**Quy ước chung:** mọi endpoint owner-scoped phải dùng dependency `get_owned_trip(trip_id, user)` — trả 404 (không phải 403) khi không phải chủ, để không lộ sự tồn tại.

---

## 6. Luồng dữ liệu then chốt

### 6.1 Tạo lộ trình bằng AI (grounded) — Module 2

```
Flutter                         FastAPI                              Gemini
  │ POST /trips/{id}/generate      │                                    │
  ├──────────────────────────────▶ │ 1. đọc trip (ngày, ngân sách…)     │
  │                                │ 2. gọi Directions (Goong) → route  │
  │                                │ 3. corridor-search → quán dọc tuyến│
  │                                │ 4. nearby POI theo sở thích        │
  │                                │ 5. dựng candidate list C (≤ 80)    │
  │                                │    mỗi item: place_id, name, lat,  │
  │                                │    lng, rating, hours, price, dist │
  │                                │ 6. prompt: chọn & xếp lịch từ C    │
  │                                ├─────────── generateContent ───────▶│
  │                                │◀────────── JSON (place_id + day) ──│
  │                                │ 7. VALIDATE: mọi place_id ∈ C      │
  │                                │    sai → loại, log, thử lại 1 lần  │
  │                                │ 8. tính travel_mins từ Directions  │
  │                                │ 9. tính est_cost từ bảng giá nội bộ│
  │                                │10. lưu TripDay/TripStop           │
  │◀──── Trip đầy đủ + reasoning ──│                                    │
```

Bước 7 là **hàng rào chống bịa**. Không có bước này thì AI có thể trả về địa điểm không tồn tại.

### 6.2 Tìm địa điểm gần đây — Module 5

```
GPS → NearbyFilter → GET /places/nearby (cache 24h) → PlaceRepository
    → NearbyScreen: bản đồ tối + marker + danh sách + chip lọc
    → chạm marker → bottom sheet chi tiết (ảnh 9): Gọi · Chỉ đường · Thêm vào chuyến
```

### 6.3 Trợ lý AI — Module 4

```
Chat message → POST /assistant/chat (SSE)
  → Gemini với tools: add_stop, remove_stop, move_stop, set_budget, search_places
  → tool_call → backend thực thi trên DB (kiểm tra owner) → functionResponse
  → stream text về Flutter (data: {"delta": "..."})
  → UI: bong bóng chat + card hành động ("Đã thêm Quán bún chả vào Ngày 2")
```

---

## 7. Migration & vận hành

1. `alembic init backend/alembic`, cấu hình `sqlalchemy.url` từ `DATABASE_URL`.
2. Baseline: `alembic revision --autogenerate -m "baseline existing 18 tables"` — chạy trên DB đang có dữ liệu, đánh dấu `alembic stamp head` để không tạo lại bảng.
3. Migration mới: `trips`, `trip_days`, `trip_stops`, `expenses`, `ai_sessions`, `ai_messages`, `place_cache`, `search_history`.
4. Bỏ `_ensure_ingestion_columns()` và `create_all()` khỏi startup (chỉ dùng trong test).
5. `requirements.txt`: bỏ `python-jose`, `passlib`, `pydantic-settings` **hoặc** dùng thật; thêm `psycopg2-binary` (cần cho Postgres local).

### Bảo mật phải sửa (P6, nhưng chặn merge từ P3)

| # | Lỗi | Sửa |
|---|---|---|
| 1 | `DELETE /itineraries/{id}` không auth | Thêm `Depends(get_current_user)` + kiểm tra owner |
| 2 | `GET /itineraries` không token trả toàn bộ | Trả 401 hoặc chỉ trả public templates |
| 3 | IDOR `GET/PUT/POST /itineraries/{id}/*` | Dependency `get_owned_trip` |
| 4 | OTP `888999` / "mọi mã 6 số" | Chỉ chấp nhận OTP trong DB, hết hạn 5 phút; dev dùng `DEV_OTP` qua env, log rõ |
| 5 | `SECRET_KEY` mặc định | Bắt buộc env ở production (`raise` nếu thiếu) |
| 6 | CORS `*` + `allow_credentials` | Danh sách origin cụ thể |
| 7 | Auto-login Super Admin ở admin-web | Xoá; yêu cầu đăng nhập thật |
| 8 | Mật khẩu demo hardcode | Chỉ seed khi `SEED_DEMO=1`, in ra cảnh báo |

---

## 8. Hiệu năng

| Vấn đề hiện tại | Cách xử lý |
|---|---|
| `fetch*` fallback mock che lỗi mạng | Bỏ mock; dùng Hive + banner offline |
| 10 request song song khi mở admin | Phân trang + `?fields=` |
| Places/Directions gọi mỗi lần | `place_cache` TTL 24h + in-memory LRU |
| Ảnh gốc tải full | Cloudinary `w_400/-w_1200` như hiện tại, thêm `cacheWidth` khi decode |
| `AppState` rebuild toàn app | Riverpod provider theo màn (P1) |
