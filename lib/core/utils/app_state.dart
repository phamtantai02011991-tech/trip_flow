import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../storage/offline_cache_service.dart';
import 'data_models.dart';
import 'mock_data.dart';
import 'vietnamese_utils.dart';

/// Trạng thái quyền truy cập vị trí của người dùng (Mục 5.3 & Mục 15).
enum LocationPermissionState {
  granted,
  denied,
}

/// Quản lý toàn bộ trạng thái ứng dụng TripFlow Mobile kết hợp Riverpod + Dio + Hive Offline-first.
/// Hỗ trợ:
/// - Chọn Tỉnh/thành phố (Mặc định: TP. Hồ Chí Minh)
/// - Xem nội dung không bắt buộc đăng nhập (Guest Mode) hoặc Đăng nhập tài khoản
/// - Tạo, thêm điểm dừng, xóa, đổi thứ tự điểm dừng và lưu lịch trình bền vững vào Hive (`OfflineCacheService`)
/// - Tự động đồng bộ lịch trình đã tạo khi Offline lên Backend (`POST /api/v1/itineraries/sync`) khi có mạng trở lại
/// - Gọi Backend FastAPI cho Corridor Search (`POST /api/v1/restaurants/corridor-search` - Goong Maps + Bounding Box + Shapely).
class TripFlowAppState extends ChangeNotifier {
  final OfflineCacheService cacheService;
  final ApiClient apiClient;

  TripFlowAppState({
    OfflineCacheService? cacheService,
    DioApiClient? dioClient,
  })  : cacheService = cacheService ?? OfflineCacheService.instance,
        apiClient = ApiClient(
          cacheService: cacheService ?? OfflineCacheService.instance,
        ) {
    _restoreFromHiveCache();
  }

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  ProvinceModel _selectedProvince = MockDataRepository.vietnamAll;
  ProvinceModel get selectedProvince => _selectedProvince;
  bool get isNationalMode => _selectedProvince.id == 0;
  ProvinceModel get currentProvinceDisplay => _selectedProvince;

  List<ProvinceModel> _provinces = List.of(MockDataRepository.provinces);
  List<ProvinceModel> get provinces => _provinces;

  List<DestinationModel> _allDestinations =
      List.of(MockDataRepository.destinations);
  List<LocalFoodModel> _allLocalFoods = List.of(MockDataRepository.localFoods);
  List<RestaurantModel> _allRestaurants =
      List.of(MockDataRepository.restaurants);
  List<ItineraryModel> _sampleItineraries =
      List.of(MockDataRepository.sampleItineraries);

  /// Danh sách lịch trình cá nhân của người dùng (lưu giữ bền vững trong Hive cả khi Offline)
  final List<ItineraryModel> _userItineraries = [
    const ItineraryModel(
      id: 901,
      provinceId: 1,
      provinceName: 'TP. Hồ Chí Minh',
      title: 'Lịch trình Khám phá Sài Gòn của tôi',
      description:
          'Lịch trình cá nhân đã lưu trong bộ nhớ đệm Hive trên thiết bị (Xem lại được ngay cả khi mất mạng).',
      totalDays: 1,
      isTemplate: false,
      isSyncedWithServer: true,
      stops: [
        ItineraryStopModel(
          id: 9001,
          dayNumber: 1,
          stopOrder: 1,
          stopType: 'destination',
          referenceId: 1,
          title: 'Dinh Độc Lập (Hội trường Thống Nhất)',
          address: '135 Nam Kỳ Khởi Nghĩa, Quận 1, TP.HCM',
          latitude: 10.7770,
          longitude: 106.6953,
          plannedTime: '08:00 - 10:00',
          durationMins: 120,
          notes: 'Tham quan di tích lịch sử mở đầu hành trình.',
        ),
        ItineraryStopModel(
          id: 9002,
          dayNumber: 1,
          stopOrder: 2,
          stopType: 'restaurant',
          referenceId: 4,
          title: 'Nhà hàng Ngon (160 Pasteur)',
          address: '160 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM',
          latitude: 10.7782,
          longitude: 106.6968,
          plannedTime: '11:30 - 13:00',
          durationMins: 90,
          notes: 'Điểm dừng ăn trưa dọc lộ trình Quận 1 -> Quận 3.',
        ),
        ItineraryStopModel(
          id: 9003,
          dayNumber: 1,
          stopOrder: 3,
          stopType: 'destination',
          referenceId: 7,
          title: 'Bảo tàng Chứng tích Chiến tranh',
          address: '28 Võ Văn Tần, Quận 3, TP.HCM',
          latitude: 10.7795,
          longitude: 106.6921,
          plannedTime: '14:00 - 16:00',
          durationMins: 120,
          notes: 'Tham quan bảo tàng buổi chiều.',
        ),
      ],
    ),
  ];

  int _activeItineraryIndex = 0;

  /// Danh sách Yêu thích
  final Set<int> _favoriteDestinationIds = {1, 6};
  final Set<int> _favoriteFoodIds = {1};
  final Set<int> _favoriteRestaurantIds = {3};

  /// Lịch sử báo sai thông tin từ người dùng
  final List<ContentReportRecord> _submittedReports = [];

  /// Trạng thái mạng, quyền vị trí và tài khoản
  bool _isLoading = false;
  bool _isOfflineSimulated = false;
  LocationPermissionState _locationPermission = LocationPermissionState.granted;
  bool _isLoggedIn = false;
  String _userName = 'Khách du lịch (Guest Mode)';
  String _userEmail = '';
  String _userPhone = '';
  bool _isOtpVerified = false;
  String _authToken = '';

  bool get isLoading => _isLoading;
  bool get isOfflineSimulated => _isOfflineSimulated;
  LocationPermissionState get locationPermission => _locationPermission;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  bool get isOtpVerified => _isOtpVerified;
  String get authToken => _authToken;

  List<ItineraryModel> get sampleItineraries => _sampleItineraries;
  List<ItineraryModel> get userItineraries => _userItineraries;
  ItineraryModel get activeItinerary => _userItineraries[_activeItineraryIndex];
  int get activeItineraryIndex => _activeItineraryIndex;
  List<ContentReportRecord> get submittedReports => _submittedReports;

  /// Số lượng lịch trình tạo/chỉnh sửa khi Offline đang chờ đồng bộ lên Server
  int get unsyncedItinerariesCount =>
      _userItineraries.where((i) => !i.isSyncedWithServer).length;

  Set<int> get favoriteDestinationIds => _favoriteDestinationIds;
  Set<int> get favoriteFoodIds => _favoriteFoodIds;
  Set<int> get favoriteRestaurantIds => _favoriteRestaurantIds;

  int get totalFavoritesCount =>
      _favoriteDestinationIds.length +
      _favoriteFoodIds.length +
      _favoriteRestaurantIds.length;

  /// Khôi phục lịch trình & danh sách yêu thích từ Hive Box khi mở ứng dụng
  void _restoreFromHiveCache() {
    final savedItins = cacheService.loadUserItineraries();
    if (savedItins != null && savedItins.isNotEmpty) {
      _userItineraries
        ..clear()
        ..addAll(savedItins);
      _activeItineraryIndex = 0;
    }
    final savedFavs = cacheService.loadFavoriteSets();
    if (savedFavs != null) {
      _favoriteDestinationIds
        ..clear()
        ..addAll(savedFavs['destinations'] ?? {1, 6});
      _favoriteFoodIds
        ..clear()
        ..addAll(savedFavs['foods'] ?? {1});
      _favoriteRestaurantIds
        ..clear()
        ..addAll(savedFavs['restaurants'] ?? {3});
    }

    final authSession = cacheService.loadUserAuthSession();
    if (authSession != null) {
      _userPhone = authSession['user_phone']?.toString() ?? '';
      _userName = authSession['user_name']?.toString() ?? 'Du khách TripFlow';
      _isOtpVerified = authSession['is_otp_verified'] == true;
      _authToken = authSession['auth_token']?.toString() ?? '';
      if (_userPhone.isNotEmpty) {
        _userEmail = '$_userPhone@tripflow.vn';
      }
      _isLoggedIn = _userPhone.isNotEmpty || _authToken.isNotEmpty;
      if (_authToken.isNotEmpty) {
        apiClient.authToken = _authToken;
      }
    }
  }

  Future<void> _persistItinerariesToHive() async {
    await cacheService.saveUserItineraries(_userItineraries);
  }

  Future<void> _persistFavoritesToHive() async {
    await cacheService.saveFavoriteSets(
      destinationIds: _favoriteDestinationIds,
      foodIds: _favoriteFoodIds,
      restaurantIds: _favoriteRestaurantIds,
    );
  }

  /// Lấy danh sách địa điểm thuộc tỉnh đang chọn (hoặc Toàn quốc nếu isNationalMode)
  List<DestinationModel> get destinationsForSelectedProvince => isNationalMode
      ? _allDestinations
      : _allDestinations
          .where((d) => d.provinceId == _selectedProvince.id)
          .toList();

  List<DestinationModel> get featuredDestinations => isNationalMode
      ? _allDestinations.where((d) => d.isFeatured).toList()
      : destinationsForSelectedProvince.where((d) => d.isFeatured).toList();

  List<LocalFoodModel> get localFoodsForSelectedProvince {
    if (isNationalMode) return _allLocalFoods;
    final list = _allLocalFoods
        .where((f) => f.provinceId == _selectedProvince.id)
        .toList();
    return list.isNotEmpty ? list : _allLocalFoods;
  }

  List<RestaurantModel> get restaurantsForSelectedProvince {
    if (isNationalMode) return _allRestaurants;
    final list = _allRestaurants
        .where((r) => r.provinceId == _selectedProvince.id)
        .toList();
    return list.isNotEmpty ? list : _allRestaurants;
  }

  /// Danh sách dịch vụ Super App cho chế độ hiển thị Toàn Quốc hoặc Tỉnh thành
  List<HotelModel> get hotelsForDisplay => isNationalMode
      ? MockDataRepository.hotels
      : MockDataRepository.hotels
          .where((h) => h.provinceId == _selectedProvince.id)
          .toList();

  List<TourModel> get toursForDisplay => isNationalMode
      ? MockDataRepository.tours
      : MockDataRepository.tours
          .where((t) => t.provinceId == _selectedProvince.id || t.provinceId == 0)
          .toList();

  List<TransportTicketModel> get transportTicketsForDisplay =>
      MockDataRepository.transportTickets;

  List<BikerPOIModel> get bikerPOIsForDisplay =>
      MockDataRepository.bikerPOIs;

  /// Quản lý danh sách Booking cá nhân
  final List<HotelBookingRecord> _hotelBookings = [];
  final List<TransportBookingRecord> _transportBookings = [];
  final List<TourBookingRecord> _tourBookings = [];

  List<HotelBookingRecord> get hotelBookings => _hotelBookings;
  List<TransportBookingRecord> get transportBookings => _transportBookings;
  List<TourBookingRecord> get tourBookings => _tourBookings;

  void bookHotel(HotelBookingRecord record) {
    _hotelBookings.insert(0, record);
    notifyListeners();
  }

  void bookTransport(TransportBookingRecord record) {
    _transportBookings.insert(0, record);
    notifyListeners();
  }

  void bookTour(TourBookingRecord record) {
    _tourBookings.insert(0, record);
    notifyListeners();
  }

  void selectNational() {
    _selectedProvince = MockDataRepository.vietnamAll;
    notifyListeners();
  }

  /// Lọc và tìm kiếm quán ăn nâng cao theo rating, số lượng review, món đặc trưng và nội dung bình luận
  List<RestaurantModel> filterRestaurants({
    String query = '',
    String filterType = 'all',
    double? minRating,
    int? minReviews,
  }) {
    var list = isNationalMode
        ? List<RestaurantModel>.from(_allRestaurants)
        : List<RestaurantModel>.from(restaurantsForSelectedProvince);
    final q = query.trim();

    if (q.isNotEmpty) {
      list = list.where((r) {
        final inName = VietnameseUtils.matches(r.name, q);
        final inCuisine = VietnameseUtils.matches(r.cuisineType, q);
        final inAddress = VietnameseUtils.matches(r.address, q);
        final inSpecialties = VietnameseUtils.matches(r.specialties, q) ||
            VietnameseUtils.matches(r.specialtyDishes, q);
        final inReviews =
            r.sampleReviews.any((rev) => VietnameseUtils.matches(rev.text, q));
        return inName || inCuisine || inAddress || inSpecialties || inReviews;
      }).toList();
    }

    if (minRating != null) {
      list = list.where((r) => r.rating >= minRating).toList();
    }

    if (minReviews != null) {
      list = list.where((r) => r.reviewsCount >= minReviews).toList();
    }

    switch (filterType) {
      case 'high_rated':
        list = list.where((r) => r.isHighRated || r.rating >= 4.5).toList();
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'most_reviewed':
        list.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
        break;
      case 'specialty':
        list = list.where((r) => r.specialties.isNotEmpty).toList();
        break;
      default:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return list;
  }

  List<ItineraryModel> get sampleItinerariesForSelectedProvince {
    if (isNationalMode) return _sampleItineraries;
    final list = _sampleItineraries
        .where((i) => i.provinceId == _selectedProvince.id)
        .toList();
    return list.isNotEmpty ? list : _sampleItineraries;
  }

  List<String> get availableRegions => MockDataRepository.regions;

  List<ProvinceModel> filterProvinces({
    String region = 'Tất cả',
    String query = '',
  }) {
    final cleanQuery = query.trim();
    return _provinces.where((prov) {
      final matchesRegion =
          region == 'Tất cả' || region.isEmpty || prov.region == region;
      if (!matchesRegion) return false;
      if (cleanQuery.isEmpty) return true;
      return VietnameseUtils.matches(prov.name, cleanQuery) ||
          VietnameseUtils.matches(prov.code, cleanQuery) ||
          VietnameseUtils.matches(prov.region, cleanQuery) ||
          VietnameseUtils.matches(prov.description, cleanQuery);
    }).toList();
  }

  List<DestinationModel> get allDestinations => _allDestinations;
  List<LocalFoodModel> get allLocalFoods => _allLocalFoods;
  List<RestaurantModel> get allRestaurants => _allRestaurants;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void selectProvince(ProvinceModel? province) {
    if (province == null || province.id == 0) {
      _selectedProvince = MockDataRepository.vietnamAll;
    } else {
      _selectedProvince = province;
    }
    notifyListeners();
  }

  void selectActiveItinerary(int index) {
    if (index >= 0 && index < _userItineraries.length) {
      _activeItineraryIndex = index;
      notifyListeners();
    }
  }

  /// Đồng bộ dữ liệu mới nhất từ Backend FastAPI qua Dio + đẩy lịch trình Offline lên Server
  Future<void> syncFromBackend() async {
    if (_isOfflineSimulated) return;
    _isLoading = true;
    notifyListeners();
    try {
      await syncPendingOfflineItineraries();
      final results = await Future.wait([
        apiClient.fetchProvinces(),
        apiClient.fetchDestinations(),
        apiClient.fetchLocalFoods(),
        apiClient.fetchRestaurants(),
        apiClient.fetchSampleItineraries(),
      ]);
      _provinces = results[0] as List<ProvinceModel>;
      _allDestinations = results[1] as List<DestinationModel>;
      _allLocalFoods = results[2] as List<LocalFoodModel>;
      _allRestaurants = results[3] as List<RestaurantModel>;
      _sampleItineraries = results[4] as List<ItineraryModel>;

      if (_selectedProvince.id != 0) {
        final currentProv = _provinces.where((p) => p.id == _selectedProvince.id);
        if (currentProv.isNotEmpty) {
          _selectedProvince = currentProv.first;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tự động đồng bộ các Lịch trình được tạo/chỉnh sửa khi Offline lên Backend (`POST /api/v1/itineraries/sync`)
  Future<int> syncPendingOfflineItineraries() async {
    if (_isOfflineSimulated) return 0;
    int syncedCount = 0;
    for (int i = 0; i < _userItineraries.length; i++) {
      final item = _userItineraries[i];
      if (!item.isSyncedWithServer) {
        await apiClient.syncItineraryToBackend(item);
        _userItineraries[i] = item.copyWith(isSyncedWithServer: true);
        syncedCount++;
      }
    }
    if (syncedCount > 0) {
      await _persistItinerariesToHive();
      notifyListeners();
    }
    return syncedCount;
  }

  /// Bật / tắt mô phỏng chế độ mất mạng (Offline-first / Hive Cache) để kiểm thử TC-06 & TC-09
  void toggleOfflineSimulation(bool value) {
    _isOfflineSimulated = value;
    if (!value) {
      syncPendingOfflineItineraries();
    }
    notifyListeners();
  }

  /// Bật / tắt quyền vị trí để kiểm thử TC-09 (Ứng dụng vẫn hoạt động đầy đủ khi từ chối quyền vị trí)
  void setLocationPermission(LocationPermissionState state) {
    _locationPermission = state;
    notifyListeners();
  }

  /// Quản lý Yêu thích (Lưu bền vững vào Hive)
  bool isDestinationFavorite(int id) => _favoriteDestinationIds.contains(id);
  bool isFoodFavorite(int id) => _favoriteFoodIds.contains(id);
  bool isRestaurantFavorite(int id) => _favoriteRestaurantIds.contains(id);

  void toggleDestinationFavorite(int id) {
    if (_favoriteDestinationIds.contains(id)) {
      _favoriteDestinationIds.remove(id);
    } else {
      _favoriteDestinationIds.add(id);
    }
    _persistFavoritesToHive();
    notifyListeners();
  }

  void toggleFoodFavorite(int id) {
    if (_favoriteFoodIds.contains(id)) {
      _favoriteFoodIds.remove(id);
    } else {
      _favoriteFoodIds.add(id);
    }
    _persistFavoritesToHive();
    notifyListeners();
  }

  void toggleRestaurantFavorite(int id) {
    if (_favoriteRestaurantIds.contains(id)) {
      _favoriteRestaurantIds.remove(id);
    } else {
      _favoriteRestaurantIds.add(id);
    }
    _persistFavoritesToHive();
    notifyListeners();
  }

  /// Quản lý Lịch trình Offline-first: Ghi ngay vào Hive Box (`tripflow_itineraries`)
  void createNewItinerary({
    required String title,
    required String description,
    int totalDays = 1,
  }) {
    final newItin = ItineraryModel(
      id: DateTime.now().millisecondsSinceEpoch,
      provinceId: _selectedProvince.id,
      provinceName: _selectedProvince.name,
      title: title,
      description: description,
      totalDays: totalDays,
      isTemplate: false,
      isSyncedWithServer: !_isOfflineSimulated,
      stops: const [],
    );
    _userItineraries.insert(0, newItin);
    _activeItineraryIndex = 0;
    _persistItinerariesToHive();
    if (!_isOfflineSimulated) {
      apiClient.syncItineraryToBackend(newItin);
    }
    notifyListeners();
  }

  void applyTemplateToMyItinerary(ItineraryModel template) {
    final clonedStops = template.stops
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(
            id: DateTime.now().millisecondsSinceEpoch + entry.key,
            stopOrder: entry.key + 1,
          ),
        )
        .toList();

    final created = ItineraryModel(
      id: DateTime.now().millisecondsSinceEpoch,
      provinceId: template.provinceId,
      provinceName: template.provinceName,
      title: '${template.title} (Bản sao của tôi)',
      description: template.description,
      totalDays: template.totalDays,
      isTemplate: false,
      isSyncedWithServer: !_isOfflineSimulated,
      stops: clonedStops,
    );
    _userItineraries.insert(0, created);
    _activeItineraryIndex = 0;
    _persistItinerariesToHive();
    if (!_isOfflineSimulated) {
      apiClient.syncItineraryToBackend(created);
    }
    notifyListeners();
  }

  /// Lưu trực tiếp một Lịch trình thông minh (Smart Itinerary) do Engine tự động sinh ra
  void saveNewItinerary(ItineraryModel itinerary) {
    _userItineraries.insert(0, itinerary);
    _activeItineraryIndex = 0;
    _persistItinerariesToHive();
    if (!_isOfflineSimulated) {
      apiClient.syncItineraryToBackend(itinerary);
    }
    notifyListeners();
  }

  void addDestinationToActiveItinerary(
    DestinationModel dest, {
    String plannedTime = '09:00 - 10:30',
    String? notes,
  }) {
    final current = activeItinerary;
    final nextOrder = current.stops.length + 1;
    final newStop = ItineraryStopModel(
      id: DateTime.now().millisecondsSinceEpoch,
      dayNumber: 1,
      stopOrder: nextOrder,
      stopType: 'destination',
      referenceId: dest.id,
      title: dest.name,
      address: dest.address,
      latitude: dest.latitude,
      longitude: dest.longitude,
      plannedTime: plannedTime,
      durationMins: dest.recommendedDurationMins,
      notes: notes ?? 'Tham quan địa điểm du lịch tại ${dest.provinceName}',
    );
    final updatedStops = [...current.stops, newStop];
    final updatedItin = current.copyWith(
      stops: updatedStops,
      isSyncedWithServer: !_isOfflineSimulated,
    );
    _userItineraries[_activeItineraryIndex] = updatedItin;
    _persistItinerariesToHive();
    if (!_isOfflineSimulated) {
      apiClient.syncItineraryToBackend(updatedItin);
    }
    notifyListeners();
  }

  void addRestaurantToActiveItinerary(
    RestaurantModel rest, {
    String plannedTime = '12:00 - 13:15',
    String? notes,
  }) {
    final current = activeItinerary;
    final nextOrder = current.stops.length + 1;
    final newStop = ItineraryStopModel(
      id: DateTime.now().millisecondsSinceEpoch,
      dayNumber: 1,
      stopOrder: nextOrder,
      stopType: 'restaurant',
      referenceId: rest.id,
      title: rest.name,
      address: rest.address,
      latitude: rest.latitude,
      longitude: rest.longitude,
      plannedTime: plannedTime,
      durationMins: 75,
      notes: notes ?? 'Điểm dừng thưởng thức ${rest.cuisineType} trên lộ trình',
    );
    final updatedStops = [...current.stops, newStop];
    final updatedItin = current.copyWith(
      stops: updatedStops,
      isSyncedWithServer: !_isOfflineSimulated,
    );
    _userItineraries[_activeItineraryIndex] = updatedItin;
    _persistItinerariesToHive();
    if (!_isOfflineSimulated) {
      apiClient.syncItineraryToBackend(updatedItin);
    }
    notifyListeners();
  }

  /// Gợi ý và chèn điểm dừng ăn uống thông minh (Smart Meal Stop) vào ngày chỉ định
  void addSmartMealStop({
    required RestaurantModel restaurant,
    int dayNumber = 1,
    String preferredTime = '12:00 - 13:00',
    String? reasoning,
  }) {
    final current = activeItinerary;
    final dayStops =
        current.stops.where((s) => s.dayNumber == dayNumber).toList();
    final insertOrder = dayStops.length >= 2 ? 2 : dayStops.length + 1;

    final newStop = ItineraryStopModel(
      id: DateTime.now().millisecondsSinceEpoch,
      dayNumber: dayNumber,
      stopOrder: insertOrder,
      stopType: 'meal',
      referenceId: restaurant.id,
      title: 'Dừng ăn trưa: ${restaurant.name}',
      address: restaurant.address,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      plannedTime: preferredTime,
      durationMins: 60,
      notes: reasoning ??
          'Quán ăn được đánh giá cao (${restaurant.rating}⭐, ${restaurant.reviewsCount}+ đánh giá). Món ngon: ${restaurant.specialties.isNotEmpty ? restaurant.specialties : restaurant.specialtyDishes}',
    );

    final newStops = <ItineraryStopModel>[];
    for (final s in current.stops) {
      if (s.dayNumber == dayNumber && s.stopOrder >= insertOrder) {
        newStops.add(s.copyWith(stopOrder: s.stopOrder + 1));
      } else {
        newStops.add(s);
      }
    }
    newStops.add(newStop);
    newStops.sort((a, b) {
      final dayCmp = a.dayNumber.compareTo(b.dayNumber);
      if (dayCmp != 0) return dayCmp;
      return a.stopOrder.compareTo(b.stopOrder);
    });

    final updatedItin = current.copyWith(
      stops: newStops,
      isSyncedWithServer: !_isOfflineSimulated,
    );
    _userItineraries[_activeItineraryIndex] = updatedItin;
    _persistItinerariesToHive();
    if (!_isOfflineSimulated) {
      apiClient.syncItineraryToBackend(updatedItin);
    }
    notifyListeners();
  }

  void addCustomStopToActiveItinerary({
    required String title,
    required String address,
    required String plannedTime,
    required String stopType,
    String notes = '',
  }) {
    final current = activeItinerary;
    final nextOrder = current.stops.length + 1;
    final newStop = ItineraryStopModel(
      id: DateTime.now().millisecondsSinceEpoch,
      dayNumber: 1,
      stopOrder: nextOrder,
      stopType: stopType,
      title: title,
      address: address,
      latitude: _selectedProvince.centerLat,
      longitude: _selectedProvince.centerLng,
      plannedTime: plannedTime,
      durationMins: 60,
      notes: notes,
    );
    final updatedStops = [...current.stops, newStop];
    final updatedItin = current.copyWith(
      stops: updatedStops,
      isSyncedWithServer: !_isOfflineSimulated,
    );
    _userItineraries[_activeItineraryIndex] = updatedItin;
    _persistItinerariesToHive();
    if (!_isOfflineSimulated) {
      apiClient.syncItineraryToBackend(updatedItin);
    }
    notifyListeners();
  }

  void removeStopFromActiveItinerary(int index) {
    final current = activeItinerary;
    if (index < 0 || index >= current.stops.length) return;
    final updated = List<ItineraryStopModel>.from(current.stops)
      ..removeAt(index);
    final normalized = updated
        .asMap()
        .entries
        .map((e) => e.value.copyWith(stopOrder: e.key + 1))
        .toList();
    final updatedItin = current.copyWith(
      stops: normalized,
      isSyncedWithServer: !_isOfflineSimulated,
    );
    _userItineraries[_activeItineraryIndex] = updatedItin;
    _persistItinerariesToHive();
    notifyListeners();
  }

  void reorderStopInActiveItinerary(int oldIndex, int newIndex) {
    final current = activeItinerary;
    final list = List<ItineraryStopModel>.from(current.stops);
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (newIndex < 0 || newIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    final normalized = list
        .asMap()
        .entries
        .map((e) => e.value.copyWith(stopOrder: e.key + 1))
        .toList();
    final updatedItin = current.copyWith(
      stops: normalized,
      isSyncedWithServer: !_isOfflineSimulated,
    );
    _userItineraries[_activeItineraryIndex] = updatedItin;
    _persistItinerariesToHive();
    notifyListeners();
  }

  void moveStopStep(int index, int delta) {
    final current = activeItinerary;
    final target = index + delta;
    if (target < 0 || target >= current.stops.length) return;
    final list = List<ItineraryStopModel>.from(current.stops);
    final temp = list[index];
    list[index] = list[target];
    list[target] = temp;
    final normalized = list
        .asMap()
        .entries
        .map((e) => e.value.copyWith(stopOrder: e.key + 1))
        .toList();
    final updatedItin = current.copyWith(
      stops: normalized,
      isSyncedWithServer: !_isOfflineSimulated,
    );
    _userItineraries[_activeItineraryIndex] = updatedItin;
    _persistItinerariesToHive();
    notifyListeners();
  }

  /// Gửi báo cáo sai thông tin (Mục 11)
  Future<void> submitReport({
    required String targetType,
    required int targetId,
    required String targetName,
    required String issueType,
    required String description,
  }) async {
    await apiClient.submitContentReport(
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      issueType: issueType,
      description: description,
    );
    _submittedReports.insert(
      0,
      ContentReportRecord(
        id: DateTime.now().millisecondsSinceEpoch,
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        issueType: issueType,
        description: description,
        status: 'pending',
        createdAt: 'Vừa gửi',
      ),
    );
    notifyListeners();
  }

  /// Gửi mã xác thực OTP qua SMS
  Future<Map<String, dynamic>> sendPhoneOtp({
    required String phone,
    String? fullName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await apiClient.sendSmsOtp(
        phone: phone,
        fullName: fullName,
      );
      return res;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xác thực mã OTP, kích hoạt đăng nhập và lưu session vào Hive Cache
  Future<Map<String, dynamic>> verifyOtpAndLogin({
    required String phone,
    required String otpCode,
    String? fullName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await apiClient.verifySmsOtp(
        phone: phone,
        otpCode: otpCode,
        fullName: fullName,
      );
      if (res['success'] == true) {
        _isLoggedIn = true;
        _userPhone = phone;
        _isOtpVerified = true;
        _userEmail = '$phone@tripflow.vn';
        final userMap = res['user'] as Map<String, dynamic>?;
        if (userMap != null &&
            userMap['full_name'] != null &&
            userMap['full_name'].toString().isNotEmpty) {
          _userName = userMap['full_name'].toString();
        } else if (fullName != null && fullName.isNotEmpty) {
          _userName = fullName;
        } else {
          _userName =
              'Du khách ${phone.length >= 4 ? phone.substring(phone.length - 4) : phone}';
        }
        _authToken = res['access_token']?.toString() ?? '';
        await cacheService.saveUserAuthSession(
          phone: _userPhone,
          fullName: _userName,
          isOtpVerified: _isOtpVerified,
          token: _authToken,
        );
      }
      return res;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đăng nhập / Đăng xuất người dùng
  void loginUser({
    required String email,
    required String fullName,
    String? phone,
    bool isOtpVerified = false,
  }) {
    _isLoggedIn = true;
    _userEmail = email;
    _userName = fullName;
    if (phone != null) _userPhone = phone;
    _isOtpVerified = isOtpVerified;
    cacheService.saveUserAuthSession(
      phone: _userPhone,
      fullName: _userName,
      isOtpVerified: _isOtpVerified,
      token: _authToken,
    );
    notifyListeners();
  }

  void logoutUser() {
    _isLoggedIn = false;
    _userEmail = '';
    _userPhone = '';
    _isOtpVerified = false;
    _authToken = '';
    _userName = 'Khách du lịch (Guest Mode)';
    apiClient.authToken = null;
    cacheService.clearUserAuthSession();
    notifyListeners();
  }
}
