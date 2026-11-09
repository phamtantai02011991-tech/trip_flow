import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/data_models.dart';

/// Dịch vụ Lưu trữ Offline-first bằng Hive NoSQL (Mục 2.2 & Pitfall 2 trong Kế hoạch tối ưu).
/// Đảm bảo:
/// 1. Lưu đệm JSON trả về từ Dio API Client vào Hive Box (`tripflow_api_cache`).
/// 2. Khi mất mạng (Offline), tự động đọc dữ liệu từ Hive Box để hiển thị ngay lập tức mà không văng màn hình lỗi đỏ.
/// 3. Khi tạo/sửa Lịch trình (`ItineraryModel`), ghi trực tiếp vào Hive Box (`tripflow_itineraries`) trước tiên,
///    đánh dấu `isSyncedWithServer = false` nếu đang offline, và tự động đẩy đồng bộ lên Backend khi có mạng trở lại.
class OfflineCacheService {
  static final OfflineCacheService instance = OfflineCacheService._internal();

  OfflineCacheService._internal();

  static const String apiCacheBoxName = 'tripflow_api_cache';
  static const String itinerariesBoxName = 'tripflow_itineraries';
  static const String favoritesBoxName = 'tripflow_favorites';
  static const String authBoxName = 'tripflow_auth_session';

  bool _hiveInitialized = false;
  Box<String>? _apiCacheBox;
  Box<String>? _itinerariesBox;
  Box<String>? _favoritesBox;
  Box<String>? _authBox;
  FlutterSecureStorage? _secureStorage;
  String? _secureToken;

  /// Token JWT được lưu trong Keychain/Keystore, không nằm trong Hive plaintext.
  static const String _secureTokenKey = 'tripflow_auth_token';

  // Bộ nhớ dự phòng trong RAM cho môi trường Unit/Widget Test không có ổ đĩa Native
  final Map<String, String> _memoryApiCache = {};
  final Map<String, String> _memoryItineraries = {};
  final Map<String, String> _memoryFavorites = {};
  final Map<String, String> _memoryAuth = {};
  String? _memoryGuestToken;

  bool get isHiveReady => _hiveInitialized;

  /// Khởi tạo Hive Flutter và mở các Box lưu trữ cục bộ
  Future<void> init() async {
    if (_hiveInitialized) return;
    try {
      await Hive.initFlutter();
      _apiCacheBox = await Hive.openBox<String>(apiCacheBoxName);
      _itinerariesBox = await Hive.openBox<String>(itinerariesBoxName);
      _favoritesBox = await Hive.openBox<String>(favoritesBoxName);
      _authBox = await Hive.openBox<String>(authBoxName);
      _hiveInitialized = true;
      await _initSecureStorage();
    } catch (_) {
      // Trong môi trường flutter test không có path_provider native, tự động dùng bộ nhớ đệm trong RAM
      _hiveInitialized = false;
    }
  }

  /// Khởi tạo secure storage và migrate token cũ khỏi Hive (nếu có).
  Future<void> _initSecureStorage() async {
    try {
      _secureStorage = const FlutterSecureStorage();
      _secureToken = await _secureStorage!.read(key: _secureTokenKey);
      final raw = _authBox?.get('current_session');
      if (raw == null || raw.isEmpty) return;
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final legacyToken = (payload['auth_token'] ?? '').toString();
      if (legacyToken.isEmpty) return;
      if (_secureToken == null || _secureToken!.isEmpty) {
        await _secureStorage!.write(key: _secureTokenKey, value: legacyToken);
        _secureToken = legacyToken;
      }
      // Xoá token khỏi bản Hive cũ, giữ lại thông tin hiển thị.
      payload['auth_token'] = '';
      await _authBox?.put('current_session', jsonEncode(payload));
    } catch (_) {
      _secureStorage = null;
    }
  }

  /// Lưu phản hồi JSON của REST API vào Hive Box theo khóa `cacheKey`
  Future<void> cacheJson(String cacheKey, dynamic jsonData) async {
    final encoded = jsonEncode({
      'cached_at': DateTime.now().toIso8601String(),
      'data': jsonData,
    });
    _memoryApiCache[cacheKey] = encoded;
    if (_hiveInitialized && _apiCacheBox != null) {
      await _apiCacheBox!.put(cacheKey, encoded);
    }
  }

  /// Đọc dữ liệu JSON đã lưu trong Hive Box khi mất mạng
  dynamic getCachedJson(String cacheKey) {
    String? raw;
    if (_hiveInitialized && _apiCacheBox != null) {
      raw = _apiCacheBox!.get(cacheKey);
    }
    raw ??= _memoryApiCache[cacheKey];
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded['data'];
    } catch (_) {
      return null;
    }
  }

  /// Lưu danh sách lịch trình cá nhân của người dùng vào Hive Box (Offline-first)
  Future<void> saveUserItineraries(List<ItineraryModel> itineraries) async {
    final payload = jsonEncode(itineraries.map((e) => e.toJson()).toList());
    _memoryItineraries['user_itineraries'] = payload;
    if (_hiveInitialized && _itinerariesBox != null) {
      await _itinerariesBox!.put('user_itineraries', payload);
    }
  }

  /// Đọc danh sách lịch trình cá nhân đã lưu từ Hive Box
  List<ItineraryModel>? loadUserItineraries() {
    String? raw;
    if (_hiveInitialized && _itinerariesBox != null) {
      raw = _itinerariesBox!.get('user_itineraries');
    }
    raw ??= _memoryItineraries['user_itineraries'];
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ItineraryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Lưu danh sách ID yêu thích (Địa điểm, Món ăn, Nhà hàng) vào Hive Box
  Future<void> saveFavoriteSets({
    required Set<int> destinationIds,
    required Set<int> foodIds,
    required Set<int> restaurantIds,
  }) async {
    final payload = jsonEncode({
      'destinations': destinationIds.toList(),
      'foods': foodIds.toList(),
      'restaurants': restaurantIds.toList(),
    });
    _memoryFavorites['user_favorites'] = payload;
    if (_hiveInitialized && _favoritesBox != null) {
      await _favoritesBox!.put('user_favorites', payload);
    }
  }

  /// Đọc danh sách ID yêu thích từ Hive Box
  Map<String, Set<int>>? loadFavoriteSets() {
    String? raw;
    if (_hiveInitialized && _favoritesBox != null) {
      raw = _favoritesBox!.get('user_favorites');
    }
    raw ??= _memoryFavorites['user_favorites'];
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'destinations': ((map['destinations'] as List<dynamic>?) ?? [])
            .map((e) => (e as num).toInt())
            .toSet(),
        'foods': ((map['foods'] as List<dynamic>?) ?? [])
            .map((e) => (e as num).toInt())
            .toSet(),
        'restaurants': ((map['restaurants'] as List<dynamic>?) ?? [])
            .map((e) => (e as num).toInt())
            .toSet(),
      };
    } catch (_) {
      return null;
    }
  }

  /// Lấy (hoặc tạo) định danh ẩn danh của thiết bị.
  ///
  /// Backend dùng mã này để chỉ cho đúng thiết bị đọc/sửa các chuyến đi tạo khi
  /// chưa đăng nhập, tránh lộ dữ liệu giữa các khách vãng lai.
  Future<String> getOrCreateGuestToken() async {
    String? token;
    if (_hiveInitialized && _authBox != null) {
      token = _authBox!.get('guest_token');
    }
    token ??= _memoryGuestToken;
    if (token == null || token.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      _memoryGuestToken = token;
      if (_hiveInitialized && _authBox != null) {
        await _authBox!.put('guest_token', token);
      }
    }
    return token;
  }

  /// Lưu thông tin phiên đăng nhập người dùng (SĐT, Họ tên, Trạng thái OTP, Token) vào Hive Box
  Future<void> saveUserAuthSession({
    required String phone,
    required String fullName,
    required bool isOtpVerified,
    String? token,
  }) async {
    final tokenValue = token ?? '';
    var hiveToken = tokenValue;
    if (tokenValue.isNotEmpty && _secureStorage != null) {
      try {
        await _secureStorage!.write(key: _secureTokenKey, value: tokenValue);
        _secureToken = tokenValue;
        hiveToken = '';
      } catch (_) {
        // Secure storage không khả dụng: fallback Hive để không mất phiên.
        hiveToken = tokenValue;
      }
    }
    final payload = jsonEncode({
      'user_phone': phone,
      'user_name': fullName,
      'is_otp_verified': isOtpVerified,
      'auth_token': hiveToken,
      'updated_at': DateTime.now().toIso8601String(),
    });
    _memoryAuth['current_session'] = payload;
    if (_hiveInitialized && _authBox != null) {
      await _authBox!.put('current_session', payload);
    }
  }

  /// Đọc thông tin phiên đăng nhập người dùng từ Hive Box
  Map<String, dynamic>? loadUserAuthSession() {
    String? raw;
    if (_hiveInitialized && _authBox != null) {
      raw = _authBox!.get('current_session');
    }
    raw ??= _memoryAuth['current_session'];
    if (raw == null || raw.isEmpty) return null;
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      if (_secureToken != null && _secureToken!.isNotEmpty) {
        payload['auth_token'] = _secureToken;
      }
      return payload;
    } catch (_) {
      return null;
    }
  }

  /// Xóa phiên đăng nhập người dùng khi đăng xuất
  Future<void> clearUserAuthSession() async {
    _memoryAuth.remove('current_session');
    _secureToken = null;
    try {
      await _secureStorage?.delete(key: _secureTokenKey);
    } catch (_) {
      // Bỏ qua nếu thiết bị không hỗ trợ secure storage.
    }
    if (_hiveInitialized && _authBox != null) {
      await _authBox!.delete('current_session');
    }
  }
}
