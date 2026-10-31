import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/offline_cache_service.dart';
import '../utils/data_models.dart';
import '../utils/geo_utils.dart';
import '../utils/mock_data.dart';

/// Lớp HTTP Client trung tâm sử dụng `Dio` kết hợp bộ nhớ đệm `Hive` (`OfflineCacheService`).
/// Tuân thủ Mục 2.2, Pitfall 1, Pitfall 2 & Pitfall 3 trong bản kế hoạch tối ưu:
/// - Tự động gắn Bearer Token qua Interceptor.
/// - Tự động lưu phản hồi 200 OK vào Hive Box (`tripflow_api_cache`).
/// - Khi mất mạng (Offline), tự động đọc dữ liệu từ Hive Box hoặc `MockDataRepository` mà không crash app.
/// - Nhận diện mã lỗi HTTP 429 (SlowAPI Rate Limit 10 lần/phút/IP) khi tìm kiếm lộ trình.
class DioApiClient {
  final Dio _dio;
  final OfflineCacheService cacheService;
  String? authToken;
  String? lastRateLimitWarning;

  DioApiClient({
    String? baseUrl,
    OfflineCacheService? cacheService,
  })  : cacheService = cacheService ?? OfflineCacheService.instance,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
            connectTimeout: const Duration(milliseconds: 2500),
            receiveTimeout: const Duration(milliseconds: 3000),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (authToken != null && authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 429) {
            lastRateLimitWarning =
                'Bạn đã vượt quá giới hạn ${AppConfig.corridorRateLimitPerMinute} yêu cầu tìm đường/phút (SlowAPI Rate Limit). Đang hiển thị kết quả tính toán dự phòng.';
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Lấy danh sách Tỉnh/thành phố (tự động cache vào Hive)
  Future<List<ProvinceModel>> fetchProvinces() async {
    const cacheKey = 'provinces_all';
    try {
      final resp = await _dio.get('/provinces');
      final data = resp.data as List<dynamic>;
      await cacheService.cacheJson(cacheKey, data);
      return data
          .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final cached = cacheService.getCachedJson(cacheKey) as List<dynamic>?;
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return MockDataRepository.provinces;
    }
  }

  /// Lấy danh sách Địa điểm du lịch (tự động cache vào Hive)
  Future<List<DestinationModel>> fetchDestinations({int? provinceId}) async {
    final cacheKey = 'destinations_${provinceId ?? "all"}';
    try {
      final resp = await _dio.get(
        '/destinations',
        queryParameters: provinceId != null ? {'province_id': provinceId} : null,
      );
      final data = resp.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];
      await cacheService.cacheJson(cacheKey, items);
      return items
          .map((e) => DestinationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final cached = cacheService.getCachedJson(cacheKey) as List<dynamic>?;
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => DestinationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (provinceId != null) {
        return MockDataRepository.destinations
            .where((d) => d.provinceId == provinceId)
            .toList();
      }
      return MockDataRepository.destinations;
    }
  }

  /// Lấy danh sách Món ăn đặc sản (tự động cache vào Hive)
  Future<List<LocalFoodModel>> fetchLocalFoods({int? provinceId}) async {
    final cacheKey = 'local_foods_${provinceId ?? "all"}';
    try {
      final resp = await _dio.get(
        '/local-foods',
        queryParameters: provinceId != null ? {'province_id': provinceId} : null,
      );
      final data = resp.data as List<dynamic>;
      await cacheService.cacheJson(cacheKey, data);
      return data
          .map((e) => LocalFoodModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final cached = cacheService.getCachedJson(cacheKey) as List<dynamic>?;
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => LocalFoodModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (provinceId != null) {
        return MockDataRepository.localFoods
            .where((f) => f.provinceId == provinceId)
            .toList();
      }
      return MockDataRepository.localFoods;
    }
  }

  /// Lấy danh sách Nhà hàng / Quán ăn (tự động cache vào Hive)
  Future<List<RestaurantModel>> fetchRestaurants({int? provinceId}) async {
    final cacheKey = 'restaurants_${provinceId ?? "all"}';
    try {
      final resp = await _dio.get(
        '/restaurants',
        queryParameters: provinceId != null ? {'province_id': provinceId} : null,
      );
      final data = resp.data as List<dynamic>;
      await cacheService.cacheJson(cacheKey, data);
      return data
          .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final cached = cacheService.getCachedJson(cacheKey) as List<dynamic>?;
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (provinceId != null) {
        return MockDataRepository.restaurants
            .where((r) => r.provinceId == provinceId)
            .toList();
      }
      return MockDataRepository.restaurants;
    }
  }

  /// Lấy danh sách Lịch trình mẫu (tự động cache vào Hive)
  Future<List<ItineraryModel>> fetchSampleItineraries({int? provinceId}) async {
    final cacheKey = 'sample_itineraries_${provinceId ?? "all"}';
    try {
      final resp = await _dio.get(
        '/itineraries',
        queryParameters: {
          if (provinceId != null) 'province_id': provinceId,
          'templates_only': true,
        },
      );
      final data = resp.data as List<dynamic>;
      await cacheService.cacheJson(cacheKey, data);
      return data
          .map((e) => ItineraryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final cached = cacheService.getCachedJson(cacheKey) as List<dynamic>?;
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => ItineraryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return MockDataRepository.sampleItineraries;
    }
  }

  /// Gọi API Backend `POST /api/v1/restaurants/corridor-search` (Goong Maps + Bounding Box SQL + Shapely < 2km).
  /// Nếu mất kết nối mạng hoặc vượt Rate Limit 10 lần/phút, tự động fallback về bộ lọc cục bộ đã cache.
  Future<CorridorSearchResponseModel> searchCorridorOnBackend({
    required int provinceId,
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    double corridorRadiusKm = 2.0,
    String? cuisineFilter,
    required List<RestaurantModel> fallbackRestaurants,
  }) async {
    lastRateLimitWarning = null;
    try {
      final resp = await _dio.post(
        '/restaurants/corridor-search',
        data: {
          'province_id': provinceId,
          'origin_lat': originLat,
          'origin_lng': originLng,
          'destination_lat': destinationLat,
          'destination_lng': destinationLng,
          'corridor_radius_km': corridorRadiusKm,
          'cuisine_filter':
              (cuisineFilter == null || cuisineFilter == 'all') ? null : cuisineFilter,
        },
      );
      return CorridorSearchResponseModel.fromJson(
        resp.data as Map<String, dynamic>,
      );
    } catch (_) {
      final poly = GeoUtils.buildRoutePolyline(
        originLat: originLat,
        originLng: originLng,
        destLat: destinationLat,
        destLng: destinationLng,
      );
      final bbox = GeoUtils.computeBoundingBox(poly, corridorRadiusKm);
      final routeKm = GeoUtils.calculateRouteLengthKm(poly);
      final results = GeoUtils.findRestaurantsOnCorridor(
        restaurants: fallbackRestaurants,
        polyline: poly,
        corridorRadiusKm: corridorRadiusKm,
        cuisineFilter: cuisineFilter,
      );
      return CorridorSearchResponseModel(
        encodedPolyline: 'offline_cached_goong_polyline',
        polyline: poly,
        boundingBox: bbox,
        corridorRadiusKm: corridorRadiusKm,
        totalRouteKm: routeKm,
        estimatedDriveMins: (routeKm / 0.38).round().clamp(3, 180),
        matchedCount: results.length,
        mapProvider: 'goong_maps_offline_cache',
        spatialEngine: 'postgresql_btree_bbox_plus_shapely_linestring',
        results: results,
      );
    }
  }

  /// Đồng bộ Lịch trình đã tạo/sửa khi Offline lên Backend (`POST /api/v1/itineraries/sync`)
  Future<bool> syncItineraryToBackend(ItineraryModel itinerary) async {
    try {
      await _dio.post(
        '/itineraries/sync',
        data: {
          'local_id': itinerary.id,
          'client_offline_id': 'hive_itin_${itinerary.id}',
          'province_id': itinerary.provinceId,
          'title': itinerary.title,
          'description': itinerary.description,
          'total_days': itinerary.totalDays,
          'stops': itinerary.stops.map((s) => s.toJson()).toList(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gửi báo cáo sai thông tin lên Admin/Moderator
  Future<bool> submitContentReport({
    required String targetType,
    required int targetId,
    required String targetName,
    required String issueType,
    required String description,
  }) async {
    try {
      await _dio.post(
        '/destinations/$targetId/report',
        data: {
          'target_type': targetType,
          'target_id': targetId,
          'target_name': targetName,
          'issue_type': issueType,
          'description': description,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
