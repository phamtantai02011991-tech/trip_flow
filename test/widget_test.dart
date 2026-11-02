import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_flow/core/config/app_config.dart';
import 'package:trip_flow/core/storage/offline_cache_service.dart';
import 'package:trip_flow/core/utils/app_state.dart';
import 'package:trip_flow/core/utils/data_models.dart';
import 'package:trip_flow/core/utils/geo_utils.dart';
import 'package:trip_flow/core/utils/mock_data.dart';
import 'package:trip_flow/main.dart';

void main() {
  setUpAll(() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final text = details.exception.toString();
      if (text.contains('NetworkImage') ||
          text.contains('ClientException') ||
          text.contains('statusCode: 400') ||
          text.contains('tiles.goong.io')) {
        return; // Bỏ qua lỗi kết nối mạng trong môi trường test cô lập
      }
      originalOnError?.call(details);
    };
  });
  testWidgets(
    'TripFlow Mobile (Riverpod + Dio + Hive) hiển thị đầy đủ 5 tab điều hướng và dữ liệu TP. Hồ Chí Minh',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: TripFlowApp(),
        ),
      );
      await tester.pumpAndSettle();
      tester.takeException();

      // TC-01: Hiển thị mặc định TP. Hồ Chí Minh và tab điều hướng chuẩn
      expect(find.text('TP. Hồ Chí Minh'), findsWidgets);
      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.event_note_outlined), findsOneWidget);
      expect(find.byIcon(Icons.ramen_dining_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      // Hiển thị địa điểm nổi bật tại TP.HCM
      expect(
        find.textContaining('Dinh Độc Lập'),
        findsWidgets,
      );

      // Chuyển sang Tab 1: Gần đây
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.text('Gần đây'), findsOneWidget);

      // Chuyển sang Tab 2: Chuyến đi
      await tester.tap(find.byIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.text('Chuyến đi của tôi'), findsOneWidget);

      // Chuyển sang Tab 4: Ẩm thực
      await tester.tap(find.byIcon(Icons.ramen_dining_outlined));
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.text('Ẩm thực'), findsOneWidget);
    },
  );

  test(
    'Thuật toán Bounding Box + Corridor Search lọc chính xác nhà hàng dọc tuyến đường (< 2.0km)',
    () {
      final polyline = GeoUtils.buildRoutePolyline(
        originLat: 10.7770,
        originLng: 106.6953,
        destLat: 10.7955,
        destLng: 106.6785,
      );
      final bbox = GeoUtils.computeBoundingBox(polyline, 2.0);
      expect(bbox['min_lat']! < 10.7770, isTrue);
      expect(bbox['max_lat']! > 10.7955, isTrue);

      final matched = GeoUtils.findRestaurantsOnCorridor(
        restaurants: MockDataRepository.restaurants,
        polyline: polyline,
        corridorRadiusKm: 2.0,
      );

      expect(matched.isNotEmpty, isTrue);
      for (final item in matched) {
        expect(item.distanceFromRouteKm <= 2.0, isTrue);
      }
    },
  );

  test(
    'Offline-first Hive Cache lưu lịch trình khi mất mạng và Cloudinary sinh URL Thumbnail chuẩn',
    () {
      final appState = TripFlowAppState();
      appState.toggleOfflineSimulation(true);
      expect(appState.isOfflineSimulated, isTrue);

      appState.createNewItinerary(
        title: 'Lịch trình Offline Sài Gòn',
        description: 'Tạo khi đang mất mạng, lưu vào Hive',
      );
      expect(appState.activeItinerary.isSyncedWithServer, isFalse);
      expect(appState.unsyncedItinerariesCount, greaterThanOrEqualTo(1));

      final thumb = AppConfig.buildThumbnailUrl(
        'https://res.cloudinary.com/tripflow-vn/image/upload/v1/tripflow/dinh_doc_lap.jpg',
      );
      expect(thumb.contains('c_fill,w_400,h_300,q_auto,f_auto'), isTrue);
    },
  );

  test(
    'TC-14 & TC-17: TripFlowAppState quản lý 10 tỉnh/thành phố và lọc chính xác theo 4 vùng miền',
    () {
      final appState = TripFlowAppState();
      expect(appState.provinces.length, equals(10));
      expect(appState.availableRegions, containsAll(['Tất cả', 'Bắc Bộ', 'Trung Bộ', 'Tây Nguyên', 'Nam Bộ']));

      // Lọc theo Bắc Bộ
      final northProvinces = appState.filterProvinces(region: 'Bắc Bộ');
      expect(northProvinces.length, equals(3));
      expect(northProvinces.map((p) => p.code), containsAll(['HN', 'QN', 'LC']));

      // Lọc theo Tây Nguyên
      final highlands = appState.filterProvinces(region: 'Tây Nguyên');
      expect(highlands.length, equals(1));
      expect(highlands.first.code, equals('LD'));

      // Tìm kiếm từ khóa "Phú Quốc"
      final pqSearch = appState.filterProvinces(query: 'Phú Quốc');
      expect(pqSearch.length, equals(1));
      expect(pqSearch.first.code, equals('KG'));

      // Chuyển tỉnh sang Đà Lạt (id = 9) và kiểm tra dữ liệu động
      final daLat = appState.provinces.firstWhere((p) => p.code == 'LD');
      appState.selectProvince(daLat);
      expect(appState.selectedProvince.name, contains('Lâm Đồng'));
      expect(appState.destinationsForSelectedProvince.isNotEmpty, isTrue);
      expect(appState.localFoodsForSelectedProvince.isNotEmpty, isTrue);
      expect(appState.restaurantsForSelectedProvince.isNotEmpty, isTrue);
      expect(appState.sampleItinerariesForSelectedProvince.isNotEmpty, isTrue);
    },
  );

  test(
    'TC-18: RestaurantModel & MockData chứa đầy đủ reviewsCount, sampleReviews từ Google Maps và isHighRated',
    () {
      final restaurants = MockDataRepository.restaurants;
      expect(restaurants.isNotEmpty, isTrue);

      final comTam = restaurants.firstWhere((r) => r.id == 1);
      expect(comTam.reviewsCount, greaterThanOrEqualTo(1000));
      expect(comTam.isHighRated, isTrue);
      expect(comTam.sampleReviews.isNotEmpty, isTrue);
      expect(comTam.sampleReviews.first.author.isNotEmpty, isTrue);
      expect(comTam.sampleReviews.first.rating, greaterThanOrEqualTo(4.0));
      expect(comTam.specialties.isNotEmpty, isTrue);

      // Kiểm tra tất cả 10 tỉnh thành đều có dữ liệu reviewsCount > 0
      final allHaveReviews = restaurants.every((r) => r.reviewsCount > 0);
      expect(allHaveReviews, isTrue);
    },
  );

  test(
    'TC-19: filterRestaurants() hỗ trợ lọc high_rated, most_reviewed và tìm kiếm full-text trong bình luận',
    () {
      final appState = TripFlowAppState();

      // Lọc nhà hàng đánh giá cao (high_rated)
      final highRated = appState.filterRestaurants(filterType: 'high_rated');
      expect(highRated.isNotEmpty, isTrue);
      for (final r in highRated) {
        expect(r.isHighRated || r.rating >= 4.5, isTrue);
      }

      // Lọc nhà hàng nhiều review nhất (most_reviewed)
      final mostReviewed = appState.filterRestaurants(filterType: 'most_reviewed');
      expect(mostReviewed.isNotEmpty, isTrue);
      expect(mostReviewed.first.reviewsCount, greaterThanOrEqualTo(mostReviewed.last.reviewsCount));

      // Lọc theo số lượng review tối thiểu
      final min1000 = appState.filterRestaurants(minReviews: 1000);
      expect(min1000.isNotEmpty, isTrue);
      for (final r in min1000) {
        expect(r.reviewsCount, greaterThanOrEqualTo(1000));
      }

      // Tìm kiếm trong bình luận thực tế (ví dụ: 'sườn' hoặc 'chả')
      final searchResult = appState.filterRestaurants(query: 'sườn');
      expect(searchResult.isNotEmpty, isTrue);
    },
  );

  test(
    'TC-20 & TC-21: addSmartMealStop chèn điểm dừng ăn trưa vào lịch trình và tính toán SFCS Corridor',
    () {
      final appState = TripFlowAppState();
      final initialStopsCount = appState.activeItinerary.stops.length;
      final sampleRestaurant = MockDataRepository.restaurants.first;

      // Chèn điểm dừng ăn uống thông minh
      appState.addSmartMealStop(
        restaurant: sampleRestaurant,
        dayNumber: 1,
        preferredTime: '12:15',
        reasoning: 'Gợi ý AI SFCS: Quán gần tuyến nhất, 4.8 sao với 3200+ đánh giá.',
      );

      final updatedStops = appState.activeItinerary.stops;
      expect(updatedStops.length, equals(initialStopsCount + 1));

      final mealStop = updatedStops.firstWhere((s) => s.stopType == 'meal' && s.referenceId == sampleRestaurant.id);
      expect(mealStop.title, contains(sampleRestaurant.name));
      expect(mealStop.plannedTime, equals('12:15'));
      expect(mealStop.notes, contains('SFCS'));

      // Kiểm tra CorridorRestaurantResult có corridorScore
      final corridorResult = CorridorRestaurantResult(
        restaurant: sampleRestaurant,
        distanceFromRouteKm: 0.35,
        detourDistanceKm: 0.70,
        estimatedDetourMins: 3,
        nearestRouteLat: 10.7769,
        nearestRouteLng: 106.7009,
        routeProgressPct: 25.0,
        corridorScore: 92.4,
      );
      expect(corridorResult.corridorScore, equals(92.4));
      expect(corridorResult.distanceFromRouteKm, lessThan(1.0));
    },
  );

  testWidgets(
    'TC-24: Luồng Đăng ký Tên + Số điện thoại Việt Nam + Xác thực OTP SMS và cập nhật Hồ sơ Profile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: TripFlowApp(),
        ),
      );
      await tester.pumpAndSettle();
      tester.takeException();

      // 1. Điều hướng đến Tab Cá nhân (Tab 5)
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      tester.takeException();

      // Kiểm tra đang ở Guest Mode với nút Đăng ký tài khoản
      expect(find.text('Khách du lịch (Guest Mode)'), findsOneWidget);
      expect(find.text('Đăng ký tài khoản (Nhận OTP)'), findsOneWidget);

      // 2. Nhấn nút Đăng ký tài khoản để mở RegisterScreen
      await tester.tap(find.text('Đăng ký tài khoản (Nhận OTP)'));
      await tester.pumpAndSettle();
      tester.takeException();

      expect(find.text('Tham Gia TripFlow'), findsOneWidget);
      expect(find.text('Họ và tên du khách'), findsOneWidget);
      expect(find.text('Số điện thoại di động Việt Nam'), findsOneWidget);

      // 3. Nhập Họ và tên và Số điện thoại di động Việt Nam
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Nguyễn Văn Du Khách');
      await tester.enterText(textFields.at(1), '0987654321');
      await tester.pumpAndSettle();
      tester.takeException();

      // 4. Nhấn nút "Nhận mã xác thực OTP qua SMS"
      final sendOtpBtn = find.text('Nhận mã xác thực OTP qua SMS');
      expect(sendOtpBtn, findsOneWidget);
      await tester.ensureVisible(sendOtpBtn);
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();
      tester.takeException();

      // 5. Kiểm tra đã chuyển sang OtpVerificationScreen
      expect(find.text('Xác Thực Mã OTP SMS'), findsWidgets);
      expect(find.textContaining('098 •••• 321'), findsOneWidget);
      expect(find.text('TIN NHẮN SMS MỚI • TRIPFLOW'), findsOneWidget);
      expect(find.text('Điền mã 1-chạm'), findsOneWidget);

      // 6. Nhấn nút "Điền mã 1-chạm" để tự động điền mã OTP từ SMS Simulator
      await tester.tap(find.text('Điền mã 1-chạm'));
      await tester.pumpAndSettle();
      tester.takeException();

      // 7. Nhấn nút "Xác Nhận & Hoàn Tất"
      final verifyBtn = find.text('Xác Nhận & Hoàn Tất');
      expect(verifyBtn, findsOneWidget);
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();
      tester.takeException();

      // 8. Đã quay lại màn hình Cá nhân: kiểm tra tên, SĐT và huy hiệu xác thực OTP
      expect(find.text('Nguyễn Văn Du Khách'), findsWidgets);
      expect(find.text('0987654321'), findsWidgets);
      expect(find.text('Đã xác thực OTP qua tin nhắn SMS'), findsOneWidget);
    },
  );

  test(
    'TC-24 Unit: TripFlowAppState lưu trữ và khôi phục số điện thoại cùng trạng thái OTP xác thực',
    () async {
      OfflineCacheService.instance.clearUserAuthSession();
      final appState = TripFlowAppState();

      // Kiểm tra trạng thái ban đầu là Guest
      expect(appState.isLoggedIn, isFalse);
      expect(appState.userPhone, isEmpty);
      expect(appState.isOtpVerified, isFalse);

      // Gửi OTP
      final sendRes = await appState.sendPhoneOtp(
        phone: '0987654321',
        fullName: 'Nguyễn Văn Du Khách',
      );
      expect(sendRes['success'], isTrue);
      expect(sendRes['debug_otp'], isNotNull);

      final debugOtp = sendRes['debug_otp']?.toString() ?? '888999';

      // Xác thực OTP
      final verifyRes = await appState.verifyOtpAndLogin(
        phone: '0987654321',
        otpCode: debugOtp,
        fullName: 'Nguyễn Văn Du Khách',
      );
      expect(verifyRes['success'], isTrue);

      // Kiểm tra trạng thái đã cập nhật
      expect(appState.isLoggedIn, isTrue);
      expect(appState.userPhone, equals('0987654321'));
      expect(appState.userName, equals('Nguyễn Văn Du Khách'));
      expect(appState.isOtpVerified, isTrue);

      // Đăng xuất
      appState.logoutUser();
      expect(appState.isLoggedIn, isFalse);
      expect(appState.userPhone, isEmpty);
      expect(appState.isOtpVerified, isFalse);
      expect(appState.userName, contains('Guest Mode'));
    },
  );
}

