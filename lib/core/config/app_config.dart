/// Cấu hình trung tâm cho ứng dụng Flutter TripFlow (Mục 2.2, Mục 3 & Mục 4 Kế hoạch tối ưu).
/// Tuyệt đối KHÔNG nhúng khóa bí mật của máy chủ (Server API Key / DB Credentials) tại đây.
/// Mọi tác vụ gọi Goong Directions API & tính toán hình học Shapely đều thực hiện qua Backend FastAPI.
import 'package:flutter/foundation.dart' show kReleaseMode;

class AppConfig {
  static const String appName = 'TripFlow';
  static const String appTagline = 'Khám phá Du lịch, Ẩm thực & Lộ trình Việt Nam';

  /// JWT hiện tại của phiên đăng nhập (do `TripFlowAppState` gán khi OTP thành công).
  /// Các client API dùng chung biến này để tự gắn header `Authorization`.
  static String? authToken;

  /// Định danh ẩn danh của thiết bị, dùng cho các chuyến đi tạo khi chưa đăng nhập.
  static String? guestToken;

  /// Địa chỉ REST API Backend FastAPI.
  /// Có thể ghi đè khi build bằng `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Goong Maps Tile URL phục vụ hiển thị bản đồ đường phố Việt Nam trên `flutter_map`
  static const String goongMapTilesKey = String.fromEnvironment(
    'GOONG_MAP_TILES_KEY',
    defaultValue: 'demo_goong_maptiles_key',
  );

  static const String goongMapTileUrlTemplate =
      'https://tiles.goong.io/assets/goong_map_web.json?api_key=$goongMapTilesKey';

  static const String fallbackOsmTileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Nền bản đồ miễn phí khi chưa có Goong key.
  /// Dùng OSM chuẩn cho cả chế độ tối để tránh tile yêu cầu API key (Carto/Stadia).
  static const String fallbackOsmDarkTileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Goong chỉ dùng khi đã cấu hình key thật; key demo luôn trả 403.
  static bool get hasGoongTiles =>
      goongMapTilesKey.isNotEmpty && goongMapTilesKey != 'demo_goong_maptiles_key';

  static String mapTileUrlTemplateFor({required bool dark}) {
    if (hasGoongTiles) return goongMapTileUrlTemplate;
    return dark ? fallbackOsmDarkTileUrlTemplate : fallbackOsmTileUrlTemplate;
  }

  /// Cấu hình Cloudinary CDN tự động tối ưu dung lượng ảnh (Pitfall 4)
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'tripflow-vn',
  );

  /// Tỉnh/thành mặc định khi mở ứng dụng lần đầu: TP. Hồ Chí Minh (ID = 1)
  static const int defaultProvinceId = 1;

  /// Giới hạn nghiệp vụ Hành lang tìm kiếm (Bounding Box + Shapely < 2.0 km) & Rate Limit (10 req/min)
  static const double defaultCorridorRadiusKm = 2.0;
  static const double minCorridorRadiusKm = 0.5;
  static const double maxCorridorRadiusKm = 5.0;
  static const int maxItineraryStops = 20;
  static const int corridorRateLimitPerMinute = 10;

  /// Hotline CSKH thật (để trống nếu chưa có — UI sẽ ẩn nút gọi).
  static const String supportHotline = String.fromEnvironment(
    'SUPPORT_HOTLINE',
    defaultValue: '',
  );

  /// Có hiển thị luồng đặt phòng/vé/tour DEMO hay không.
  /// Debug: bật để demo; Release: tắt mặc định để không phát hành booking giả.
  /// Có thể ép bật/tắt bằng `--dart-define=SHOW_DEMO_BOOKING=true|false`.
  static const bool showDemoBooking = bool.fromEnvironment(
    'SHOW_DEMO_BOOKING',
    defaultValue: !kReleaseMode,
  );

  /// Định dạng số tiền VNĐ (ví dụ: 1200000 -> 1.200.000đ)
  static String formatVnd(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join()}đ';
  }

  /// Sinh URL ảnh Thumbnail nhẹ (c_fill,w_400,h_300,q_auto,f_auto) cho danh sách Flutter
  static String buildThumbnailUrl(String originalUrl) {
    if (originalUrl.isEmpty) {
      return 'https://res.cloudinary.com/$cloudinaryCloudName/image/upload/c_fill,w_400,h_300,q_auto,f_auto/v1/tripflow/default_place.jpg';
    }
    if (originalUrl.contains('res.cloudinary.com') &&
        originalUrl.contains('/upload/')) {
      if (originalUrl.contains('c_fill,w_400,h_300')) return originalUrl;
      return originalUrl.replaceFirst(
        '/upload/',
        '/upload/c_fill,w_400,h_300,q_auto,f_auto/',
      );
    }
    if (originalUrl.contains('images.unsplash.com')) {
      final base = originalUrl.split('?').first;
      return '$base?auto=format&fit=crop&w=400&h=300&q=75';
    }
    return originalUrl;
  }

  /// Sinh URL ảnh Chi tiết sắc nét (w_1200,q_auto,f_auto)
  static String buildDetailUrl(String originalUrl) {
    if (originalUrl.isEmpty) {
      return 'https://res.cloudinary.com/$cloudinaryCloudName/image/upload/w_1200,q_auto,f_auto/v1/tripflow/default_place.jpg';
    }
    if (originalUrl.contains('res.cloudinary.com') &&
        originalUrl.contains('/upload/')) {
      if (originalUrl.contains('w_1200,q_auto,f_auto')) return originalUrl;
      return originalUrl.replaceFirst(
        '/upload/',
        '/upload/w_1200,q_auto,f_auto/',
      );
    }
    return originalUrl;
  }
}
