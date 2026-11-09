import 'package:dio/dio.dart';

import '../core/config/app_config.dart';
import '../core/network/auth_interceptor.dart';

/// Một POI trả về từ `/places/nearby`.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.kind,
    required this.lat,
    required this.lng,
    required this.address,
    required this.rating,
    required this.distanceKm,
    required this.etaMin,
    required this.source,
    this.priceHint = '',
    this.openHours = '',
    this.reviewCount = 0,
    this.qualityLabel = 'normal',
    this.qualityScore = 0,
    this.imageUrl = '',
    this.thumbnailUrl = '',
  });

  final String id;
  final String name;
  final String kind;
  final double lat;
  final double lng;
  final String address;
  final double rating;
  final double distanceKm;
  final int etaMin;
  final String source;
  final String priceHint;
  final String openHours;
  final int reviewCount;

  /// hidden_gem | top_rated | popular | normal — do backend tính từ rating,
  /// số lượt đánh giá, giá và loại quán (xem `places_service._quality`).
  final String qualityLabel;
  final double qualityScore;
  final String imageUrl;
  final String thumbnailUrl;

  bool get isHiddenGem => qualityLabel == 'hidden_gem';
  bool get isTopRated => qualityLabel == 'top_rated';

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        kind: (json['kind'] ?? 'food').toString(),
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        address: (json['address'] ?? '').toString(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        etaMin: (json['eta_min'] as num?)?.toInt() ?? 0,
        source: (json['source'] ?? 'catalog').toString(),
        priceHint: (json['price_hint'] ?? '').toString(),
        openHours: (json['open_hours'] ?? '').toString(),
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        qualityLabel: (json['quality_label'] ?? 'normal').toString(),
        qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0,
        imageUrl: (json['image_url'] ?? '').toString(),
        thumbnailUrl: (json['thumbnail_url'] ?? '').toString(),
      );
}

class NearbyResult {
  const NearbyResult({
    required this.items,
    required this.total,
    required this.note,
    this.hiddenGemCount = 0,
  });
  final List<Place> items;
  final int total;
  final String note;
  final int hiddenGemCount;
}

/// Điểm nghỉ chân nằm dọc tuyến đường (Module corridor).
class AlongRouteStop {
  const AlongRouteStop({
    required this.id,
    required this.name,
    required this.kind,
    required this.stopCategory,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.thumbnailUrl,
    required this.rating,
    required this.reviewCount,
    required this.distanceFromRouteKm,
    required this.estimatedDetourMins,
    required this.routeProgressPct,
  });

  final String id;
  final String name;
  final String kind;
  final String stopCategory;
  final String address;
  final double latitude;
  final double longitude;
  final String thumbnailUrl;
  final double rating;
  final int reviewCount;
  final double distanceFromRouteKm;
  final int estimatedDetourMins;
  final double routeProgressPct;

  factory AlongRouteStop.fromJson(Map<String, dynamic> json) => AlongRouteStop(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        kind: (json['kind'] ?? 'rest').toString(),
        stopCategory: (json['stop_category'] ?? '').toString(),
        address: (json['address'] ?? '').toString(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        thumbnailUrl: (json['thumbnail_url'] ?? '').toString(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        distanceFromRouteKm:
            (json['distance_from_route_km'] as num?)?.toDouble() ?? 0,
        estimatedDetourMins:
            (json['estimated_detour_mins'] as num?)?.toInt() ?? 0,
        routeProgressPct:
            (json['route_progress_pct'] as num?)?.toDouble() ?? 0,
      );
}

class PlacesApi {
  PlacesApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 20),
            )) {
    _dio.interceptors.add(authInterceptor());
  }

  final Dio _dio;

  Future<NearbyResult> nearby({
    required double lat,
    required double lng,
    double radiusKm = 3,
    List<String> kinds = const ['food'],
    double minRating = 0,
    bool openNow = false,
    String sortBy = 'quality',
    int maxPrice = 0,
  }) async {
    final resp = await _dio.get('/places/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
      'kinds': kinds.join(','),
      'min_rating': minRating,
      'open_now': openNow,
      'sort_by': sortBy,
      if (maxPrice > 0) 'max_price': maxPrice,
    });
    final data = resp.data as Map<String, dynamic>;
    return NearbyResult(
      items: ((data['items'] as List?) ?? const [])
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      total: (data['total'] as num?)?.toInt() ?? 0,
      note: (data['note'] ?? '').toString(),
      hiddenGemCount: (data['hidden_gem_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Điểm nghỉ chân / quán cà phê dọc hành lang tuyến đường.
  Future<List<AlongRouteStop>> alongRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    double corridorRadiusKm = 2,
    String kinds = 'rest,gas,ev,cafe',
  }) async {
    final resp = await _dio.post('/places/along-route', data: {
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'corridor_radius_km': corridorRadiusKm,
      'kinds': kinds,
    });
    final data = resp.data as Map<String, dynamic>;
    return ((data['stops'] as List?) ?? const [])
        .map((e) => AlongRouteStop.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
