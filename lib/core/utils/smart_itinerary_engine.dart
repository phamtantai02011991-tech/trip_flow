import 'dart:math' as math;
import 'data_models.dart';
import 'geo_utils.dart';

/// Thể loại sở thích du lịch người dùng có thể chọn
class TravelPreferenceItem {
  final String id;
  final String title;
  final String group;
  final String iconEmoji;

  const TravelPreferenceItem({
    required this.id,
    required this.title,
    required this.group,
    required this.iconEmoji,
  });
}

/// Danh sách sở thích du lịch phân nhóm trực quan (Việt hóa theo Ảnh 3)
class TravelPreferencesCatalog {
  static const List<TravelPreferenceItem> allPreferences = [
    // Nhóm 1: Điểm đến hàng đầu
    TravelPreferenceItem(
      id: 'top_rated',
      title: 'Được đánh giá cao',
      group: 'Điểm đến hàng đầu',
      iconEmoji: '⭐',
    ),
    TravelPreferenceItem(
      id: 'tourist_favorite',
      title: 'Du khách yêu thích',
      group: 'Điểm đến hàng đầu',
      iconEmoji: '❤️',
    ),
    TravelPreferenceItem(
      id: 'trending',
      title: 'Xu hướng nổi bật',
      group: 'Điểm đến hàng đầu',
      iconEmoji: '🔥',
    ),
    TravelPreferenceItem(
      id: 'hidden_gems',
      title: 'Điểm đến ẩn giấu',
      group: 'Điểm đến hàng đầu',
      iconEmoji: '💎',
    ),

    // Nhóm 2: Lịch sử & Di sản
    TravelPreferenceItem(
      id: 'heritage',
      title: 'Di tích lịch sử',
      group: 'Lịch sử & Di sản',
      iconEmoji: '🏛️',
    ),
    TravelPreferenceItem(
      id: 'museum',
      title: 'Bảo tàng & Văn hóa',
      group: 'Lịch sử & Di sản',
      iconEmoji: '🏺',
    ),
    TravelPreferenceItem(
      id: 'architecture',
      title: 'Kiến trúc & Biểu tượng',
      group: 'Lịch sử & Di sản',
      iconEmoji: '🏰',
    ),

    // Nhóm 3: Thiên nhiên & Dạo bộ
    TravelPreferenceItem(
      id: 'nature',
      title: 'Cảnh quan thiên nhiên',
      group: 'Thiên nhiên & Ngoài trời',
      iconEmoji: '🌳',
    ),
    TravelPreferenceItem(
      id: 'street_walk',
      title: 'Phố đi bộ & Bến sông',
      group: 'Thiên nhiên & Ngoài trời',
      iconEmoji: '🚶',
    ),
    TravelPreferenceItem(
      id: 'checkin_spots',
      title: 'Điểm ngắm cảnh đẹp',
      group: 'Thiên nhiên & Ngoài trời',
      iconEmoji: '📸',
    ),

    // Nhóm 4: Ẩm thực & Thư giãn
    TravelPreferenceItem(
      id: 'cuisine',
      title: 'Đặc sản địa phương',
      group: 'Ẩm thực & Mua sắm',
      iconEmoji: '🍜',
    ),
    TravelPreferenceItem(
      id: 'market',
      title: 'Chợ truyền thống',
      group: 'Ẩm thực & Mua sắm',
      iconEmoji: '🛍️',
    ),
    TravelPreferenceItem(
      id: 'rest_cafe',
      title: 'Cafe nghỉ chân thư giãn',
      group: 'Ẩm thực & Mua sắm',
      iconEmoji: '☕',
    ),
  ];
}

/// Một điểm dừng trong lịch trình thông minh
class SmartItineraryStop {
  final int stopOrder;
  final String stopType; // 'origin', 'attraction', 'rest_stop', 'restaurant', 'destination'
  final String stopTypeLabel;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String timeSlot;
  final int durationMins;
  final String ticketPriceInfo;
  final int estimatedCostVnd;
  final String notes;
  final double distanceFromPrevStopKm;
  final int transitMinutesFromPrevStop;
  final double rating;
  final dynamic rawEntity;

  const SmartItineraryStop({
    required this.stopOrder,
    required this.stopType,
    required this.stopTypeLabel,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.timeSlot,
    required this.durationMins,
    required this.ticketPriceInfo,
    required this.estimatedCostVnd,
    required this.notes,
    this.distanceFromPrevStopKm = 0.0,
    this.transitMinutesFromPrevStop = 0,
    this.rating = 4.8,
    this.rawEntity,
  });

  bool get isRestaurant => stopType == 'restaurant';
  bool get isRestStop => stopType == 'rest_stop';
  bool get isAttraction => stopType == 'attraction';
  bool get isOrigin => stopType == 'origin';
  bool get isDestination => stopType == 'destination';
}

/// Kế hoạch điểm dừng theo từng ngày
class SmartItineraryDayPlan {
  final int dayNumber;
  final DateTime date;
  final String dateFormatted;
  final String dayTheme;
  final List<SmartItineraryStop> stops;
  final double dayDistanceKm;
  final int dayCostVnd;

  const SmartItineraryDayPlan({
    required this.dayNumber,
    required this.date,
    required this.dateFormatted,
    required this.dayTheme,
    required this.stops,
    required this.dayDistanceKm,
    required this.dayCostVnd,
  });
}

/// Mô hình toàn diện của một Lịch trình được xây dựng tự động
class SmartItineraryPlan {
  final String id;
  final String title;
  final String description;
  final ProvinceModel province;
  final DestinationModel origin;
  final DestinationModel destination;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double totalDistanceKm;
  final int totalDurationMins;
  final int estimatedTotalCostVnd;
  final int estimatedTicketCostVnd;
  final int estimatedFoodCostVnd;
  final int estimatedTransportCostVnd;
  final List<List<double>> fullPolyline;
  final List<SmartItineraryDayPlan> dayPlans;
  final String weatherForecast;
  final List<String> selectedPreferences;

  const SmartItineraryPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.province,
    required this.origin,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.totalDistanceKm,
    required this.totalDurationMins,
    required this.estimatedTotalCostVnd,
    required this.estimatedTicketCostVnd,
    required this.estimatedFoodCostVnd,
    required this.estimatedTransportCostVnd,
    required this.fullPolyline,
    required this.dayPlans,
    required this.weatherForecast,
    required this.selectedPreferences,
  });

  /// Chuyển đổi sang ItineraryModel chuẩn để lưu trữ vào Hive / Server
  ItineraryModel toItineraryModel() {
    final List<ItineraryStopModel> allStops = [];
    int globalId = 1;

    for (final day in dayPlans) {
      for (final stop in day.stops) {
        allStops.add(
          ItineraryStopModel(
            id: globalId++,
            referenceId: stop.rawEntity is DestinationModel
                ? (stop.rawEntity as DestinationModel).id
                : null,
            dayNumber: day.dayNumber,
            stopOrder: stop.stopOrder,
            stopType: stop.stopType,
            title: stop.title,
            address: stop.address,
            latitude: stop.latitude,
            longitude: stop.longitude,
            plannedTime: stop.timeSlot,
            durationMins: stop.durationMins,
            notes: stop.notes,
          ),
        );
      }
    }

    return ItineraryModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      provinceId: province.id,
      provinceName: province.name,
      title: title,
      description: description,
      totalDays: totalDays,
      isTemplate: false,
      isSyncedWithServer: false,
      stops: allStops,
    );
  }
}

/// Engine Thuật toán xây dựng Lịch trình Tự động (Smart Itinerary Engine)
class SmartItineraryEngine {
  /// Xây dựng lịch trình hoàn chỉnh từ các tiêu chí người dùng nhập
  static SmartItineraryPlan generate({
    required ProvinceModel province,
    required DestinationModel origin,
    required DestinationModel destination,
    required DateTime startDate,
    required int totalDays,
    required Set<String> preferenceIds,
    required List<DestinationModel> allDestinations,
    required List<RestaurantModel> allRestaurants,
  }) {
    final provDestinations = allDestinations
        .where((d) => d.provinceId == province.id && d.id != origin.id && d.id != destination.id)
        .toList();
    final provRestaurants = allRestaurants
        .where((r) => r.provinceId == province.id)
        .toList();

    // 1. Phân loại và chấm điểm điểm đến theo sở thích đã chọn
    final scoredDestinations = provDestinations.map((dest) {
      double score = dest.rating * 10;
      if (dest.isFeatured) score += 15;
      if (preferenceIds.contains(dest.categoryCode)) score += 25;
      if (preferenceIds.contains('top_rated') && dest.rating >= 4.8) score += 20;
      if (preferenceIds.contains('tourist_favorite') && dest.reviewCount > 3000) score += 15;

      // Tính khoảng cách từ trục origin -> destination
      final distOrigin = GeoUtils.haversineDistanceKm(
        origin.latitude,
        origin.longitude,
        dest.latitude,
        dest.longitude,
      );
      final distTarget = GeoUtils.haversineDistanceKm(
        dest.latitude,
        dest.longitude,
        destination.latitude,
        destination.longitude,
      );
      final totalDistViaDest = distOrigin + distTarget;
      // Trừ điểm nếu quá xa đường thẳng
      score -= totalDistViaDest * 1.5;

      return MapEntry(dest, score);
    }).toList();

    scoredDestinations.sort((a, b) => b.value.compareTo(a.value));
    final selectedAttractions = scoredDestinations.map((e) => e.key).toList();

    // 2. Chia theo ngày (Mỗi ngày gồm 2-3 điểm tham quan, 1-2 điểm ăn uống, 1 điểm dừng chân)
    final List<SmartItineraryDayPlan> dayPlans = [];
    int attractionPointer = 0;
    int restaurantPointer = 0;
    double accumulatedDistanceKm = 0.0;
    int totalEstimatedCostVnd = 0;
    int totalTicketCost = 0;
    int totalFoodCost = 0;
    int totalTransportCost = 0;
    int totalDurationMins = 0;

    final List<List<double>> routeCoordinates = [];

    // Tọa độ khởi hành ban đầu
    double currentLat = origin.latitude;
    double currentLng = origin.longitude;
    routeCoordinates.add([currentLat, currentLng]);

    final safeDays = math.max(1, math.min(totalDays, 3));

    for (int day = 1; day <= safeDays; day++) {
      final List<SmartItineraryStop> dayStops = [];
      int stopOrder = 1;
      double dayDistance = 0.0;
      int dayCost = 0;
      final dayDate = startDate.add(Duration(days: day - 1));

      // Điểm bắt đầu ngày:
      if (day == 1) {
        dayStops.add(
          SmartItineraryStop(
            stopOrder: stopOrder++,
            stopType: 'origin',
            stopTypeLabel: 'Điểm khởi hành',
            title: origin.name,
            address: origin.address,
            latitude: origin.latitude,
            longitude: origin.longitude,
            imageUrl: origin.primaryImageUrl,
            timeSlot: '07:30 - 08:30',
            durationMins: 60,
            ticketPriceInfo: origin.ticketPriceInfo,
            estimatedCostVnd: _parseTicketCost(origin.ticketPriceInfo),
            notes: 'Tập trung khởi hành, kiểm tra tư trang và bắt đầu hành trình.',
            distanceFromPrevStopKm: 0.0,
            transitMinutesFromPrevStop: 0,
            rating: origin.rating,
            rawEntity: origin,
          ),
        );
        dayCost += _parseTicketCost(origin.ticketPriceInfo);
        totalTicketCost += _parseTicketCost(origin.ticketPriceInfo);
        totalDurationMins += 60;
      } else {
        // Điểm đầu ngày tiếp theo là khách sạn / điểm dừng chân sáng
        dayStops.add(
          SmartItineraryStop(
            stopOrder: stopOrder++,
            stopType: 'rest_stop',
            stopTypeLabel: 'Khởi đầu ngày mới',
            title: 'Điểm nghỉ chân & Cà phê sáng $day',
            address: 'Trung tâm khu vực ${province.name}',
            latitude: currentLat,
            longitude: currentLng,
            imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=900&q=80',
            timeSlot: '07:30 - 08:30',
            durationMins: 60,
            ticketPriceInfo: 'Chi phí đồ uống',
            estimatedCostVnd: 45000,
            notes: 'Thưởng thức cà phê sáng, nạp năng lượng cho ngày khám phá thứ $day.',
            distanceFromPrevStopKm: 0.0,
            transitMinutesFromPrevStop: 0,
            rating: 4.8,
          ),
        );
        dayCost += 45000;
        totalFoodCost += 45000;
        totalDurationMins += 60;
      }

      // Điểm tham quan buổi sáng (09:00 - 11:30)
      if (attractionPointer < selectedAttractions.length) {
        final attr1 = selectedAttractions[attractionPointer++];
        final dist = GeoUtils.haversineDistanceKm(currentLat, currentLng, attr1.latitude, attr1.longitude);
        final transitMin = (dist * 2.5).round().clamp(10, 45);
        dayDistance += dist;
        currentLat = attr1.latitude;
        currentLng = attr1.longitude;
        routeCoordinates.add([currentLat, currentLng]);

        final cost = _parseTicketCost(attr1.ticketPriceInfo);
        dayCost += cost;
        totalTicketCost += cost;
        totalDurationMins += attr1.recommendedDurationMins + transitMin;

        dayStops.add(
          SmartItineraryStop(
            stopOrder: stopOrder++,
            stopType: 'attraction',
            stopTypeLabel: 'Điểm tham quan',
            title: attr1.name,
            address: attr1.address,
            latitude: attr1.latitude,
            longitude: attr1.longitude,
            imageUrl: attr1.primaryImageUrl,
            timeSlot: '09:00 - 11:30',
            durationMins: attr1.recommendedDurationMins,
            ticketPriceInfo: attr1.ticketPriceInfo,
            estimatedCostVnd: cost,
            notes: '${attr1.description} (Thời gian tham quan gợi ý: ${attr1.recommendedDurationMins} phút).',
            distanceFromPrevStopKm: double.parse(dist.toStringAsFixed(1)),
            transitMinutesFromPrevStop: transitMin,
            rating: attr1.rating,
            rawEntity: attr1,
          ),
        );
      }

      // Điểm ăn trưa dọc lộ trình (11:45 - 13:15)
      RestaurantModel? lunchRest;
      if (provRestaurants.isNotEmpty) {
        lunchRest = provRestaurants[restaurantPointer % provRestaurants.length];
        restaurantPointer++;
      }
      if (lunchRest != null) {
        final dist = GeoUtils.haversineDistanceKm(currentLat, currentLng, lunchRest.latitude, lunchRest.longitude);
        final transitMin = (dist * 2.5).round().clamp(5, 25);
        dayDistance += dist;
        currentLat = lunchRest.latitude;
        currentLng = lunchRest.longitude;
        routeCoordinates.add([currentLat, currentLng]);

        const lunchCost = 85000;
        dayCost += lunchCost;
        totalFoodCost += lunchCost;
        totalDurationMins += 90 + transitMin;

        dayStops.add(
          SmartItineraryStop(
            stopOrder: stopOrder++,
            stopType: 'restaurant',
            stopTypeLabel: 'Bữa trưa dọc lộ trình',
            title: lunchRest.name,
            address: lunchRest.address,
            latitude: lunchRest.latitude,
            longitude: lunchRest.longitude,
            imageUrl: lunchRest.imageUrl,
            timeSlot: '11:45 - 13:15',
            durationMins: 90,
            ticketPriceInfo: lunchRest.priceRange,
            estimatedCostVnd: lunchCost,
            notes: 'Thưởng thức món ngon đặc trưng: ${lunchRest.specialtyDishes}. Không gian mát mẻ nghỉ ngơi giữa ngày.',
            distanceFromPrevStopKm: double.parse(dist.toStringAsFixed(1)),
            transitMinutesFromPrevStop: transitMin,
            rating: lunchRest.rating,
            rawEntity: lunchRest,
          ),
        );
      }

      // Điểm dừng nghỉ chân thư giãn giữa chiều (13:30 - 14:30)
      final restStopLat = currentLat + 0.003;
      final restStopLng = currentLng + 0.003;
      routeCoordinates.add([restStopLat, restStopLng]);
      currentLat = restStopLat;
      currentLng = restStopLng;
      dayDistance += 1.2;
      const restCost = 35000;
      dayCost += restCost;
      totalFoodCost += restCost;
      totalDurationMins += 60;

      dayStops.add(
        SmartItineraryStop(
          stopOrder: stopOrder++,
          stopType: 'rest_stop',
          stopTypeLabel: 'Điểm dừng nghỉ chân',
          title: 'Trạm dừng chân & Không gian ngắm cảnh',
          address: 'Ven tuyến đường hành lang ${province.name}',
          latitude: restStopLat,
          longitude: restStopLng,
          imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80',
          timeSlot: '13:30 - 14:30',
          durationMins: 60,
          ticketPriceInfo: 'Đồ uống nhẹ',
          estimatedCostVnd: restCost,
          notes: 'Nghỉ chân thư giãn, uống nước dừa hoặc trà sen ngắm cảnh quan địa phương.',
          distanceFromPrevStopKm: 1.2,
          transitMinutesFromPrevStop: 10,
          rating: 4.7,
        ),
      );

      // Điểm tham quan buổi chiều (15:00 - 17:30)
      if (attractionPointer < selectedAttractions.length) {
        final attr2 = selectedAttractions[attractionPointer++];
        final dist = GeoUtils.haversineDistanceKm(currentLat, currentLng, attr2.latitude, attr2.longitude);
        final transitMin = (dist * 2.5).round().clamp(10, 45);
        dayDistance += dist;
        currentLat = attr2.latitude;
        currentLng = attr2.longitude;
        routeCoordinates.add([currentLat, currentLng]);

        final cost = _parseTicketCost(attr2.ticketPriceInfo);
        dayCost += cost;
        totalTicketCost += cost;
        totalDurationMins += attr2.recommendedDurationMins + transitMin;

        dayStops.add(
          SmartItineraryStop(
            stopOrder: stopOrder++,
            stopType: 'attraction',
            stopTypeLabel: 'Điểm tham quan',
            title: attr2.name,
            address: attr2.address,
            latitude: attr2.latitude,
            longitude: attr2.longitude,
            imageUrl: attr2.primaryImageUrl,
            timeSlot: '15:00 - 17:30',
            durationMins: attr2.recommendedDurationMins,
            ticketPriceInfo: attr2.ticketPriceInfo,
            estimatedCostVnd: cost,
            notes: '${attr2.description} (Ánh sáng hoàng hôn chụp ảnh rất đẹp).',
            distanceFromPrevStopKm: double.parse(dist.toStringAsFixed(1)),
            transitMinutesFromPrevStop: transitMin,
            rating: attr2.rating,
            rawEntity: attr2,
          ),
        );
      }

      // Điểm ăn tối hoặc Đích đến cuối ngày
      if (day == safeDays) {
        // Ngày cuối cùng kết thúc tại Điểm đến đã chọn
        final dist = GeoUtils.haversineDistanceKm(currentLat, currentLng, destination.latitude, destination.longitude);
        final transitMin = (dist * 2.5).round().clamp(10, 45);
        dayDistance += dist;
        currentLat = destination.latitude;
        currentLng = destination.longitude;
        routeCoordinates.add([currentLat, currentLng]);

        final cost = _parseTicketCost(destination.ticketPriceInfo);
        dayCost += cost;
        totalTicketCost += cost;
        totalDurationMins += destination.recommendedDurationMins + transitMin;

        dayStops.add(
          SmartItineraryStop(
            stopOrder: stopOrder++,
            stopType: 'destination',
            stopTypeLabel: 'Đích đến chuyến đi',
            title: destination.name,
            address: destination.address,
            latitude: destination.latitude,
            longitude: destination.longitude,
            imageUrl: destination.primaryImageUrl,
            timeSlot: '18:30 - 20:30',
            durationMins: destination.recommendedDurationMins,
            ticketPriceInfo: destination.ticketPriceInfo,
            estimatedCostVnd: cost,
            notes: 'Điểm kết thúc trọn vẹn hành trình. Chụp ảnh lưu niệm và tổng kết chuyến đi.',
            distanceFromPrevStopKm: double.parse(dist.toStringAsFixed(1)),
            transitMinutesFromPrevStop: transitMin,
            rating: destination.rating,
            rawEntity: destination,
          ),
        );
      } else {
        // Ngày chưa kết thúc: Điểm ăn tối & khám phá phố đêm
        RestaurantModel? dinnerRest;
        if (provRestaurants.isNotEmpty) {
          dinnerRest = provRestaurants[restaurantPointer % provRestaurants.length];
          restaurantPointer++;
        }
        if (dinnerRest != null) {
          final dist = GeoUtils.haversineDistanceKm(currentLat, currentLng, dinnerRest.latitude, dinnerRest.longitude);
          final transitMin = (dist * 2.5).round().clamp(10, 30);
          dayDistance += dist;
          currentLat = dinnerRest.latitude;
          currentLng = dinnerRest.longitude;
          routeCoordinates.add([currentLat, currentLng]);

          const dinnerCost = 120000;
          dayCost += dinnerCost;
          totalFoodCost += dinnerCost;
          totalDurationMins += 120 + transitMin;

          dayStops.add(
            SmartItineraryStop(
              stopOrder: stopOrder++,
              stopType: 'restaurant',
              stopTypeLabel: 'Bữa tối & Ẩm thực đêm',
              title: dinnerRest.name,
              address: dinnerRest.address,
              latitude: dinnerRest.latitude,
              longitude: dinnerRest.longitude,
              imageUrl: dinnerRest.imageUrl,
              timeSlot: '18:30 - 20:30',
              durationMins: 120,
              ticketPriceInfo: dinnerRest.priceRange,
              estimatedCostVnd: dinnerCost,
              notes: 'Thưởng thức ẩm thực tối đặc sắc cùng bạn bè: ${dinnerRest.specialtyDishes}.',
              distanceFromPrevStopKm: double.parse(dist.toStringAsFixed(1)),
              transitMinutesFromPrevStop: transitMin,
              rating: dinnerRest.rating,
              rawEntity: dinnerRest,
            ),
          );
        }
      }

      accumulatedDistanceKm += dayDistance;
      totalEstimatedCostVnd += dayCost;

      dayPlans.add(
        SmartItineraryDayPlan(
          dayNumber: day,
          date: dayDate,
          dateFormatted: _formatVietnameseDate(dayDate),
          dayTheme: 'Ngày $day: ${day == 1 ? 'Khởi hành & Biểu tượng văn hóa' : day == 2 ? 'Trải nghiệm thắng cảnh & Ẩm thực' : 'Hành trình chinh phục & Về đích'}',
          stops: dayStops,
          dayDistanceKm: double.parse(dayDistance.toStringAsFixed(1)),
          dayCostVnd: dayCost,
        ),
      );
    }

    // Chi phí di chuyển ước tính (Xăng xe / taxi khoảng 12.000đ / km)
    totalTransportCost = (accumulatedDistanceKm * 12000).round();
    totalEstimatedCostVnd += totalTransportCost;

    // Polyline mịn
    final fullPolyline = routeCoordinates.isNotEmpty
        ? routeCoordinates
        : GeoUtils.buildRoutePolyline(
            originLat: origin.latitude,
            originLng: origin.longitude,
            destLat: destination.latitude,
            destLng: destination.longitude,
          );

    final endDate = startDate.add(Duration(days: safeDays - 1));

    return SmartItineraryPlan(
      id: 'smart_itin_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Lịch trình ${safeDays}N${safeDays > 1 ? '${safeDays - 1}Đ' : ''}: ${origin.name} → ${destination.name}',
      description: 'Lộ trình khám phá tối ưu kết hợp danh lam thắng cảnh, điểm dừng chân thư giãn và ẩm thực đặc sản địa phương.',
      province: province,
      origin: origin,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      totalDays: safeDays,
      totalDistanceKm: double.parse(accumulatedDistanceKm.toStringAsFixed(1)),
      totalDurationMins: totalDurationMins,
      estimatedTotalCostVnd: totalEstimatedCostVnd,
      estimatedTicketCostVnd: totalTicketCost,
      estimatedFoodCostVnd: totalFoodCost,
      estimatedTransportCostVnd: totalTransportCost,
      fullPolyline: fullPolyline,
      dayPlans: dayPlans,
      weatherForecast: '28°C Nắng nhẹ, độ ẩm 62%, gió 12 km/h • Thời tiết lý tưởng cho chuyến đi',
      selectedPreferences: preferenceIds.toList(),
    );
  }

  static int _parseTicketCost(String ticketText) {
    final lower = ticketText.toLowerCase();
    if (lower.contains('miễn phí') || lower.contains('free')) return 0;
    // Extract first number like 40.000, 20.000, 200.000
    final reg = RegExp(r'(\d+[\.\,]?\d*)\s*000');
    final match = reg.firstMatch(ticketText);
    if (match != null) {
      final rawNum = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
      return (int.tryParse(rawNum) ?? 30) * 1000;
    }
    return 35000;
  }

  static String _formatVietnameseDate(DateTime date) {
    const daysOfWeek = ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy'];
    final dow = daysOfWeek[date.weekday % 7];
    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = date.month.toString().padLeft(2, '0');
    return '$dow, $dayStr/$monthStr/${date.year}';
  }
}
