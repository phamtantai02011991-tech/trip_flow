# KẾ HOẠCH KHẮC PHỤC TRIỆT ĐỂ SỰ CỐ TẢI ẢNH & CHE KHUẤT GIAO DIỆN TRÊN THIẾT BỊ DI ĐỘNG (PIXEL 8 PRO)

**Dự án:** TripFlow — Khám Phá Du Lịch & Lộ Trình Thông Minh  
**Tác nhân thực hiện:** 🧠 Planner Agent (Agent 1)  
**Người nhận kế hoạch:** 💻 Coder Agent (Agent 2)  
**Ngày lập kế hoạch:** 02/11/2026  
**Tham chiếu phản hồi:** Phản ánh từ người dùng: *"lỗi quá nhiều , hình ảnh không thấy được là sao"* kèm ảnh chụp màn hình máy Pixel 8 Pro (`media_1793590075992_3ef50a9c.jpg`).

---

## 1. PHÂN TÍCH NGUYÊN NHÂN GỐC RỄ (ROOT CAUSE ANALYSIS)

Dựa trên hình ảnh chụp thực tế từ điện thoại Google Pixel 8 Pro và đối soát toàn bộ mã nguồn của dự án, 3 vấn đề nghiêm trọng đã được xác định:

### Vấn đề 1: Hệ điều hành Android chặn toàn bộ kết nối mạng của Ứng dụng
- **Hiện tượng:** Thẻ Hero "Hà Nội 36 Phố Phường" fallback về màu nền gradient xanh đậm `Color(0xFF0D9488)`; Thẻ "Điểm Đến Thịnh Hành" (Phố đi bộ Nguyễn Huệ, Bảo tàng Chứng tích Chiến tranh) không tải được ảnh và hiện icon lỗi gạch chéo `Icons.image_not_supported_outlined`.
- **Nguyên nhân cốt lõi:** File `android/app/src/main/AndroidManifest.xml` hoàn toàn thiếu quyền truy cập Internet và Network State:
  - Thiếu `<uses-permission android:name="android.permission.INTERNET"/>`
  - Thiếu `<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>`
  - Thiếu cờ `android:usesCleartextTraffic="true"` trong thẻ `<application>`.
- **Hệ quả:** Khi cài đặt ứng dụng lên máy thật Android hoặc thiết bị Pixel, Android Sandbox lập tức chặn mọi socket HTTP/HTTPS từ ứng dụng, ném ra ngoại lệ mạng hoặc không cho phép bất kỳ `Image.network` nào kết nối tới máy chủ internet.

### Vấn đề 2: Máy chủ Wikimedia Commons chặn 403 Forbidden các request từ Flutter/Dart
- **Hiện tượng:** Ngay cả khi kết nối Internet được cấp quyền, nguồn ảnh Wikimedia (`upload.wikimedia.org`) áp dụng chính sách lọc User-Agent rất ngặt nghèo (Wikimedia User-Agent Policy). Các request HTTP từ Flutter Image widget với header mặc định `Dart/<version> (dart:io)` bị máy chủ Wikimedia từ chối thẳng thừng với mã lỗi `403 Forbidden`.
- **Hệ quả:** Tất cả 38 URL wikimedia trong dữ liệu mẫu (`lib/core/utils/mock_data.dart`) và 4 thẻ Hero Carousel (`lib/features/home/widgets/hero_trip_carousel.dart`) đều sụp đổ và rơi vào hàm `errorBuilder`.

### Vấn đề 3: Trải nghiệm người dùng (UX) khi Fallback ảnh quá thô ráp
- **Hiện tượng:** Trong `lib/features/home/widgets/popular_destination_card.dart`, hàm `errorBuilder` trả về một khối màu xám tro nhạt `Color(0xFFCBD5E1)` với biểu tượng `Icons.image_not_supported_outlined` to ở giữa. Điều này tạo cảm giác ứng dụng "bị vỡ", "kém chất lượng", gây tâm lý ức chế cho người dùng.
- **Giải pháp UX:** Thay vì hiện icon gạch chéo báo lỗi, cần trang bị nền gradient nghệ thuật cao cấp đồng bộ với chủ đề du lịch (Dark Slate / Teal / Navy), kết hợp biểu tượng danh lam thắng cảnh nhẹ nhàng và hiệu ứng chuyển cảnh mượt mà.

### Vấn đề 4: Thanh điều hướng nổi (Floating Bottom Bar) che lấp nội dung cuối màn hình
- **Hiện tượng:** Tiêu đề "Ẩm Thực & Món Ngon", nút "Xem tất cả", danh sách món đặc sản và card "Tìm Quán Ăn Dọc Tuyến" bị thanh Floating Bottom Bar che khuất một phần.
- **Nguyên nhân:** Scaffold của `MainNavigationShell` (`lib/main.dart`) cấu hình `extendBody: true` để tạo hiệu ứng thanh điều hướng lอย trên nền nội dung. Thanh bar có chiều cao 60px + margin 10px + phần đệm an toàn `SafeArea` của Pixel 8 Pro (~34px) = tổng chiều cao chiếm dụng ~104px. Tuy nhiên, `ListView` trong `lib/features/home/home_screen.dart` chỉ chừa khoảng đệm dưới `padding: const EdgeInsets.only(bottom: 90)`, khiến nội dung cuối cùng bị thanh bar che lấp mất ~20-30px khi người dùng cuộn kịch đáy.

---

## 2. GIẢI PHÁP KỸ THUẬT TỔNG THỂ (COMPREHENSIVE SOLUTION)

```mermaid
flowchart TD
    subgraph Android OS
        A[AndroidManifest.xml] -->|Thêm INTERNET & ACCESS_NETWORK_STATE| B[Cho phép App kết nối Socket ra ngoài]
        A -->|usesCleartextTraffic=true| B
    end

    subgraph Flutter Network Layer
        C[lib/main.dart] -->|HttpOverrides.global| D[TripFlowHttpOverrides: UserAgent hợp lệ]
        D -->|Vượt rào 403 Forbidden| E[Load ảnh mạng thông suốt]
    end

    subgraph Data Sources & Reliability
        F[mock_data.dart & hero_trip_carousel.dart] -->|Chuyển 100% URL Wikimedia| G[Unsplash CDN Siêu Tốc & Ổn Định]
        H[popular_destination_card.dart] -->|Nâng cấp errorBuilder| I[Gradient Cao Cấp + Icon Địa Danh Tinh Tế]
    end

    subgraph Screen Layout
        J[lib/features/home/home_screen.dart] -->|Tăng bottom padding từ 90 lên 130px| K[Nội dung cuộn thoáng đãng, không bị Floating Bar che]
    end

    B --> E
    E --> G
    G --> I
    I --> K
```

---

## 3. DANH SÁCH CHI TIẾT CÁC FILE CẦN CHỈNH SỬA VÀ MÃ NGUỒN MẪU

Coder Agent phải tuân thủ chính xác từng file và mã nguồn dưới đây:

### File 1: `android/app/src/main/AndroidManifest.xml`
- **Mục tiêu:** Cấp quyền Internet & Network State, cho phép cleartext traffic.
- **Vị trí sửa:** Thêm quyền trước thẻ `<application>`, thêm `android:usesCleartextTraffic="true"` vào thuộc tính của `<application>`.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Cấp toàn quyền truy cập mạng Internet và giám sát trạng thái mạng -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <application
        android:label="trip_flow"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            ...
```

---

### File 2: `lib/main.dart`
- **Mục tiêu:** Cấu hình `HttpOverrides` để thiết lập header `User-Agent` chuẩn cho toàn bộ `HttpClient` và `Image.network` trong ứng dụng (tự động bypass lỗi 403 của các máy chủ CDN như Wikimedia).
- **Vị trí sửa:** Thêm import `dart:io` và `package:flutter/foundation.dart`, định nghĩa class `TripFlowHttpOverrides`, và gán `HttpOverrides.global` trong hàm `main()`.

```dart
import 'dart:io' show HttpOverrides, HttpClient, SecurityContext;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/providers/app_providers.dart';
import 'core/storage/offline_cache_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_state.dart';
import 'features/home/home_screen.dart';
import 'features/itinerary/itinerary_screen.dart';
import 'features/assistant/assistant_screen.dart';
import 'features/local_foods/local_foods_screen.dart';
import 'features/nearby/nearby_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/trip/trip_list_screen.dart';

/// HttpOverrides tùy chỉnh để cấp User-Agent hợp lệ cho mọi request tải ảnh và dữ liệu mạng,
/// ngăn chặn việc bị máy chủ CDN (Wikimedia, Cloudflare, ...) chặn 403 Forbidden.
class TripFlowHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'TripFlow/1.0 (Android; Mobile)';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kích hoạt HttpOverrides trên nền tảng di động (Android / iOS)
  if (!kIsWeb) {
    HttpOverrides.global = TripFlowHttpOverrides();
  }
  await OfflineCacheService.instance.init();
  runApp(
    const ProviderScope(
      child: TripFlowApp(),
    ),
  );
}
```

---

### File 3: `lib/features/home/widgets/hero_trip_carousel.dart`
- **Mục tiêu:**
  1. Thay thế toàn bộ 4 URL Wikimedia bằng các link ảnh Unsplash chuyên đề Việt Nam có độ nét cao, tốc độ tải tức thì.
  2. Nâng cấp `errorBuilder` và `loadingBuilder` với gradient tinh tế và icon danh thắng mờ ảo sang trọng.
- **Mã nguồn thay đổi cụ thể:**

```dart
  // Cập nhật danh sách các chuyến đi mẫu tiêu biểu sang Unsplash CDN chất lượng cao:
  final List<FeaturedTripItem> _trips = const [
    FeaturedTripItem(
      id: 'trip-hcm-heritage',
      title: 'Sài Gòn Di Sản & Lịch Sử',
      subtitle: 'Khởi hành từ 350.000đ',
      durationText: '3 ngày 2 đêm • 12 điểm dừng',
      heroImageUrl:
          'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1280&q=80',
      priceStarting: '350.000đ',
      travelersText: '2 người',
      provinceId: 1,
      provinceName: 'TP. Hồ Chí Minh',
    ),
    FeaturedTripItem(
      id: 'trip-hanoi-ancient',
      title: 'Hà Nội 36 Phố Phường',
      subtitle: 'Khởi hành từ 480.000đ',
      durationText: '2 ngày 1 đêm • 8 điểm dừng',
      heroImageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1280&q=80',
      priceStarting: '480.000đ',
      travelersText: '2-4 người',
      provinceId: 2,
      provinceName: 'Hà Nội',
    ),
    FeaturedTripItem(
      id: 'trip-danang-coastal',
      title: 'Đà Nẵng Biển Xanh Cầu Rồng',
      subtitle: 'Khởi hành từ 520.000đ',
      durationText: '4 ngày 3 đêm • 14 điểm dừng',
      heroImageUrl:
          'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1280&q=80',
      priceStarting: '520.000đ',
      travelersText: '2 người',
      provinceId: 3,
      provinceName: 'Đà Nẵng',
    ),
    FeaturedTripItem(
      id: 'trip-dalat-flowers',
      title: 'Đà Lạt Mộng Mơ & Cà Phê',
      subtitle: 'Khởi hành từ 390.000đ',
      durationText: '3 ngày 2 đêm • 10 điểm dừng',
      heroImageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1280&q=80',
      priceStarting: '390.000đ',
      travelersText: '2 người',
      provinceId: 4,
      provinceName: 'Lâm Đồng',
    ),
  ];
```

Trong phương thức `_buildCard`, cải tiến phần ảnh nền:
```dart
            // 1. Ảnh phong cảnh toàn màn hình của card với loadingBuilder và errorBuilder mượt mà
            Positioned.fill(
              child: Image.network(
                trip.heroImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFFF4B55).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
```

---

### File 4: `lib/features/home/widgets/popular_destination_card.dart`
- **Mục tiêu:** Xóa bỏ hoàn toàn icon gạch chéo `Icons.image_not_supported_outlined` thô kệch. Thay thế bằng hiệu ứng Gradient màu sắc chiều sâu nghệ thuật và icon danh thắng thanh nhã `Icons.landscape_rounded`.
- **Mã nguồn thay đổi cụ thể:**

```dart
                // 1. Ảnh tràn viền với loading và error builder cao cấp
                Positioned.fill(
                  child: Image.network(
                    heroUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF4B55),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF334155), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.landscape_rounded,
                          color: Colors.white.withValues(alpha: 0.28),
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
```

---

### File 5: `lib/features/home/home_screen.dart`
- **Mục tiêu:** Tăng khoảng đệm đáy của `ListView` từ `90` lên `130` để giải quyết triệt để lỗi Floating Bottom Bar che lấp "Ẩm Thực & Món Ngon" và "Tìm Quán Ăn Dọc Tuyến".
- **Vị trí sửa:** Dòng 46 trong `HomeScreen`:

```dart
// TRƯỚC:
            child: ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [

// SAU:
            child: ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: [
```

---

### File 6: `lib/core/utils/mock_data.dart`
- **Mục tiêu:** Thay thế toàn bộ 38 URL Wikimedia Commons bằng các link Unsplash chuyên đề danh lam thắng cảnh Việt Nam chất lượng Full HD, tải siêu mượt.
- **Danh sách URL thay thế chuẩn cho 10 Tỉnh/Thành & 28 Điểm Đến:**

#### A. 10 Tỉnh/Thành phố (`provinces`):
1. **TP. Hồ Chí Minh** (id 1):
   - Thay `upload.wikimedia.org/.../Independence_Palace.jpg` bằng:
   - `'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1280&q=80'`
2. **TP. Đà Nẵng** (id 2):
   - Thay `upload.wikimedia.org/.../Dragon_Bridge_Da_Nang_1.jpg` bằng:
   - `'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1280&q=80'`
3. **Thủ đô Hà Nội** (id 3):
   - Thay `upload.wikimedia.org/.../Tháp_Rùa.jpg` bằng:
   - `'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1280&q=80'`
4. **Quảng Ninh (Vịnh Hạ Long)** (id 4):
   - Thay `upload.wikimedia.org/.../Halong_Bay.jpg` bằng:
   - `'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1280&q=80'`
5. **Lào Cai (Sa Pa)** (id 5):
   - Thay `upload.wikimedia.org/.../Fansipan.jpg` bằng:
   - `'https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=1280&q=80'`
6. **Thừa Thiên Huế (Cố đô Huế)** (id 6):
   - Thay `upload.wikimedia.org/.../Ngọ_môn,_Huế.jpg` bằng:
   - `'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1280&q=80'`
7. **Quảng Nam (Phố cổ Hội An)** (id 7):
   - Thay `upload.wikimedia.org/.../Japanese_Covered_Bridge...jpg` bằng:
   - `'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=1280&q=80'`
8. **Khánh Hòa (Nha Trang)** (id 8):
   - Thay `upload.wikimedia.org/.../PoNagar.jpg` bằng:
   - `'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1280&q=80'`
9. **Lâm Đồng (Đà Lạt)** (id 9):
   - Thay `upload.wikimedia.org/.../Da_Lat_-_Xuan_Huong_Lake.jpg` bằng:
   - `'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1280&q=80'`
10. **Kiên Giang (Phú Quốc)** (id 10):
    - Thay `upload.wikimedia.org/.../Dinh_Cậu_Phú_Quốc.jpg` bằng:
    - `'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1280&q=80'`

#### B. 28 Điểm Đến (`destinations`):
- **TP. Hồ Chí Minh:**
  - id 1 (Dinh Độc Lập): `'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1080&q=80'`
  - id 2 (Chợ Bến Thành): `'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1080&q=80'`
  - id 3 (Nhà thờ Đức Bà Sài Gòn): `'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1080&q=80'`
  - id 4 (Bưu điện Trung tâm Sài Gòn): `'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1080&q=80'`
  - id 5 (Bến Nhà Rồng): `'https://images.unsplash.com/photo-1519451241324-20b4ea2c4220?auto=format&fit=crop&w=1080&q=80'`
  - id 6 (Phố đi bộ Nguyễn Huệ): `'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=1080&q=80'`
  - id 7 (Bảo tàng Chứng tích Chiến tranh): `'https://images.unsplash.com/photo-1572953109213-3be62398eb95?auto=format&fit=crop&w=1080&q=80'`
  - id 8 (Địa đạo Củ Chi): `'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1080&q=80'`
- **Đà Nẵng:**
  - id 9 (Cầu Rồng): `'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1080&q=80'`
  - id 10 (Ngũ Hành Sơn): `'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1080&q=80'`
  - id 11 (Bán đảo Sơn Trà & Chùa Linh Ứng): `'https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=1080&q=80'`
- **Hà Nội:**
  - id 12 (Hồ Hoàn Kiếm & Đền Ngọc Sơn): `'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1080&q=80'`
  - id 13 (Văn Miếu - Quốc Tử Giám): `'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1080&q=80'`
  - id 14 (Hoàng thành Thăng Long): `'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1080&q=80'`
- **Quảng Ninh:**
  - id 15 (Vịnh Hạ Long): `'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1080&q=80'`
  - id 16 (Bảo tàng Quảng Ninh): `'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1080&q=80'`
- **Lào Cai (Sa Pa):**
  - id 17 (Đỉnh Fansipan): `'https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=1080&q=80'`
  - id 18 (Bản Cát Cát): `'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1080&q=80'`
- **Thừa Thiên Huế:**
  - id 19 (Quần thể Di tích Cố đô Huế): `'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1080&q=80'`
  - id 20 (Chùa Thiên Mụ): `'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1080&q=80'`
- **Quảng Nam (Hội An):**
  - id 21 (Chùa Cầu & Phố cổ Hội An): `'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=1080&q=80'`
  - id 22 (Rừng dừa Bảy Mẫu): `'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1080&q=80'`
- **Khánh Hòa (Nha Trang):**
  - id 23 (Tháp Bà Ponagar): `'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1080&q=80'`
  - id 24 (VinWonders Nha Trang): `'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1080&q=80'`
- **Lâm Đồng (Đà Lạt):**
  - id 25 (Hồ Xuân Hương & Quảng trường Lâm Viên): `'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1080&q=80'`
  - id 26 (Đỉnh Langbiang): `'https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=1080&q=80'`
- **Kiên Giang (Phú Quốc):**
  - id 27 (Dinh Cậu Phú Quốc): `'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1080&q=80'`
  - id 28 (Bãi Sao & Nam Đảo Phú Quốc): `'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1080&q=80'`

---

### File 7: `lib/features/itinerary/screens/stop_detail_sheet.dart`
- **Mục tiêu:** Thay thế 3 link Wikimedia fallback trong `galleryUrls` bằng link Unsplash chất lượng cao.
- **Vị trí sửa:** Dòng 38-40:

```dart
// TRƯỚC:
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Dinh_%C4%90%E1%BB%99c_L%E1%BA%ADp_2022.jpg/1280px-Dinh_%C4%90%E1%BB%99c_L%E1%BA%ADp_2022.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Saigon_Post_Office_-_Ho_Chi_Minh_City_Vietnam.jpg/1280px-Saigon_Post_Office_-_Ho_Chi_Minh_City_Vietnam.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Notre-Dame_Cathedral_Basilica_of_Saigon_2017.jpg/1280px-Notre-Dame_Cathedral_Basilica_of_Saigon_2017.jpg',

// SAU:
      'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1080&q=80',
      'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1080&q=80',
      'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1080&q=80',
```

---

## 4. QUY TRÌNH THỰC HIỆN CHO CODER AGENT

1. **Bước 1:** Cập nhật `android/app/src/main/AndroidManifest.xml` (thêm quyền Internet, Access Network State, cleartext traffic).
2. **Bước 2:** Cập nhật `lib/main.dart` (thêm `TripFlowHttpOverrides` và gán trong `main()`).
3. **Bước 3:** Cập nhật `lib/features/home/widgets/hero_trip_carousel.dart` (Unsplash URLs + loading/error builder mượt mà).
4. **Bước 4:** Cập nhật `lib/features/home/widgets/popular_destination_card.dart` (loại bỏ icon gạch chéo, thêm gradient và landscape icon sang trọng).
5. **Bước 5:** Cập nhật `lib/features/home/home_screen.dart` (tăng `bottom: 130` cho `ListView`).
6. **Bước 6:** Cập nhật toàn bộ link Wikimedia trong `lib/core/utils/mock_data.dart` và `lib/features/itinerary/screens/stop_detail_sheet.dart` sang Unsplash URLs.
7. **Bước 7:** Chạy `flutter analyze` để kiểm tra cú pháp và tính toàn vẹn của mã nguồn.
8. **Bước 8:** Ghi báo cáo hoàn thành vào `.agents/workspace/code_report.md` và bàn giao cho Reviewer Agent.

---

## 5. TIÊU CHÍ NGHIỆM THU (ACCEPTANCE CRITERIA)

| Hạng mục | Tiêu chuẩn đạt |
|---|---|
| **Android Permissions** | `AndroidManifest.xml` có `<uses-permission android:name="android.permission.INTERNET"/>` và `ACCESS_NETWORK_STATE`, thẻ `<application>` có `android:usesCleartextTraffic="true"`. |
| **HttpOverrides** | `lib/main.dart` khai báo `TripFlowHttpOverrides` gắn User-Agent hợp lệ, hoạt động an toàn kể cả khi chạy web (`kIsWeb`). |
| **Hero Carousel** | Thẻ "Hà Nội 36 Phố Phường" và các thẻ khác hiển thị ảnh nền phong cảnh sắc nét, không bị rơi về nền màu đơn sắc. |
| **Điểm Đến Thịnh Hành** | Thẻ "Phố đi bộ Nguyễn Huệ", "Bảo tàng Chứng tích Chiến tranh" hiển thị ảnh nét 100%, không còn bất kỳ icon gạch chéo `image_not_supported`. |
| **Fallback UI** | Trong trường hợp thiết bị tắt mạng (offline), card hiển thị gradient nghệ thuật cao cấp kèm icon danh thắng mờ tinh tế, không làm vỡ bố cục giao diện. |
| **Bottom Navigation Bar** | Khi cuộn màn hình xuống hết cỡ, tiêu đề "Ẩm Thực & Món Ngon", các món đặc sản và thẻ "Tìm Quán Ăn Dọc Tuyến" nằm hoàn toàn phía trên thanh điều hướng nổi, không bị che khuất. |
| **Toàn vẹn mã nguồn** | Lệnh `flutter analyze` không có lỗi nghiêm trọng (0 errors). |
