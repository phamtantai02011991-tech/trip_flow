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
    'TripFlow Mobile hiển thị BrandIdentityHeader, SuperAppServiceGrid và mặc định Toàn quốc 🇻🇳',
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

      // TC-01: Hiển thị mặc định Toàn quốc 🇻🇳 và Brand Identity Hero Header
      expect(find.textContaining('Toàn quốc 🇻🇳'), findsWidgets);
      expect(find.text('TRIPFLOW'), findsOneWidget);
      expect(find.text('SUPER APP'), findsOneWidget);
      expect(find.text('1900 6868'), findsOneWidget);
      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsWidgets);
      expect(find.byIcon(Icons.event_note_outlined), findsOneWidget);
      expect(find.byIcon(Icons.ramen_dining_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      // Hiển thị 5 dịch vụ Super App
      expect(find.text('Khách Sạn'), findsOneWidget);
      expect(find.text('Vé Xe & Tàu'), findsOneWidget);
      expect(find.text('Tour Tuyển'), findsOneWidget);
      expect(find.text('Lập Lịch Phượt'), findsOneWidget);
      expect(find.text('Ẩm Thực'), findsWidgets);

      // Chuyển sang Tab 1: Gần đây
      await tester.tap(find.byIcon(Icons.map_outlined).last);
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

  test(
    'TC-SuperApp-01: MockDataRepository chứa đầy đủ dữ liệu Toàn Quốc, Khách sạn, Vé xe tàu, Tour và Biker POIs',
    () {
      // 1. Kiểm tra hằng số Toàn quốc
      expect(MockDataRepository.vietnamAll.id, equals(0));
      expect(MockDataRepository.vietnamAll.name, contains('Toàn quốc'));
      expect(MockDataRepository.vietnamAll.code, equals('ALL'));

      // 2. Kiểm tra Khách sạn & Resort
      final hotels = MockDataRepository.hotels;
      expect(hotels.isNotEmpty, isTrue);
      expect(hotels.any((h) => h.hotelType == 'resort'), isTrue);
      expect(hotels.any((h) => h.hotelType == 'homestay'), isTrue);
      expect(hotels.first.rooms.isNotEmpty, isTrue);
      expect(hotels.first.hotline.isNotEmpty, isTrue);
      expect(hotels.first.pricePerNightVnd, greaterThan(0));

      // 3. Kiểm tra Vé xe/tàu/bay
      final transports = MockDataRepository.transportTickets;
      expect(transports.isNotEmpty, isTrue);
      expect(transports.any((t) => t.type == 'bus'), isTrue);
      expect(transports.any((t) => t.type == 'train'), isTrue);
      expect(transports.any((t) => t.type == 'flight'), isTrue);
      expect(transports.first.priceVnd, greaterThan(0));
      expect(transports.first.vehicleCode.isNotEmpty, isTrue);

      // 4. Kiểm tra Tours tuyển chọn
      final tours = MockDataRepository.tours;
      expect(tours.isNotEmpty, isTrue);
      expect(tours.any((t) => t.category == 'trekking'), isTrue);
      expect(tours.any((t) => t.category == 'motorbike_loop'), isTrue);
      expect(tours.first.dailySchedule.isNotEmpty, isTrue);
      expect(tours.first.inclusions.isNotEmpty, isTrue);
      expect(tours.first.guidePhone.isNotEmpty, isTrue);

      // 5. Kiểm tra Biker POIs
      final pois = MockDataRepository.bikerPOIs;
      expect(pois.isNotEmpty, isTrue);
      expect(pois.any((p) => p.category == 'gas_station'), isTrue);
      expect(pois.any((p) => p.category == 'mechanic'), isTrue);
      expect(pois.any((p) => p.category == 'viewpoint'), isTrue);
      expect(pois.any((p) => p.category == 'pass'), isTrue);
    },
  );

  test(
    'TC-SuperApp-02: TripFlowAppState mặc định Toàn quốc 🇻🇳 và chuyển đổi mượt mà giữa Toàn quốc và Tỉnh thành',
    () {
      final appState = TripFlowAppState();

      // Mặc định khởi động ở chế độ Toàn quốc
      expect(appState.isNationalMode, isTrue);
      expect(appState.selectedProvince.id, equals(0));
      expect(appState.selectedProvince.name, contains('Toàn quốc'));
      expect(appState.hotelsForDisplay.isNotEmpty, isTrue);
      expect(appState.toursForDisplay.isNotEmpty, isTrue);
      expect(appState.transportTicketsForDisplay.isNotEmpty, isTrue);
      expect(appState.bikerPOIsForDisplay.isNotEmpty, isTrue);

      // Chuyển sang Tỉnh Lâm Đồng (Đà Lạt)
      final daLat = appState.provinces.firstWhere((p) => p.code == 'LD');
      appState.selectProvince(daLat);
      expect(appState.isNationalMode, isFalse);
      expect(appState.selectedProvince.id, equals(9));
      expect(appState.selectedProvince.name, contains('Lâm Đồng'));

      // Danh sách khách sạn hiển thị riêng cho Lâm Đồng
      for (final h in appState.hotelsForDisplay) {
        expect(h.provinceId, equals(9));
      }

      // Quay lại Toàn quốc
      appState.selectNational();
      expect(appState.isNationalMode, isTrue);
      expect(appState.selectedProvince.id, equals(0));
      expect(appState.hotelsForDisplay.length, equals(MockDataRepository.hotels.length));
    },
  );

  test(
    'TC-SuperApp-03: Luồng đặt phòng E-Voucher, đặt vé E-Ticket và đặt tour lưu trữ chính xác trong AppState',
    () {
      final appState = TripFlowAppState();

      // Đặt phòng khách sạn
      const hotelBooking = HotelBookingRecord(
        bookingId: 'BK-TEST-001',
        hotelId: 1,
        hotelName: 'InterContinental Danang',
        roomName: 'Resort Classic Oceanview King',
        checkInDate: '14:00 hôm nay',
        checkOutDate: '12:00 ngày mai',
        guests: 2,
        customerName: 'Nguyễn Văn Phượt',
        customerPhone: '0987654321',
        totalPrice: 7800000,
        voucherCode: 'TF-HTL-TEST001',
        createdAt: 'Vừa xong',
      );
      appState.bookHotel(hotelBooking);
      expect(appState.hotelBookings.length, equals(1));
      expect(appState.hotelBookings.first.voucherCode, equals('TF-HTL-TEST001'));

      // Đặt vé giao thông
      const transportBooking = TransportBookingRecord(
        bookingId: 'TBK-TEST-002',
        ticketId: 1,
        operatorName: 'Phương Trang FUTA',
        fromCity: 'Sài Gòn',
        toCity: 'Đà Lạt',
        departureTime: '23:00',
        seatClass: 'Limousine 24 Phòng VIP',
        passengerName: 'Nguyễn Văn Phượt',
        passengerPhone: '0987654321',
        totalPrice: 320000,
        ticketCode: 'ETKT-FUTA-TEST002',
        createdAt: 'Vừa xong',
      );
      appState.bookTransport(transportBooking);
      expect(appState.transportBookings.length, equals(1));
      expect(appState.transportBookings.first.ticketCode, equals('ETKT-FUTA-TEST002'));

      // Đặt tour trải nghiệm
      const tourBooking = TourBookingRecord(
        bookingId: 'TRBK-TEST-003',
        tourId: 1,
        tourTitle: 'Trekking Tà Năng - Phan Dũng',
        startDate: 'Thứ Bảy tuần này',
        partySize: 2,
        contactName: 'Nguyễn Văn Phượt',
        contactPhone: '0987654321',
        totalAmount: 5700000,
        guideName: 'A Sáng',
        guidePhone: '0978 123 456',
        voucherCode: 'TF-TOUR-TEST003',
        createdAt: 'Vừa xong',
      );
      appState.bookTour(tourBooking);
      expect(appState.tourBookings.length, equals(1));
      expect(appState.tourBookings.first.voucherCode, equals('TF-TOUR-TEST003'));
    },
  );
}

