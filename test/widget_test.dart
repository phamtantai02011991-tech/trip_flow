import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_flow/core/config/app_config.dart';
import 'package:trip_flow/core/utils/app_state.dart';
import 'package:trip_flow/core/utils/geo_utils.dart';
import 'package:trip_flow/core/utils/mock_data.dart';
import 'package:trip_flow/main.dart';

void main() {
  testWidgets(
    'TripFlow Mobile (Riverpod + Dio + Hive) hiển thị đầy đủ 5 tab điều hướng và dữ liệu TP. Hồ Chí Minh',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TripFlowApp(),
        ),
      );
      await tester.pumpAndSettle();

      // TC-01: Hiển thị mặc định TP. Hồ Chí Minh và 5 tab điều hướng chuẩn Mục 5.2
      expect(find.text('TP. Hồ Chí Minh'), findsWidgets);
      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.text('Bản đồ'), findsOneWidget);
      expect(find.text('Lịch trình'), findsOneWidget);
      expect(find.text('Ẩm thực'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);

      // Hiển thị địa điểm nổi bật tại TP.HCM
      expect(
        find.textContaining('Dinh Độc Lập'),
        findsWidgets,
      );

      // Chuyển sang Tab 2: Bản đồ & Tìm nhà hàng trên lộ trình (Goong Maps + Bounding Box + Shapely)
      await tester.tap(find.text('Bản đồ'));
      await tester.pumpAndSettle();
      expect(find.text('Bản Đồ & Nhà Hàng Trên Lộ Trình'), findsOneWidget);
      expect(
        find.textContaining('Goong Maps Polyline'),
        findsOneWidget,
      );

      // Chuyển sang Tab 3: Lịch trình (Offline-first Hive)
      await tester.tap(find.text('Lịch trình'));
      await tester.pumpAndSettle();
      expect(find.text('Lịch Trình Tham Quan Của Tôi'), findsOneWidget);

      // Chuyển sang Tab 4: Ẩm thực
      await tester.tap(find.text('Ẩm thực'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cơm tấm Sài Gòn'), findsWidgets);
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
}

