/// Cấu hình trung tâm cho ứng dụng Flutter TripFlow (Mục 2.2, Mục 3 & Mục 4 Kế hoạch tối ưu).
/// Tuyệt đối KHÔNG nhúng khóa bí mật của máy chủ (Server API Key / DB Credentials) tại đây.
/// Mọi tác vụ gọi Goong Directions API & tính toán hình học Shapely đều thực hiện qua Backend FastAPI.
class AppConfig {
  static const String appName = 'TripFlow';
  static const String appTagline = 'Khám phá Du lịch, Ẩm thực & Lộ trình Việt Nam';

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
