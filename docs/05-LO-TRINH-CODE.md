# 05 — Lộ trình code chi tiết (từng file, từng bước)

> Cách dùng: làm **đúng thứ tự** P1 → P6. Mỗi task có: file đụng tới · việc phải làm · code mẫu · lệnh kiểm chứng · điều kiện xong (DoD). Không nhảy phase: mỗi phase kết thúc phải `flutter analyze` + `pytest` xanh.
>
> Quy ước: `NEW` = tạo mới · `EDIT` = sửa · `DEL` = xoá.

---

## P0 — Dọn dẹp ✅ (đã xong trong phiên này)

Xem [`06-DON-DEP.md`](06-DON-DEP.md). Kết quả: **428,53 MB → 4,18 MB**.

Việc còn lại của P0 (làm cùng P1):

| # | File | Việc |
|---|---|---|
| P0-1 | `lib/core/network/dio_client.dart` L335/343/383 | **Xoá** nhánh OTP `888999` / "mọi mã 6 số". Chỉ chấp nhận OTP backend trả về (hoặc `--dart-define=DEV_OTP=123456` khi debug) |
| P0-2 | `lib/features/home/widgets/hero_trip_carousel.dart` L56–105 | **Xoá** `_trips` hardcode; nhận `List<TripPreview>` từ provider |
| P0-3 | `lib/core/utils/smart_itinerary_engine.dart` L644/677/682 | Xoá chi phí cứng + thời tiết hardcode; chuyển sang `CostRules` (backend) và weather API |
| P0-4 | `lib/core/widgets/itinerary_timeline_card.dart` | **DEL** (dead code, 0 import) |
| P0-5 | `lib/core/providers/app_providers.dart` L28–42 | **DEL** `AppControllerNotifier`/`appControllerProvider` (0 dùng) |
| P0-6 | `lib/features/itinerary/screens/trip_planner_wizard_screen.dart` L27–33 | Bỏ tick sẵn 5 sở thích |
| P0-7 | `lib/features/auth/register_screen.dart` L24 | `_agreedToTerms = false` |
| P0-8 | `lib/features/profile/profile_screen.dart` L300/321 | Bỏ 2 công tắc dev giả |
| P0-9 | `pubspec.yaml` | Bỏ `cupertino_icons` nếu không dùng (0 import) |

Kiểm chứng:
```bash
grep -rn "888999" lib/                 # phải rỗng
grep -rn "itinerary_timeline_card" lib/ # phải rỗng
flutter analyze
```

---

## P1 — Design system + khung ứng dụng (2 ngày)

### P1.1 Thêm dependency (version đã xác minh trên pub.dev ngày 31/10/2026)

```bash
cd D:\trip_flow
flutter pub add go_router:^18.1.2 geolocator:^14.1.2 url_launcher:^6.3.3 intl:^0.20.3
flutter pub add flutter_map:^8.3.2 latlong2:^0.10.1     # nâng từ ^6.1.0 / ^0.9.1
```

| Package | Version chốt | Ghi chú |
|---|---|---|
| `flutter_map` | 8.3.2 (27/08/2026) | **API v7+ khác v6**: `MapOptions(initialCenter:, initialZoom:)`, `TileLayer`, `MarkerLayer`, `RichAttributionWidget` |
| `latlong2` | 0.10.1 | |
| `go_router` | 18.1.2 | |
| `geolocator` | 14.1.2 | |
| `url_launcher` | 6.3.3 | |
| `intl` | 0.20.3 | |

> **Không** thêm `google_generative_ai`: bản mới nhất là 0.4.7 phát hành **17/04/2025** (18 tháng không cập nhật). Flutter chỉ gọi backend — cũng là cách duy nhất giữ key Gemini ở server.
> Bỏ `cupertino_icons` (0 import). `shared_preferences` cũng 0 import — bỏ nếu không dùng.

### P1.2 `NEW lib/ui/tokens/app_colors.dart`
Dán nguyên nội dung §2.1 của [`02-DESIGN-SYSTEM.md`](02-DESIGN-SYSTEM.md).

### P1.3 `NEW lib/ui/tokens/app_typography.dart`, `app_spacing.dart`, `app_radii.dart`, `app_shadows.dart`
Dán §2.2–2.3. Thêm `assets/fonts/` + khai báo `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
        - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf
          weight: 800
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```
Tải font từ Google Fonts (OFL) → `assets/fonts/`. **Không** dùng `google_fonts` package (cần mạng lúc chạy).

### P1.4 `EDIT lib/core/theme/app_theme.dart` — dựng từ token

```dart
import 'package:flutter/material.dart';
import '../../ui/tokens/app_colors.dart';
import '../../ui/tokens/app_radii.dart';
import '../../ui/tokens/app_typography.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      primary: AppColors.coral,
      secondary: AppColors.terracotta,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ).copyWith(onSurface: AppColors.textPrimary, outlineVariant: AppColors.line);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displaySmall: AppTypography.display,
        headlineMedium: AppTypography.h1,
        titleLarge: AppTypography.h2,
        titleMedium: AppTypography.h3,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.bodySm,
        labelLarge: AppTypography.button,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt, side: BorderSide.none,
        shape: const StadiumBorder(), labelStyle: AppTypography.label,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        elevation: 0, centerTitle: false,
        titleTextStyle: AppTypography.h3, foregroundColor: AppColors.textPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: AppColors.coral, foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        textStyle: AppTypography.button)),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)))),
    );
  }
}
```

**DoD:** `flutter run -d chrome` vẫn mở được app cũ, màu đã đổi sang token mới.

### P1.5 `NEW lib/ui/components/` — 10 component theo bảng §3 của doc 02

Thứ tự làm: `app_card` → `app_chip` → `rating_pill` → `info_pill` → `section_header` → `image_card` → `photo_marker` → `day_pill` → `floating_pill_nav` → `bottom_sheet_shell` → `skeleton_card` → `placeholder_image` → `empty_state`.

Ví dụ `floating_pill_nav.dart`:

```dart
class FloatingPillNav extends StatelessWidget {
  const FloatingPillNav({super.key, required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Trang chủ'),
    (Icons.near_me_rounded, 'Gần đây'),
    (Icons.route_rounded, 'Chuyến đi'),
    (Icons.auto_awesome_rounded, 'Trợ lý'),
    (Icons.person_rounded, 'Tôi'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppShadow.floating,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    _NavItem(
                      icon: _items[i].$1,
                      label: _items[i].$2,
                      active: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

`_NavItem` dùng `AnimatedContainer(220ms)`; active: nền `AppColors.coral`, `Row(icon, SizedBox(6), Text(label))`, padding ngang 16.

### P1.6 `NEW lib/app/router.dart` + `lib/app/shell.dart`
Dán cấu trúc §3 của [`01-KIEN-TRUC.md`](01-KIEN-TRUC.md). Ban đầu các route trỏ về màn cũ để app vẫn chạy; thay dần ở P2–P6.

### P1.7 `EDIT lib/main.dart` — gọn lại

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineCacheService.instance.init();
  runApp(const ProviderScope(child: TripFlowApp()));
}

class TripFlowApp extends ConsumerWidget {
  const TripFlowApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: ref.watch(routerProvider),
        builder: (context, child) => kIsWeb && kDebugMode
            ? PhoneFrameDemo(child: child!)   // tách file dev/phone_frame.dart
            : child!,
      );
}
```

**DEL** `ResponsivePhoneFrameWrapper` khỏi `main.dart`, chuyển sang `lib/dev/phone_frame.dart`, chỉ bật ở web debug (bản demo).

### P1.8 `NEW lib/state/session_provider.dart`, `lib/state/settings_provider.dart`
Chuyển cờ `isOnline`, `user`, `isGuest` khỏi `AppState`.

### P1.9 `.gitignore` + `pubspec.yaml`
Đã thêm `devtools_options.yaml`, `.vscode/`, `coverage/`. Rà lại mỗi dependency đều có import thật.

**DoD P1:**
```bash
flutter analyze          # 0 issue
flutter run -d chrome    # 5 tab hiển thị với pill nav mới
grep -rn "Color(0xFF" lib/ --include=*.dart | grep -v "ui/tokens"   # còn < 10 dòng (màn cũ chưa chuyển)
```

---

## P2 — Bản đồ thật (2 ngày)

### P2.1 Backend: endpoint directions

`NEW backend/app/services/maps_service.py`

```python
async def get_directions(origin: LatLng, dest: LatLng, vehicle: str = "car",
                         waypoints: list[LatLng] | None = None) -> RouteResult:
    if settings.MAPS_PROVIDER == "goong" and settings.GOONG_API_KEY:
        return await _goong_directions(origin, dest, vehicle, waypoints)
    if settings.MAPS_PROVIDER == "osm":
        return await _osrm_directions(origin, dest, waypoints)
    raise MapsUnavailable("Chưa cấu hình nhà cung cấp bản đồ")
```

`NEW backend/app/api/v1/endpoints/maps.py`

```python
router = APIRouter(prefix="/maps", tags=["maps"])

@router.get("/directions")
async def directions(
    origin_lat: float, origin_lng: float,
    dest_lat: float, dest_lng: float,
    vehicle: str = "car",
    waypoints: str | None = None,           # "lat,lng;lat,lng"
    _: None = Depends(enforce_maps_rate_limit),
):
    return await maps_service.get_directions(...)
```

Đăng ký trong `router.py`. Test mới `backend/tests/test_maps.py`:

```python
def test_directions_requires_key(client, monkeypatch):
    monkeypatch.setattr(settings, "GOONG_API_KEY", "")
    r = client.get("/api/v1/maps/directions", params={...})
    assert r.status_code == 503
    assert r.json()["detail"]["code"] == "MAPS_UNAVAILABLE"
```

### P2.2 `EDIT backend/app/integrations/goong_client.py`
Xoá `_generate_smart_urban_polyline` và mọi nhánh trả dữ liệu giả. Ánh xạ response thật:

```python
data = resp.json()
route = (data.get("routes") or [None])[0]
if not route:
    raise MapsUnavailable("Goong không trả tuyến đường")
return RouteResult(
    encoded_polyline=route["overview_polyline"]["points"],
    distance_km=route["legs"].sum(l["distance"]["value"] for l in route["legs"]) / 1000,
    duration_mins=round(route["legs"].sum(l["duration"]["value"] for l in route["legs"]) / 60),
    legs=[...],
    provider="goong",
)
```

### P2.3 Flutter: widget bản đồ dùng chung

Trước tiên `EDIT lib/core/config/app_config.dart` — thêm hằng số còn thiếu:

```dart
static const String goongTileKey = String.fromEnvironment('GOONG_MAPTILES_KEY');
static String get goongMapTileUrlTemplate =>
    'https://tiles.goong.io/assets/goong_map_web.json?api_key=$goongTileKey';
static String get goongDarkTileUrl =>
    'https://tiles.goong.io/assets/goong_map_highlight.json?api_key=$goongTileKey';  // đổi style khi có style tối
static const String fallbackOsmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
```

> Đã xác minh (31/10/2026): Goong có 3 style `goong_map_web`, `goong_map_highlight`, `goong_satellite`. Chưa có style tối chính thức — nếu ảnh 4 cần bản đồ tối, dùng `ColorFiltered` (ma trận đảo màu) trên tile sáng **chỉ khi** không có style tối, hoặc dùng Carto dark tile miễn phí cho riêng màn Nearby.

`NEW lib/features/map/map_view.dart`

```dart
class TripFlowMap extends StatelessWidget {
  const TripFlowMap({
    super.key, required this.center, this.zoom = 13,
    this.dark = false, this.polylines = const [], this.markers = const [],
    this.onCameraMoveEnd, this.controller,
  });

  @override
  Widget build(BuildContext context) => FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center, initialZoom: zoom,
          onPositionChanged: (camera, hasGesture) { if (hasGesture) onCameraMoveEnd?.call(camera); },
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: dark
                ? AppConfig.goongDarkTileUrl
                : AppConfig.goongMapTileUrlTemplate,
            userAgentPackageName: 'com.example.trip_flow',
            fallbackUrl: AppConfig.fallbackOsmTileUrlTemplate,   // khi Goong lỗi
          ),
          if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
          MarkerLayer(markers: markers),
          RichAttributionWidget(attributions: [
            TextSourceAttribution('Goong Maps'), TextSourceAttribution('OpenStreetMap'),
          ]),
        ],
      );
}
```

`NEW lib/features/map/photo_marker.dart` — marker ảnh tròn 48px + viền trắng 3px + đuôi `CustomPaint` tam giác 8px, `AnimatedScale` khi `selected`.

### P2.4 GPS

```bash
flutter pub add geolocator
```

`NEW lib/data/location/location_service.dart`

```dart
class LocationService {
  Future<LatLng?> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
    );
    return LatLng(pos.latitude, pos.longitude);
  }
}
```
Cần quyền: `android/app/src/main/AndroidManifest.xml` (`ACCESS_FINE_LOCATION`), `ios/Runner/Info.plist` (`NSLocationWhenInUseUsageDescription`), `web` (trình duyệt hỏi).

### P2.5 Xoá bản đồ giả

- `DEL` `_MapPainter` trong `map_corridor_screen.dart` (L627) và `smart_itinerary_result_screen.dart` (L600/640).
- Thay bằng `TripFlowMap` + polyline từ `POST /restaurants/corridor-search` (`polyline` đã có trong response).

**DoD P2:**
```bash
flutter analyze
# Mở app trên Chrome: bản đồ hiện tile thật, cuộn/zoom được, marker hiện, polyline vẽ từ dữ liệu API
pytest backend/tests/test_maps.py -q
grep -rn "class _MapPainter\|class .*RoutePainter" lib/   # rỗng
```

---

## P3 — Module 1 + 3 + 6: Trip CRUD, bản đồ lộ trình, quản lý (4 ngày)

### P3.1 Backend models + migration

1. `NEW backend/app/models/trip.py` — dán schema §4 của [`01-KIEN-TRUC.md`](01-KIEN-TRUC.md).
2. `NEW backend/app/models/place.py`, `backend/app/models/ai.py`.
3. `EDIT backend/app/models/__init__.py` — export.
4. `NEW backend/alembic/`:

```bash
cd backend
alembic init alembic
# sửa alembic/env.py: from app.models import models, trip, place, ai ; target_metadata = SQLModel.metadata
alembic revision --autogenerate -m "add trips expenses ai place cache"
alembic upgrade head
```

### P3.2 Schemas

`NEW backend/app/schemas/trip.py`

```python
class TripCreate(SQLModel):
    title: str = Field(min_length=3, max_length=120)
    origin_name: str; origin_lat: float; origin_lng: float
    destination_name: str | None = None
    destination_lat: float | None = None; destination_lng: float | None = None
    start_date: date | None = None
    total_days: int = Field(default=1, ge=1, le=14)
    party_size: int = Field(default=2, ge=1, le=20)
    vehicle: VehicleType = VehicleType.motorbike
    budget_level: BudgetLevel = BudgetLevel.balanced
    budget_amount: int | None = Field(default=None, ge=0)
    preferences: list[str] = []

class TripOut(SQLModel):
    id: int; title: str; status: TripStatus
    origin: PlacePoint; destination: PlacePoint | None
    start_date: date | None; total_days: int
    days: list[TripDayOut]
    totals: TripTotals          # km, minutes, est_cost, spent
```

### P3.3 Service + router

`NEW backend/app/services/trip_service.py` — các hàm: `create_trip`, `list_trips(user)`, `get_trip_owned(trip_id, user)`, `update_trip`, `delete_trip`, `set_status`, `duplicate`, `share`, `reorder`, `recalc_legs` (gọi Directions cho từng chặng, lưu `travel_mins`/`distance_km`).

`NEW backend/app/api/v1/endpoints/trips.py` — 16 endpoint theo §5 doc 01. Dependency bảo mật:

```python
def get_owned_trip(trip_id: int, user: User = Depends(get_current_user),
                   db: Session = Depends(get_db)) -> Trip:
    trip = db.get(Trip, trip_id)
    if not trip or (trip.user_id not in (None, user.id) and not user.is_superuser):
        raise HTTPException(404, "Không tìm thấy chuyến đi")
    return trip
```

`NEW backend/tests/test_trips.py` — ≥ 10 test: tạo, list chỉ của mình, IDOR (user B không đọc được), reorder, duplicate, share token đọc công khai, xoá, validate ngày.

### P3.4 Flutter data layer

`NEW lib/core/models/trip.dart`

```dart
enum TripStatus { draft, planned, active, completed, archived }
enum VehicleType { motorbike, car, coach }

class Trip {
  final String id; final String title; final TripStatus status;
  final PlacePoint origin; final PlacePoint? destination;
  final DateTime? startDate; final int totalDays; final int partySize;
  final VehicleType vehicle; final List<TripDay> days; final TripTotals totals;
  ...
}

class TripStop {
  final String id; final int order; final String kind;
  final String? placeId; final String name; final String address;
  final double lat, lng; final DateTime? arriveAt;
  final int stayMins; final int? travelMinsFromPrev; final double? distanceKmFromPrev;
  final int? estCost; final String source;
}
```

`NEW lib/data/api/trips_api.dart` — 1 method/endpoint, dùng `Dio` đã có.
`NEW lib/data/repositories/trip_repository.dart` — API trước, lỗi → Hive, trả `Result<Trip>`.
`NEW lib/state/trip_provider.dart` — `TripListNotifier`, `ActiveTripNotifier`.

### P3.5 Màn hình

| File | Nội dung |
|---|---|
| `NEW lib/features/trip/trip_overview_screen.dart` | ảnh 2/7 — map 55% + `DraggableScrollableSheet` + DayPill + StopCard |
| `NEW lib/features/trip/day_timeline_screen.dart` | timeline dọc + `ReorderableListView` thật |
| `NEW lib/features/trip/stop_detail_screen.dart` | ảnh 3 (nâng cấp `stop_detail_sheet.dart` cũ) |
| `NEW lib/features/trip/trip_list_screen.dart` | danh sách chuyến (tab 3), 3 trạng thái rỗng/đang tải/có dữ liệu |
| `NEW lib/features/planner/planner_wizard_screen.dart` | ảnh 5, 3 bước, validate thật |
| `EDIT lib/features/home/home_screen.dart` | dựng lại theo ảnh 1, dùng provider |

**DoD P3:**
```bash
flutter analyze && pytest backend/tests -q
# Kịch bản tay: tạo chuyến → thêm 3 điểm dừng → kéo đổi thứ tự → tải lại app → dữ liệu còn
# Kiểm IDOR: đăng nhập user B, gọi GET /trips/{id_của_A} → 404
```

---

## P4 — Module 2: AI tạo lộ trình grounded (3 ngày)

### P4.1 `NEW backend/app/services/ai/prompt_builder.py`

```python
def build_candidates(trip: Trip, route: RouteResult, db: Session, limit: int = 80) -> list[dict]:
    """Gom ứng viên THẬT: destination trong tỉnh, quán dọc tuyến, POI nearby."""
    out = []
    for d in destinations_near_route(db, route, max_km=3.0)[:30]:
        out.append({"id": f"d_{d.id}", "name": d.name, "kind": "sight",
                    "lat": d.latitude, "lng": d.longitude, "rating": d.rating,
                    "hours": d.opening_hours, "price": d.ticket_price_info})
    for r in restaurants_on_corridor(route, db, radius_km=2.0, limit=25):
        out.append({"id": f"r_{r.id}", "name": r.name, "kind": "food", ...})
    for p in nearby_places(trip.destination_lat, trip.destination_lng, prefs=trip.preferences)[:25]:
        out.append({"id": f"p_{p.place_id}", ...})
    return out[:limit]

def build_plan_prompt(trip: Trip, candidates: list[dict], route: RouteResult) -> str:
    return PLAN_TEMPLATE.format(
        origin=trip.origin_name, destination=trip.destination_name,
        days=trip.total_days, party=trip.party_size, vehicle=trip.vehicle.value,
        budget=trip.budget_amount or trip.budget_level.value,
        prefs=", ".join(json.loads(trip.preferences_json)),
        start_time="07:00",
        avg_speed=avg_speed_for(trip.vehicle),
        distance_km=route.distance_km, duration_mins=route.duration_mins,
        candidates=json.dumps(candidates, ensure_ascii=False),
    )
```

### P4.2 `NEW backend/app/services/ai/plan_validator.py`

```python
def validate_plan(plan: dict, candidates: list[dict]) -> tuple[dict, list[str]]:
    allowed = {c["id"]: c for c in candidates}
    problems, kept_days = [], []
    for day in plan.get("days", []):
        stops = []
        for s in day.get("stops", []):
            pid = s.get("place_id")
            if pid not in allowed:
                problems.append(f"hallucinated place_id: {pid}")
                continue                      # LOẠI BỎ, không tin
            stops.append({**s, "_cand": allowed[pid]})
        if stops:
            kept_days.append({**day, "stops": stops})
    if not kept_days:
        raise InvalidPlan("Không còn điểm dừng hợp lệ")
    return {"days": kept_days, "summary": plan.get("summary", ""),
            "tips": plan.get("tips", [])}, problems
```

### P4.3 `NEW backend/app/api/v1/endpoints/itinerary_ai.py`

```python
@router.post("/trips/{trip_id}/generate", response_model=TripOut)
async def generate(trip: Trip = Depends(get_owned_trip), db: Session = Depends(get_db),
                   user: User = Depends(get_current_user), _=Depends(ai_daily_limit)):
    return await ai_plan_service.generate_for_trip(db, trip)   # 5 bước §3.2 doc 04
```

`ai_plan_service.generate_for_trip` phải: tính route → candidates → gọi Gemini → validate → **retry 1 lần** → tính travel/cost/arrive → lưu `TripDay`/`TripStop` → lưu `generation_meta_json` (model, tokens, thời gian, số hallucination bị loại).

### P4.4 Flutter

`NEW lib/data/api/ai_api.dart`, `NEW lib/data/repositories/ai_repository.dart`
`NEW lib/features/planner/ai_generating_screen.dart` — hiện 4 bước thật (poll `GET /trips/{id}/generation-status` hoặc SSE).
`EDIT lib/features/planner/plan_result_screen.dart` (từ `smart_itinerary_result_screen.dart`) — bỏ toàn bộ `CustomPaint`, dùng `TripFlowMap` + timeline.

**DoD P4:**
```bash
pytest backend/tests/test_ai_plan.py -q
# test bắt buộc:
#  - AI trả place_id lạ → bị loại, plan vẫn tạo được nếu còn stop hợp lệ
#  - AI trả toàn id lạ → raise InvalidPlan → fallback rule-based
#  - travel_mins lấy từ Directions, KHÔNG lấy số AI trả
grep -rn "CustomPaint" lib/features/planner/   # rỗng
```

---

## P5 — Module 4 + 5: Assistant + Nearby (3 ngày)

### P5.1 Backend Nearby

`NEW backend/app/services/places_service.py`

```python
async def nearby(lat, lng, radius_km, kinds, limit=40) -> list[PlaceOut]:
    cached = cache_get("nearby", lat, lng, radius_km, kinds)     # TTL 24h theo ô 300m
    if cached: return cached
    provider = settings.MAPS_PROVIDER
    places = await (_goong_nearby(...) if provider == "goong" else _google_nearby(...))
    cache_set(...); return places
```

`NEW backend/app/api/v1/endpoints/places.py` — `GET /places/nearby`, `GET /places/{id}`, `GET /places/autocomplete`.
`NEW backend/app/api/v1/endpoints/search.py` — lịch sử + suggest (gộp destinations/local_foods/restaurants/places, dùng `ILIKE` hoặc `pg_trgm`).

### P5.2 Assistant

`NEW backend/app/services/ai/assistant_service.py` — vòng lặp tool-calling §4.2 doc 04; `POST /assistant/chat` trả SSE:

```python
@router.post("/assistant/chat")
async def chat(req: ChatRequest, user=Depends(get_current_user)):
    async def gen():
        async for chunk in assistant_service.stream(user, req):
            yield f"data: {json.dumps(chunk, ensure_ascii=False)}\n\n"
        yield "data: [DONE]\n\n"
    return StreamingResponse(gen(), media_type="text/event-stream",
                             headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})
```

### P5.3 Flutter

- `NEW lib/features/nearby/nearby_screen.dart` (ảnh 4/9) + `nearby_filter_sheet.dart` + `place_detail_sheet.dart`.
- `NEW lib/features/assistant/assistant_screen.dart` (ảnh 8) + `chat_bubble.dart` + `tool_action_card.dart`.
- `NEW lib/data/api/places_api.dart`, `assistant_api.dart` (dùng `dio` với `ResponseType.stream`).
- `NEW lib/state/nearby_provider.dart`, `assistant_provider.dart`.

**DoD P5:**
```bash
pytest backend/tests/test_places.py backend/tests/test_assistant.py -q
# Chat: gửi "thêm quán bún chả vào ngày 2" → tool add_stop chạy → DB có stop mới → UI hiện card hành động
# Nearby: kéo map 500m → có chip "Tìm khu vực này" → bấm → danh sách đổi
```

---

## P6 — Module 7 + hardening (3 ngày)

### P6.1 Expenses

- `NEW backend/app/services/expense_service.py`, `endpoints/expenses.py` (5 endpoint + `budget-summary`).
- `NEW lib/features/expenses/expenses_screen.dart` + `expense_form_sheet.dart` + `budget_donut.dart`.
- Test: tổng theo loại đúng, vượt ngân sách → `over_budget: true`, chi phí dự kiến vs thực tế tách riêng.

### P6.2 Hardening (bắt buộc)

| # | Việc | File |
|---|---|---|
| 1 | Thêm `Depends(get_current_user)` + owner cho mọi endpoint itinerary/trip | `endpoints/itineraries.py`, `trips.py` |
| 2 | OTP: chỉ chấp nhận mã trong DB, hết hạn 5 phút; dev qua `DEV_OTP` env | `auth.py`, `dio_client.dart` |
| 3 | `SECRET_KEY` bắt buộc env ở production | `core/config.py` |
| 4 | CORS danh sách origin cụ thể | `main.py` |
| 5 | Xoá auto-login admin + mockToken | `admin-web/src/hooks/useAuth.jsx`, `services/api/client.js` |
| 6 | Mật khẩu demo chỉ seed khi `SEED_DEMO=1` | `seed_db.py` |
| 7 | Xoá dữ liệu giả: polyline giả, quota `_daily_calls`, Cloudinary demo URL, crawler fallback | `goong_client.py`, `maps_client.py`, `cloudinary_service.py`, `crawler/google_maps.py` |
| 8 | Đếm request thật vào DB (`api_usage`) thay counter giả | `maps_client.py` |
| 9 | Bỏ `create_all()` khỏi startup; chỉ Alembic | `main.py`, `db/session.py` |
| 10 | Xoá `swagger.json` khỏi git, thêm vào `.gitignore` | `.gitignore`, `main.py` |

### P6.3 Kiểm thử tổng

```bash
cd backend && python -m pytest -q           # ≥ 35 pass
cd .. && flutter analyze && flutter test    # 0 issue
flutter build web --release                 # phải < 2 MB JS
```

---

## Bảng tổng hợp file theo phase

| Phase | NEW | EDIT | DEL |
|---|---|---|---|
| P1 | ~20 (tokens, components, router, shell, session) | `main.dart`, `app_theme.dart`, `pubspec.yaml` | `ResponsivePhoneFrameWrapper` (chuyển file) |
| P2 | 6 (maps_service, maps endpoint, map_view, photo_marker, location_service, test_maps) | `goong_client.py`, `router.py`, `map_corridor_screen.dart`, `smart_itinerary_result_screen.dart`, `AndroidManifest.xml` | 2 `CustomPainter` |
| P3 | 18 (5 model/schema, trip_service, trips endpoint, 4 dart model/api/repo/provider, 6 screen, test) | `models/__init__.py`, `home_screen.dart`, `router.py` | `itinerary_screen.dart` (tách) |
| P4 | 8 (prompt_builder, plan_validator, ai endpoint, ai api/repo, generating screen, result screen, test) | `smart_itinerary_engine.dart` (chỉ giữ fallback) | `CustomPainter` còn lại |
| P5 | 12 (places_service, places/search/assistant endpoint, 3 screen, 3 api/state, 2 test) | `router.py`, `home_screen.dart` | `map_corridor_screen.dart` |
| P6 | 8 (expense service/endpoint/screen/form, hardening) | 12 file bảo mật + admin | `swagger.json` khỏi git |

---

## Ước lượng & thứ tự thực thi thực tế

| Ngày | Việc |
|---|---|
| 1 | P1.1–P1.5: token + component + theme |
| 2 | P1.6–P1.9: router + shell + main gọn + dọn P0 còn lại |
| 3 | P2.1–P2.2: backend directions + xoá polyline giả |
| 4 | P2.3–P2.5: Flutter map + GPS + xoá painter |
| 5–8 | P3: models → migration → service → API → test → 3 màn |
| 9–11 | P4: prompt → validate → endpoint → UI generating/result |
| 12–14 | P5: nearby → assistant SSE → 2 màn |
| 15–17 | P6: expenses → hardening → test tổng → build |

---

## Phụ lục: lệnh hay dùng

```bash
# Backend
cd backend
python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
python -m pytest -q
alembic upgrade head

# Flutter
flutter pub get
flutter analyze
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
flutter build web --release

# Admin
cd admin-web && npm install && npm run dev
```
