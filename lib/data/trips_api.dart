import 'package:dio/dio.dart';

import '../core/config/app_config.dart';
import '../core/models/trip.dart';

/// Lỗi API gọn để UI hiển thị đúng thông điệp tiếng Việt.
class TripsApiException implements Exception {
  TripsApiException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Gọi các endpoint `/trips` (Module 1, 2, 6).
class TripsApi {
  TripsApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 8),
                // Tạo lộ trình AI có thể mất ~10 giây (đã đo thực tế)
                receiveTimeout: const Duration(seconds: 120),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<List<Trip>> list() async {
    final resp = await _guard(() => _dio.get('/trips'));
    return ((resp as List?) ?? const [])
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Trip> detail(int id) async {
    final resp = await _guard(() => _dio.get('/trips/$id'));
    return Trip.fromJson(resp as Map<String, dynamic>);
  }

  Future<Trip> create({
    required String title,
    required String originName,
    required double originLat,
    required double originLng,
    String? destinationName,
    double? destinationLat,
    double? destinationLng,
    DateTime? startDate,
    int totalDays = 1,
    int partySize = 2,
    String vehicle = 'motorbike',
    String budgetLevel = 'balanced',
    int? budgetAmount,
    List<String> preferences = const [],
  }) async {
    final resp = await _guard(
      () => _dio.post('/trips', data: {
        'title': title,
        'origin_name': originName,
        'origin_lat': originLat,
        'origin_lng': originLng,
        if (destinationName != null) 'destination_name': destinationName,
        if (destinationLat != null) 'destination_lat': destinationLat,
        if (destinationLng != null) 'destination_lng': destinationLng,
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T').first,
        'total_days': totalDays,
        'party_size': partySize,
        'vehicle': vehicle,
        'budget_level': budgetLevel,
        if (budgetAmount != null) 'budget_amount': budgetAmount,
        'preferences': preferences,
      }),
    );
    return Trip.fromJson(resp as Map<String, dynamic>);
  }

  /// Module 2 — AI tạo lộ trình. Trả về chuyến đã có điểm dừng.
  Future<Trip> generate(int tripId, {String? feedback}) async {
    final resp = await _guard(
      () => _dio.post('/trips/$tripId/generate',
          data: {if (feedback != null) 'feedback': feedback}),
    );
    return Trip.fromJson(resp as Map<String, dynamic>);
  }

  Future<Trip> addStop(int tripId, int dayNumber, Map<String, dynamic> stop) async {
    final resp = await _guard(() => _dio.post('/trips/$tripId/days/$dayNumber/stops', data: stop));
    return Trip.fromJson(resp as Map<String, dynamic>);
  }

  Future<Trip> deleteStop(int tripId, int stopId) async {
    final resp = await _guard(() => _dio.delete('/trips/$tripId/stops/$stopId'));
    return Trip.fromJson(resp as Map<String, dynamic>);
  }

  Future<Trip> reorder(int tripId, int dayNumber, List<int> orderedIds) async {
    final resp = await _guard(
      () => _dio.put('/trips/$tripId/days/$dayNumber/reorder', data: orderedIds),
    );
    return Trip.fromJson(resp as Map<String, dynamic>);
  }

  Future<Trip> share(int tripId) async {
    final resp = await _guard(() => _dio.post('/trips/$tripId/share'));
    return Trip.fromJson(resp as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------
  // Module 3 — chỉ đường thật (OSRM)
  // ------------------------------------------------------------------
  Future<RouteInfo> directions({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<(double, double)> waypoints = const [],
    String vehicle = 'motorbike',
  }) async {
    final resp = await _guard(
      () => _dio.get('/maps/directions', queryParameters: {
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
        if (waypoints.isNotEmpty)
          'waypoints': waypoints.map((w) => '${w.$1},${w.$2}').join(';'),
        'vehicle': vehicle,
      }),
    );
    return RouteInfo.fromJson(resp as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------
  // Module 7 — chi phí
  // ------------------------------------------------------------------
  Future<List<TripExpense>> listExpenses(int tripId) async {
    final resp = await _guard(() => _dio.get('/trips/$tripId/expenses'));
    return ((resp as List?) ?? const [])
        .map((e) => TripExpense.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<TripExpense> addExpense(
    int tripId, {
    required String title,
    required int amount,
    required String category,
    bool planned = false,
    int? tripDayId,
  }) async {
    final resp = await _guard(
      () => _dio.post('/trips/$tripId/expenses', data: {
        'title': title,
        'amount': amount,
        'category': category,
        'planned': planned,
        if (tripDayId != null) 'trip_day_id': tripDayId,
      }),
    );
    return TripExpense.fromJson(resp as Map<String, dynamic>);
  }

  Future<void> deleteExpense(int tripId, int expenseId) async {
    await _guard(() => _dio.delete('/trips/$tripId/expenses/$expenseId'));
  }

  Future<TripBudget> budgetSummary(int tripId) async {
    final resp = await _guard(() => _dio.get('/trips/$tripId/budget-summary'));
    return TripBudget.fromJson(resp as Map<String, dynamic>);
  }

  Future<Object?> _guard(Future<Response<dynamic>> Function() call) async {
    try {
      final resp = await call();
      return resp.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is Map) {
        final detail = data['detail'] as Map;
        throw TripsApiException(
          (detail['message'] ?? 'Máy chủ trả lỗi').toString(),
          code: detail['code']?.toString(),
        );
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw TripsApiException('Không kết nối được máy chủ. Kiểm tra backend đã chạy chưa.');
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        throw TripsApiException('Máy chủ phản hồi quá lâu, thử lại sau.');
      }
      throw TripsApiException('Lỗi máy chủ (${e.response?.statusCode ?? 'mạng'}).');
    }
  }
}

/// Kết quả một lần chỉ đường: có polyline thật thì vẽ theo, không thì nối điểm.
class RouteInfo {
  const RouteInfo({
    required this.provider,
    required this.distanceKm,
    required this.durationMins,
    required this.points,
    required this.note,
  });

  final String provider;
  final double distanceKm;
  final int durationMins;
  final List<(double, double)> points; // (lat, lng)
  final String note;

  bool get isReal => provider == 'osrm' || provider == 'goong';

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    final encoded = json['encoded_polyline']?.toString();
    final raw = (json['geometry'] as List?) ?? const [];
    final points = encoded != null && encoded.isNotEmpty
        ? _decode(encoded)
        : raw
            .whereType<List>()
            .map((p) => ((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList(growable: false);

    return RouteInfo(
      provider: (json['provider'] ?? 'fallback').toString(),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      durationMins: (json['duration_mins'] as num?)?.toInt() ?? 0,
      points: points,
      note: (json['note'] ?? '').toString(),
    );
  }

  /// Giải mã polyline chuẩn Google/OSRM thành danh sách (lat, lng).
  static List<(double, double)> _decode(String encoded) {
    final result = <(double, double)>[];
    var index = 0;
    var lat = 0;
    var lng = 0;
    while (index < encoded.length) {
      var shift = 0;
      var value = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        value |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (value & 1) != 0 ? ~(value >> 1) : value >> 1;
      result.add((lat / 1e5, lng / 1e5));

      shift = 0;
      value = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        value |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (value & 1) != 0 ? ~(value >> 1) : value >> 1;
      result[result.length - 1] = (lat / 1e5, lng / 1e5);
    }
    return result;
  }
}

/// Một dòng chi phí (Module 7).
class TripExpense {
  const TripExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.planned,
  });

  final int id;
  final String title;
  final int amount;
  final String category;
  final bool planned;

  factory TripExpense.fromJson(Map<String, dynamic> json) => TripExpense(
        id: (json['id'] as num).toInt(),
        title: (json['title'] ?? '').toString(),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        category: (json['category'] ?? 'other').toString(),
        planned: json['planned'] == true,
      );
}

/// Tổng hợp ngân sách (Module 7).
class TripBudget {
  const TripBudget({
    required this.budgetAmount,
    required this.totalEstimate,
    required this.actualTotal,
    required this.perPerson,
    required this.overBudget,
    required this.byCategory,
    this.remaining,
  });

  final int budgetAmount;
  final int totalEstimate;
  final int actualTotal;
  final int perPerson;
  final bool overBudget;
  final Map<String, int> byCategory;
  final int? remaining;

  factory TripBudget.fromJson(Map<String, dynamic> json) {
    final rawMap = (json['by_category'] as Map?) ?? const {};
    return TripBudget(
      budgetAmount: (json['budget_amount'] as num?)?.toInt() ?? 0,
      totalEstimate: (json['total_estimate'] as num?)?.toInt() ?? 0,
      actualTotal: (json['actual_total'] as num?)?.toInt() ?? 0,
      perPerson: (json['per_person'] as num?)?.toInt() ?? 0,
      overBudget: json['over_budget'] == true,
      remaining: (json['remaining'] as num?)?.toInt(),
      byCategory: {
        for (final entry in rawMap.entries)
          entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
      },
    );
  }
}
