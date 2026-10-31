import 'dart:math' as math;
import 'data_models.dart';

/// Công cụ hình học không gian phục vụ bản đồ Goong Maps và thuật toán Tìm nhà hàng dọc lộ trình
/// (Bounding Box + Point-to-Polyline Corridor Search - Mục 9 & Pitfall 1).
class GeoUtils {
  static const double earthRadiusKm = 6371.0;

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Giải mã chuỗi Encoded Polyline (chuẩn Goong Maps / Google Directions) sang danh sách `[lat, lng]`.
  static List<List<double>> decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];
    final List<List<double>> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      if (index >= len) break;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add([
        double.parse((lat / 1e5).toStringAsFixed(6)),
        double.parse((lng / 1e5).toStringAsFixed(6)),
      ]);
    }
    return points;
  }

  /// Tính khung hình chữ nhật giới hạn (Bounding Box: min_lat, max_lat, min_lng, max_lng)
  /// mở rộng theo `corridorRadiusKm` quanh tuyến đường.
  static Map<String, double> computeBoundingBox(
    List<List<double>> polyline,
    double corridorRadiusKm,
  ) {
    if (polyline.isEmpty) {
      return {
        'min_lat': 10.75,
        'max_lat': 10.80,
        'min_lng': 106.67,
        'max_lng': 106.71,
      };
    }
    final lats = polyline.map((p) => p[0]);
    final lngs = polyline.map((p) => p[1]);
    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);
    final minLng = lngs.reduce(math.min);
    final maxLng = lngs.reduce(math.max);

    final meanLatRad = _degToRad((minLat + maxLat) / 2.0);
    final cosLat = math.max(0.2, math.cos(meanLatRad));
    final latBuffer = (corridorRadiusKm * 1.15) / 111.0;
    final lngBuffer = (corridorRadiusKm * 1.15) / (111.32 * cosLat);

    return {
      'min_lat': double.parse((minLat - latBuffer).toStringAsFixed(6)),
      'max_lat': double.parse((maxLat + latBuffer).toStringAsFixed(6)),
      'min_lng': double.parse((minLng - lngBuffer).toStringAsFixed(6)),
      'max_lng': double.parse((maxLng + lngBuffer).toStringAsFixed(6)),
    };
  }

  /// Tính khoảng cách đường chim bay (km) giữa 2 tọa độ GPS bằng công thức Haversine.
  static double haversineDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt((1 - a).clamp(0.0, 1.0)));
    return earthRadiusKm * c;
  }

  /// Sinh danh sách các đỉnh tọa độ Polyline nối từ điểm xuất phát tới điểm đến.
  static List<List<double>> buildRoutePolyline({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    final List<List<double>> points = [];
    const int steps = 5;
    final dLat = destLat - originLat;
    final dLng = destLng - originLng;

    for (int i = 0; i <= steps; i++) {
      final frac = i / steps;
      final curve = math.sin(frac * math.pi) * 0.0007;
      final lat = originLat + dLat * frac + (i == 0 || i == steps ? 0 : curve);
      final lng = originLng + dLng * frac - (i == 0 || i == steps ? 0 : curve);
      points.add([lat, lng]);
    }
    return points;
  }

  /// Tính tổng chiều dài tuyến đường Polyline (km).
  static double calculateRouteLengthKm(List<List<double>> polyline) {
    if (polyline.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < polyline.length - 1; i++) {
      total += haversineDistanceKm(
        polyline[i][0],
        polyline[i][1],
        polyline[i + 1][0],
        polyline[i + 1][1],
      );
    }
    return double.parse(total.toStringAsFixed(2));
  }

  /// Chiếu điểm P(px, py) lên đoạn thẳng AB(ax, ay -> bx, by).
  /// Trả về [distanceKm, closestLat, closestLng, segmentT].
  static List<double> pointToSegmentDistanceKm(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    final meanLatRad = _degToRad((px + ax + bx) / 3.0);
    final cosLat = math.max(0.2, math.cos(meanLatRad));

    final abX = bx - ax;
    final abY = (by - ay) * cosLat;
    final apX = px - ax;
    final apY = (py - ay) * cosLat;

    final abLenSq = abX * abX + abY * abY;
    double t = 0.0;
    if (abLenSq > 1e-12) {
      t = ((apX * abX + apY * abY) / abLenSq).clamp(0.0, 1.0);
    }

    final closestLat = ax + t * (bx - ax);
    final closestLng = ay + t * (by - ay);
    final distKm = haversineDistanceKm(px, py, closestLat, closestLng);
    return [distKm, closestLat, closestLng, t];
  }

  /// Tìm các nhà hàng nằm trong hành lang bán kính [corridorRadiusKm] dọc theo tuyến đường [polyline].
  /// Bước 1: Lọc nhanh bằng Bounding Box (min_lat, max_lat, min_lng, max_lng).
  /// Bước 2: Tính khoảng cách vuông góc chính xác từ điểm nhà hàng đến đường gấp khúc Polyline.
  static List<CorridorRestaurantResult> findRestaurantsOnCorridor({
    required List<RestaurantModel> restaurants,
    required List<List<double>> polyline,
    required double corridorRadiusKm,
    String? cuisineFilter,
  }) {
    if (polyline.isEmpty) return [];
    final bbox = computeBoundingBox(polyline, corridorRadiusKm);
    final minLat = bbox['min_lat']!;
    final maxLat = bbox['max_lat']!;
    final minLng = bbox['min_lng']!;
    final maxLng = bbox['max_lng']!;

    final totalRouteKm = math.max(0.01, calculateRouteLengthKm(polyline));
    final List<CorridorRestaurantResult> matched = [];
    final filterKw = cuisineFilter?.trim().toLowerCase();

    for (final rest in restaurants) {
      // Bước 1: Lọc sơ bộ bằng Bounding Box
      if (rest.latitude < minLat ||
          rest.latitude > maxLat ||
          rest.longitude < minLng ||
          rest.longitude > maxLng) {
        continue;
      }

      if (filterKw != null && filterKw.isNotEmpty && filterKw != 'all') {
        final text =
            '${rest.cuisineType} ${rest.specialtyDishes} ${rest.name}'.toLowerCase();
        if (!text.contains(filterKw)) continue;
      }

      double minDist = double.infinity;
      double bestLat = polyline.first[0];
      double bestLng = polyline.first[1];
      double bestAlongKm = 0.0;
      double cumulativeKm = 0.0;

      for (int i = 0; i < polyline.length - 1; i++) {
        final ax = polyline[i][0];
        final ay = polyline[i][1];
        final bx = polyline[i + 1][0];
        final by = polyline[i + 1][1];
        final segLen = haversineDistanceKm(ax, ay, bx, by);

        final proj = pointToSegmentDistanceKm(
          rest.latitude,
          rest.longitude,
          ax,
          ay,
          bx,
          by,
        );
        if (proj[0] < minDist) {
          minDist = proj[0];
          bestLat = proj[1];
          bestLng = proj[2];
          bestAlongKm = cumulativeKm + proj[3] * segLen;
        }
        cumulativeKm += segLen;
      }

      if (minDist <= corridorRadiusKm) {
        final distRounded = double.parse(minDist.toStringAsFixed(2));
        final detourKm = double.parse((minDist * 2.0).toStringAsFixed(2));
        final detourMins = math.max(2, (detourKm / 0.4).round() + 1);
        final progressPct = double.parse(
          ((bestAlongKm / totalRouteKm) * 100.0).clamp(0.0, 100.0).toStringAsFixed(1),
        );

        matched.add(
          CorridorRestaurantResult(
            restaurant: rest,
            distanceFromRouteKm: distRounded,
            detourDistanceKm: detourKm,
            estimatedDetourMins: detourMins,
            nearestRouteLat: bestLat,
            nearestRouteLng: bestLng,
            routeProgressPct: progressPct,
          ),
        );
      }
    }

    matched.sort((a, b) =>
        a.distanceFromRouteKm.compareTo(b.distanceFromRouteKm));
    return matched;
  }
}
