# 02 — Design System & Ngôn ngữ thị giác

> Nguồn: 8 ảnh tham chiếu người dùng gửi (home 3D card deck, itinerary map + photo markers, stop detail full-bleed, dark map nearby, AI wizard 3 bước, route planner waypoint, tablet weather, AI app "Mira", bản đồ tìm kiếm kiểu native).
>
> Mục tiêu: **một** hệ thống token dùng cho cả 9 màn, thay 40+ mã màu hardcode rải rác trong `lib/`.

---

## 1. Ngôn ngữ thị giác rút ra từ 8 ảnh

| Đặc điểm chung | Bằng chứng | Quy tắc cho TripFlow |
|---|---|---|
| Ảnh là nhân vật chính, chữ tối giản | ảnh 1, 3, 8 | Card ảnh tràn viền, chỉ 2–3 dòng chữ, gradient đáy để đọc chữ |
| Bo góc rất lớn ở khối lớn, pill ở chip | ảnh 2 (sheet 32px), ảnh 5 (chip) | Card 24–28, sheet 32, chip/nút 999 |
| Điều hướng nổi (floating), không dính đáy | ảnh 1 | Bottom nav pill nổi, margin 16, nền trắng mờ + bóng |
| Bản đồ tối khi ở chế độ "khám phá" | ảnh 4 | `NearbyScreen` mặc định dark map, list card nền `#1C1C1E` |
| Bản đồ sáng khi ở chế độ "lộ trình" | ảnh 2, 6, 7 | `TripOverview` dùng map sáng để thấy polyline đỏ |
| Một màu nhấn duy nhất cho hành động | ảnh 1 đỏ san hô, ảnh 8 xanh dương, ảnh 5 đất nung | TripFlow: **san hô `#FF4B55`** là màu hành động, các màu khác chỉ để phân loại |
| Chip lọc ngang, cuộn được, có icon | ảnh 4, 8, 9 | `AppChip` + `CategoryChip` |
| Số liệu nằm trong pill nhỏ | ảnh 2 `3 days and 2 nights · 12 Spots`, ảnh 7 `10 h 12 min / 912 km` | `InfoPill` |
| Marker bản đồ là ảnh tròn có viền | ảnh 2 | `PhotoMarker` 44–56px, viền trắng 3px, đuôi nhọn |
| Tiến trình dạng chấm + số | ảnh 5 | `StepIndicator` |
| Ngày dạng pill đỏ khi active | ảnh 2 | `DayPill` |

---

## 2. Token

### 2.1 Màu — `lib/ui/tokens/app_colors.dart`

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Thương hiệu ────────────────────────────────────────────────
  static const coral       = Color(0xFFFF4B55); // CTA chính, tab active, polyline
  static const coralDark   = Color(0xFFE03A44);
  static const coralSoft   = Color(0xFFFFEDEE); // nền chip/nhãn san hô
  static const terracotta  = Color(0xFFC2703F); // nhấn phụ trong wizard (ảnh 5)
  static const cream       = Color(0xFFFAF7F2); // nền app (ảnh 1, 5)
  static const ink         = Color(0xFF14161A); // chữ chính, nền dark
  static const inkSoft     = Color(0xFF3E434B);

  // ── Nền & bề mặt ───────────────────────────────────────────────
  static const bg          = cream;
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF3EFE8); // khối phụ trên nền kem
  static const line        = Color(0xFFE8E2D9); // viền 1px
  static const lineStrong  = Color(0xFFD6CFC4);

  // ── Chữ ───────────────────────────────────────────────────────
  static const textPrimary   = ink;
  static const textSecondary = Color(0xFF6B7078);
  static const textTertiary  = Color(0xFF9AA0A6);
  static const textOnDark    = Color(0xFFF5F5F7);

  // ── Bản đồ tối (ảnh 4) ────────────────────────────────────────
  static const mapDarkBg    = Color(0xFF1C1C1E);
  static const mapDarkCard  = Color(0xFF262628);
  static const mapDarkLine  = Color(0xFF3A3A3C);

  // ── Ngữ nghĩa ─────────────────────────────────────────────────
  static const success = Color(0xFF12B76A); // "Đang mở cửa"
  static const warning = Color(0xFFF79009); // "Sắp đóng"
  static const danger  = Color(0xFFE5484D); // "Đã đóng", xoá
  static const info    = Color(0xFF2E6BFF); // tuyến đường, liên kết

  // ── Phân loại địa điểm (dùng cho map pin & chip) ──────────────
  static const kindFood    = Color(0xFFF97316);
  static const kindCafe    = Color(0xFF8B5E34);
  static const kindHotel   = Color(0xFF7C3AED);
  static const kindGas     = Color(0xFF2563EB);
  static const kindEv      = Color(0xFF12B76A);
  static const kindRest    = Color(0xFF0EA5E9);
  static const kindSight   = Color(0xFFE11D48);

  // ── Gradient phủ ảnh (để chữ trắng đọc được) ──────────────────
  static const photoScrim = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x14000000), Color(0xCC000000)],
    stops: [0.35, 0.6, 1.0],
  );
}
```

> **Không dùng màu nào ngoài file này.** Kiểm tra bằng `grep -rn "Color(0xFF" lib/ --include=*.dart | grep -v ui/tokens` → phải rỗng (trừ ảnh gradient đặc thù).

### 2.2 Chữ — `app_typography.dart`

Chọn font: **Plus Jakarta Sans** cho tiêu đề (hình học, đậm, giống ảnh 1/8), **Inter** cho nội dung. Cả hai đều OFL, tải 1 lần, **bundle trong `assets/fonts/`** để chạy offline (travel app hay mất mạng).

```dart
abstract final class AppTypography {
  static const display = TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 30, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -0.8);
  static const h1      = TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 24, height: 1.18, fontWeight: FontWeight.w800, letterSpacing: -0.5);
  static const h2      = TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20, height: 1.22, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static const h3      = TextStyle(fontFamily: 'Inter',            fontSize: 17, height: 1.28, fontWeight: FontWeight.w700);
  static const body    = TextStyle(fontFamily: 'Inter',            fontSize: 15, height: 1.45, fontWeight: FontWeight.w400);
  static const bodySm  = TextStyle(fontFamily: 'Inter',            fontSize: 13.5, height: 1.42, fontWeight: FontWeight.w400);
  static const label   = TextStyle(fontFamily: 'Inter',            fontSize: 12, height: 1.2, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static const caption = TextStyle(fontFamily: 'Inter',            fontSize: 11.5, height: 1.2, fontWeight: FontWeight.w500);
  static const button  = TextStyle(fontFamily: 'Inter',            fontSize: 15, height: 1.1, fontWeight: FontWeight.w700);
}
```

Thang cỡ chữ (dùng đúng, không tự đặt): `11.5 · 12 · 13.5 · 15 · 17 · 20 · 24 · 30`. Hiện code đang dùng 11–26 rải rác → thay hết.

### 2.3 Khoảng cách & bo góc & bóng

```dart
abstract final class AppSpace { static const x1=4.0, x2=8.0, x3=12.0, x4=16.0, x5=20.0, x6=24.0, x8=32.0, x10=40.0; }
abstract final class AppRadii {
  static const sm = 12.0; static const md = 18.0; static const lg = 24.0;
  static const xl = 30.0; static const sheet = 32.0;
  static const pill = BorderRadius.all(Radius.circular(999));
}
abstract final class AppShadow {
  static const card = [BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 8))];
  static const floating = [BoxShadow(color: Color(0x1F0F172A), blurRadius: 32, offset: Offset(0, 14))];
  static const marker = [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))];
}
```

### 2.4 Chuyển động

| Tương tác | Thời lượng | Curve |
|---|---|---|
| Chuyển tab | 220ms | `easeOutCubic` |
| Mở bottom sheet | 280ms | `easeOutQuint` |
| Card deck xoay | 320ms | `easeOutBack` (nhẹ) |
| Marker pop-in | 240ms | `easeOutBack` |
| Skeleton shimmer | 1200ms loop | linear |
| Chat streaming | 40ms/token | linear |

---

## 3. Component library — `lib/ui/components/`

| Component | Mô tả | Ảnh tham chiếu | Ghi chú kỹ thuật |
|---|---|---|---|
| `AppCard` | Nền trắng, bo 24, bóng `card`, viền 0 | 3, 6 | `padding` mặc định 16 |
| `ImageCard` | Ảnh tràn + scrim + chữ trắng đáy | 1, 3 | `Stack` + `DecoratedBox(photoScrim)` + `Hero` |
| `AppChip` | Pill, 2 trạng thái (chọn: nền ink chữ trắng; thường: nền surfaceAlt) | 4, 5, 9 | Cao 36, icon 16 trái |
| `CategoryChip` | Chip có icon màu theo `kind*` | 4, 8 | |
| `InfoPill` | `3 ngày 2 đêm · 12 điểm` | 2, 7 | Cao 32, nền trắng 85% blur |
| `RatingPill` | `★ 4.9 (127)` | 3 | Sao vàng `#F5B301`, chữ 11.5 |
| `PhotoMarker` | Marker ảnh tròn + viền trắng + đuôi | 2 | `Alignment.topCenter`, `IgnorePointer` khi kéo map |
| `DayPill` | `Day 1` active đỏ | 2 | `AnimatedContainer` |
| `StepIndicator` | 3 chấm + số | 5 | `AnimatedAlign` thanh tiến trình |
| `FloatingPillNav` | 5 icon, tab active mở rộng thành pill đỏ có nhãn | 1 | `AnimatedSize` + `AnimatedContainer`, 380×64 |
| `SectionHeader` | Tiêu đề + "Xem tất cả →" | 1 | |
| `BottomSheetShell` | Sheet bo 32, grabber, `DraggableScrollableSheet` | 2, 4 | `snapSizes: [0.45, 0.85]` |
| `EmptyState` | Icon + tiêu đề + CTA | – | Dùng khi 0 kết quả |
| `SkeletonCard` | Shimmer | – | Không dùng spinner toàn màn |
| `PlaceListTile` | Ảnh vuông 72 + tên + rating + trạng thái + khoảng cách | 4, 9 | Cao 96 |

### `FloatingPillNav` — đặc tả (thay bottom bar hiện tại)

```
Chiều cao 64, margin ngang 16, cách đáy 16 + safeArea
Nền: Colors.white.withOpacity(.92) + BackdropFilter(blur 18) + AppShadow.floating
Tab thường: icon 24, màu textSecondary, không nhãn
Tab active: pill 128×48 nền coral, icon trắng + nhãn trắng 13.5 w700, bo 999
Animation: AnimatedContainer 220ms easeOutCubic
5 tab: Trang chủ · Gần đây · Chuyến đi · Trợ lý · Tôi
Nhãn tiếng Việt: "Trang chủ", "Gần đây", "Chuyến đi", "Trợ lý", "Tôi"
```

---

## 4. Ánh xạ 8 ảnh → màn hình (chi tiết dựng)

### Ảnh 1 — Home
```
SafeArea
└── CustomScrollView
    ├── SliverToBoxAdapter  Header: "Chào, {tên}" (bodySm, secondary)
    │                        "Đi đâu tiếp theo?" (display) + chuông (badge chấm đỏ)
    ├── SliverToBoxAdapter  HeroTripDeck (cao 340)
    │     └── 3 card xếp lớp: card sau scale .94/.88, offset y 12/24, góc -3°/+3°
    │         mỗi card: ảnh 16:9 → phủ scrim → tên chuyến (h1 trắng)
    │         + "Từ 1.250.000đ" + avatar nhóm + InfoPill
    │         + nút tròn ↗ 44px góc phải trên
    │         + dots chỉ báo 3 chấm, chấm active dài 18px đỏ
    ├── SliverToBoxAdapter  SectionHeader("Điểm đến nổi bật", "Xem tất cả")
    ├── SliverToBoxAdapter  SizedBox(h 216) ListView.separated horizontal
    │     └── PopularDestinationCard 165×215: ảnh + RatingPill góc phải + tên 1 dòng
    ├── SliverToBoxAdapter  SectionHeader("Gần bạn", "Bản đồ")
    ├── SliverToBoxAdapter  Danh sách PlaceListTile ngang (3 item)
    └── SliverPadding(bottom: 96)   // chừa chỗ cho pill nav
```

### Ảnh 2 — Trip overview
```
Stack
├── FlutterMap (55% chiều cao, tile sáng Goong)
│     ├── PolylineLayer: màu coral 4px, viền trắng 6px dưới
│     ├── MarkerLayer: PhotoMarker cho từng stop, item active to hơn + viền coral
│     └── Nút "về giữa" tròn 44 góc phải dưới map
├── Positioned top: nút back tròn trắng + "Tổng quan lộ trình" + tên chuyến
└── DraggableScrollableSheet (min .45, max .88)
      ├── grabber 36×4
      ├── Row: "Khởi hành {date}" · "Về {date}" · nút "Đổi" (outline pill)
      ├── Row DayPill "Ngày 1/2/3"
      ├── ListView horizontal các StopCard 190×170
      │     ├── ảnh 16:10, badge "07:00 – 10:00"
      │     ├── tên 2 dòng, loại + khoảng cách
      │     └── đường nét đứt `----` nối giữa các card (CustomPaint 1px dash)
      └── FAB "Thêm điểm dừng"
```

### Ảnh 3 — Stop detail
```
Stack fill
├── Ảnh full-screen (Hero từ card) + scrim đáy mạnh
├── Nút back tròn 40 góc trái trên; badge "Ngày 1" giữa trên
├── Đáy: "Điểm dừng 2" (caption trắng 70%)
│        "Hồ Moran – Đường Rockpile" (display trắng, 2 dòng)
│        RatingPill 4.9 (127)
├── AppCard trắng nổi (margin 16, bo 24) chồng lên ảnh:
│        "Cách bạn 400 m" (h3) + địa chỉ (bodySm secondary)
│        nút tròn 56 coral icon điều hướng
│        hàng thumbnail 64×64 bo 14 + ô "+25" nền ink
└── Nút "Thêm vào chuyến" full width
```

### Ảnh 4 — Nearby (dark)
```
Scaffold nền mapDarkBg
├── FlutterMap dark style (Goong dark / carto dark)
├── Top: search bar tròn + nút filter
├── Chip row: Nhà hàng · Khách sạn · Xăng · Sạc · Cà phê · Nghỉ chân
├── Marker: pin màu theo kind, active phóng to + pulse
├── Bottom sheet tối (bo 32, nền mapDarkCard):
│     ├── "Quán gần đây · 2,5 km"
│     ├── LazyList PlaceListTile (ảnh 64, tên, rating vàng, "Đang mở cửa" xanh)
│     └── kéo lên → chi tiết (ảnh 9 style): ảnh lớn, nút Gọi · Chỉ đường · Thêm
└── Rail dọc trái (tuỳ chọn, ảnh 4): Thêm · Khám phá · Đã lưu · Tôi
```

### Ảnh 5 — Planner wizard (3 bước)
```
Scaffold nền cream
├── AppBar trong suốt: X · "Tạo kế hoạch với AI" · (bước 2/3)
├── StepIndicator: 3 chấm nối, active đỏ + số
├── Step 1 "Bạn muốn đi đâu?"      → SearchField + 3 card ảnh tỉnh + "Chọn trên bản đồ"
├── Step 2 "Bạn thích gì?"         → Wrap CategoryChip (Thiên nhiên, Ăn uống, Biển, Núi,
│                                     Văn hoá, Chợ đêm, Lễ hội, Chụp ảnh, Thư giãn)
│                                   + TextField "Ngân sách / từ khoá khác"
├── Step 3 "Bạn đi mấy ngày?"      → Stepper -/+ (1..14) + date range picker
│                                   + chọn phương tiện (Xe máy/Ô tô/Xe khách)
│                                   + số người (-/+)
└── Đáy: Row "Quay lại" (outline) · "Tiếp tục"/"Tạo lộ trình" (coral, full)
```
Bắt buộc: nút "Tiếp tục" disabled tới khi bước hợp lệ; **không tick sẵn sở thích**; kiểm tra origin ≠ destination trước khi gọi API.

### Ảnh 6 — Route builder
```
Row
├── Panel trái 360 (tablet) / bottom sheet (mobile)
│     ├── Tab phương tiện: Xe máy · Ô tô · Xe khách (kèm ETA tổng)
│     ├── Danh sách waypoint: chấm tròn + tên + nút kéo ≡
│     ├── "+ Thêm điểm dừng"
│     └── "Tuỳ chọn" (tránh đường đèo, ưu tiên cao tốc)
└── FlutterMap: polyline info 5px + chấm số thứ tự từng waypoint
      ├── Thanh tìm kiếm dọc tuyến: "Tìm dọc đường" + chip Khách sạn · Xăng · Sạc
      └── InfoPill tổng: "10 h 12 min · 912 km"
```

### Ảnh 7 — Tablet + weather
```
Row: panel danh sách (380) + map (còn lại)
├── Mỗi waypoint: badge số màu (1 xanh, 2 cam, …) + tên + "Lưu lại 8 giờ"
├── Card thời tiết nổi trên map: icon + "18°C, mưa rào" + 3 ngày tới
└── Chip thời gian/distance góc dưới map
```

### Ảnh 8 — Assistant "Mira"
```
Scaffold nền gradient rất nhạt (trắng → xanh nhạt)
├── Top: nút back tròn + "Trợ lý TripFlow" + chevron chọn model + nút "…"
├── Bubble chào: "Chào! Mình là TripFlow AI. Mình giúp gì cho chuyến đi?"
├── Row suggestion chips: "Đi đâu tháng 11?" · "Lên lịch 3 ngày Đà Lạt" · "Quán ăn gần đây"
├── Danh sách bong bóng chat (user: nền coral chữ trắng; AI: nền trắng viền line)
├── Card "Gợi ý từ AI" (nền trắng, list 3 bullet) khi AI trả kế hoạch
└── Input đáy: nút mic tròn 56 + TextField + nút gửi
      khi đang stream: hiện waveform 3 sóng animate
```

### Ảnh 9 — Place detail sheet (kiểu native)
```
Bottom sheet
├── Ảnh lớn 16:9 + nút X
├── Tên + loại + trạng thái ("Đang mở · 09:00–23:00") + địa chỉ
├── Hàng nút: Lưu · Gọi · Chỉ đường · Thêm vào chuyến
├── "Thông tin": giờ mở cửa theo ngày, giá, SĐT
└── "Ảnh" horizontal 120×90
```

---

## 5. Trạng thái & chuyển cảnh

| Trạng thái | Hiển thị |
|---|---|
| Đang tải danh sách | 3 `SkeletonCard` (không spinner toàn màn) |
| Đang tải bản đồ | Map + shimmer overlay mờ 20% |
| Lỗi mạng | Banner trên cùng "Không có kết nối · Đang dùng dữ liệu đã lưu" + nút "Thử lại" |
| Không có dữ liệu | `EmptyState` + CTA đúng ngữ cảnh (vd "Tạo chuyến đầu tiên") |
| AI đang tạo | Màn riêng với 4 bước tiến trình thật: "Đang tìm tuyến đường… Đang chọn điểm dừng… Đang xếp lịch… Đang tính chi phí…" (không phải animation giả) |
| AI thất bại | "Không tạo được lộ trình. Thử lại" + nút "Dùng gợi ý mặc định" (rule-based, có nhãn rõ) |

---

## 6. Accessibility

- Tương phản chữ trên ảnh: luôn có scrim, tối thiểu `0xCC000000` ở đáy.
- Không dùng màu làm tín hiệu duy nhất: trạng thái mở/đóng có cả icon + chữ.
- Tap target ≥ 44×44.
- `Semantics(label:)` cho marker bản đồ và các nút chỉ có icon.
- Hỗ trợ `textScaler` tới 1.3: không đặt chiều cao cố định cho text.

---

## 7. Việc phải xoá khi áp dụng design system

| Hiện tại | Thay bằng |
|---|---|
| `AppTheme.primaryTeal #0D9488` | `AppColors.coral` (+ teal chỉ còn cho trạng thái) |
| Card bo 16, viền `#E2E8F0` | `AppRadii.lg` 24, không viền |
| Button bo 12 | Pill 999 hoặc 14 |
| 40+ màu hardcode (`#FF4B55`, `#0F172A`, `#14B8A6`, …) | `AppColors.*` |
| `TextStyle(fontSize: 11..26)` rải rác | `AppTypography.*` |
| Bottom bar phẳng 5 icon + chữ nhỏ | `FloatingPillNav` |
| `Khung giả lập điện thoại` + status bar giả "09:41" trong `main.dart` | Giữ cho web demo nhưng tách file `dev/phone_frame.dart`, chỉ bật khi `kIsWeb && kDebugMode` |
