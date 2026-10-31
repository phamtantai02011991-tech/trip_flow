import '../config/app_config.dart';

/// Định nghĩa toàn bộ các lớp dữ liệu (Data Models) cho ứng dụng Flutter TripFlow.
/// Đồng bộ 100% với cấu trúc JSON của FastAPI Backend (`SQLModel` Schemas & `/api/v1/*`).

class ProvinceModel {
  final int id;
  final String code;
  final String name;
  final String region;
  final String description;
  final String heroImage;
  final double centerLat;
  final double centerLng;
  final bool isActive;
  final String dataSource;
  final int destinationCount;
  final int foodCount;
  final int restaurantCount;

  const ProvinceModel({
    required this.id,
    required this.code,
    required this.name,
    required this.region,
    required this.description,
    required this.heroImage,
    required this.centerLat,
    required this.centerLng,
    this.isActive = true,
    this.dataSource = 'internal',
    this.destinationCount = 0,
    this.foodCount = 0,
    this.restaurantCount = 0,
  });

  String get thumbnailUrl => AppConfig.buildThumbnailUrl(heroImage);

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: (json['id'] as num).toInt(),
      code: (json['code'] ?? 'HCM').toString(),
      name: (json['name'] ?? '').toString(),
      region: (json['region'] ?? 'Nam Bộ').toString(),
      description: (json['description'] ?? '').toString(),
      heroImage: (json['hero_image'] ?? '').toString(),
      centerLat: (json['center_lat'] as num?)?.toDouble() ?? 10.7769,
      centerLng: (json['center_lng'] as num?)?.toDouble() ?? 106.7009,
      isActive: json['is_active'] as bool? ?? true,
      dataSource: (json['data_source'] ?? 'internal').toString(),
      destinationCount: (json['destination_count'] as num?)?.toInt() ?? 0,
      foodCount: (json['food_count'] as num?)?.toInt() ?? 0,
      restaurantCount: (json['restaurant_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'region': region,
        'description': description,
        'hero_image': heroImage,
        'center_lat': centerLat,
        'center_lng': centerLng,
        'is_active': isActive,
        'data_source': dataSource,
        'destination_count': destinationCount,
        'food_count': foodCount,
        'restaurant_count': restaurantCount,
      };
}

class DestinationImageModel {
  final int id;
  final int destinationId;
  final String imageUrl;
  final String? thumbnailUrl;
  final String caption;
  final String licenseType;
  final String creditAuthor;

  const DestinationImageModel({
    required this.id,
    required this.destinationId,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.caption,
    this.licenseType = 'owned',
    this.creditAuthor = 'TripFlow Studio',
  });

  String get resolvedThumbnailUrl =>
      thumbnailUrl ?? AppConfig.buildThumbnailUrl(imageUrl);

  factory DestinationImageModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['image_url'] ?? '').toString();
    return DestinationImageModel(
      id: (json['id'] as num?)?.toInt() ?? 1,
      destinationId: (json['destination_id'] as num?)?.toInt() ?? 1,
      imageUrl: rawUrl,
      thumbnailUrl: json['thumbnail_url']?.toString() ??
          AppConfig.buildThumbnailUrl(rawUrl),
      caption: (json['caption'] ?? '').toString(),
      licenseType: (json['license_type'] ?? 'owned').toString(),
      creditAuthor: (json['credit_author'] ?? 'TripFlow Studio').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination_id': destinationId,
        'image_url': imageUrl,
        'thumbnail_url': resolvedThumbnailUrl,
        'caption': caption,
        'license_type': licenseType,
        'credit_author': creditAuthor,
      };
}

class DestinationModel {
  final int id;
  final int provinceId;
  final String provinceName;
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String openingHours;
  final String ticketPriceInfo;
  final double rating;
  final int reviewCount;
  final int recommendedDurationMins;
  final bool isFeatured;
  final bool isSponsored;
  final String? sponsorLabel;
  final String dataSource;
  final String sourceAttribution;
  final String updatedAt;
  final List<DestinationImageModel> images;

  const DestinationModel({
    required this.id,
    required this.provinceId,
    this.provinceName = 'TP. Hồ Chí Minh',
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.openingHours,
    required this.ticketPriceInfo,
    required this.rating,
    required this.reviewCount,
    this.recommendedDurationMins = 90,
    this.isFeatured = false,
    this.isSponsored = false,
    this.sponsorLabel,
    this.dataSource = 'internal',
    this.sourceAttribution = 'Ban Biên Tập TripFlow & Sở Du lịch TP.HCM',
    this.updatedAt = '30/10/2026',
    this.images = const [],
  });

  String get primaryImageUrl => images.isNotEmpty
      ? images.first.imageUrl
      : 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80';

  String get thumbnailUrl => images.isNotEmpty
      ? images.first.resolvedThumbnailUrl
      : AppConfig.buildThumbnailUrl(primaryImageUrl);

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    final rawImages = (json['images'] as List<dynamic>?) ?? [];
    return DestinationModel(
      id: (json['id'] as num).toInt(),
      provinceId: (json['province_id'] as num?)?.toInt() ?? 1,
      provinceName: (json['province_name'] ?? 'TP. Hồ Chí Minh').toString(),
      categoryId: (json['category_id'] as num?)?.toInt() ?? 1,
      categoryCode: (json['category_code'] ?? 'heritage').toString(),
      categoryName: (json['category_name'] ?? 'Di tích lịch sử').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      openingHours: (json['opening_hours'] ?? '07:30 - 17:30').toString(),
      ticketPriceInfo: (json['ticket_price_info'] ?? 'Miễn phí').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.7,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 100,
      recommendedDurationMins:
          (json['recommended_duration_mins'] as num?)?.toInt() ?? 90,
      isFeatured: json['is_featured'] as bool? ?? false,
      isSponsored: json['is_sponsored'] as bool? ?? false,
      sponsorLabel: json['sponsor_label']?.toString(),
      dataSource: (json['data_source'] ?? 'internal').toString(),
      sourceAttribution:
          (json['source_attribution'] ?? 'Ban Biên Tập TripFlow').toString(),
      updatedAt: (json['updated_at'] ?? '2026-10-30').toString(),
      images: rawImages
          .map((e) => DestinationImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'province_id': provinceId,
        'province_name': provinceName,
        'category_id': categoryId,
        'category_code': categoryCode,
        'category_name': categoryName,
        'name': name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'opening_hours': openingHours,
        'ticket_price_info': ticketPriceInfo,
        'rating': rating,
        'review_count': reviewCount,
        'recommended_duration_mins': recommendedDurationMins,
        'is_featured': isFeatured,
        'is_sponsored': isSponsored,
        'sponsor_label': sponsorLabel,
        'data_source': dataSource,
        'source_attribution': sourceAttribution,
        'updated_at': updatedAt,
        'images': images.map((e) => e.toJson()).toList(),
      };
}

class LocalFoodModel {
  final int id;
  final int provinceId;
  final String provinceName;
  final String name;
  final String description;
  final String storyOrigin;
  final String imageUrl;
  final String? thumbnailUrl;
  final String bestSeasonOrTime;
  final String avgPriceRange;
  final List<int> recommendedRestaurantIds;
  final String dataSource;
  final String licenseInfo;
  final String updatedAt;

  const LocalFoodModel({
    required this.id,
    required this.provinceId,
    this.provinceName = 'TP. Hồ Chí Minh',
    required this.name,
    required this.description,
    required this.storyOrigin,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.bestSeasonOrTime,
    required this.avgPriceRange,
    required this.recommendedRestaurantIds,
    this.dataSource = 'internal',
    this.licenseInfo = 'Ban Biên Tập Ẩm thực TripFlow',
    this.updatedAt = '30/10/2026',
  });

  String get resolvedThumbnailUrl =>
      thumbnailUrl ?? AppConfig.buildThumbnailUrl(imageUrl);

  factory LocalFoodModel.fromJson(Map<String, dynamic> json) {
    final rawIds = (json['recommended_restaurant_ids'] as List<dynamic>?) ?? [];
    final rawUrl = (json['image_url'] ?? '').toString();
    return LocalFoodModel(
      id: (json['id'] as num).toInt(),
      provinceId: (json['province_id'] as num?)?.toInt() ?? 1,
      provinceName: (json['province_name'] ?? 'TP. Hồ Chí Minh').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      storyOrigin: (json['story_origin'] ?? '').toString(),
      imageUrl: rawUrl,
      thumbnailUrl: json['thumbnail_url']?.toString() ??
          AppConfig.buildThumbnailUrl(rawUrl),
      bestSeasonOrTime: (json['best_season_or_time'] ?? 'Quanh năm').toString(),
      avgPriceRange:
          (json['avg_price_range'] ?? '45.000đ - 100.000đ').toString(),
      recommendedRestaurantIds: rawIds.map((e) => (e as num).toInt()).toList(),
      dataSource: (json['data_source'] ?? 'internal').toString(),
      licenseInfo:
          (json['license_info'] ?? 'Ban Biên Tập Ẩm thực TripFlow').toString(),
      updatedAt: (json['updated_at'] ?? '2026-10-30').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'province_id': provinceId,
        'province_name': provinceName,
        'name': name,
        'description': description,
        'story_origin': storyOrigin,
        'image_url': imageUrl,
        'thumbnail_url': resolvedThumbnailUrl,
        'best_season_or_time': bestSeasonOrTime,
        'avg_price_range': avgPriceRange,
        'recommended_restaurant_ids': recommendedRestaurantIds,
        'data_source': dataSource,
        'license_info': licenseInfo,
        'updated_at': updatedAt,
      };
}

class ReviewItemModel {
  final String author;
  final double rating;
  final String text;
  final String relativeTime;

  const ReviewItemModel({
    required this.author,
    this.rating = 5.0,
    required this.text,
    this.relativeTime = 'Gần đây',
  });

  factory ReviewItemModel.fromJson(Map<String, dynamic> json) {
    return ReviewItemModel(
      author: (json['author'] ?? 'Thực khách TripFlow').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      text: (json['text'] ?? '').toString(),
      relativeTime: (json['relative_time'] ?? 'Gần đây').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'author': author,
        'rating': rating,
        'text': text,
        'relative_time': relativeTime,
      };
}

class RestaurantModel {
  final int id;
  final int provinceId;
  final String provinceName;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String cuisineType;
  final String specialtyDishes;
  final String specialties;
  final String priceRange;
  final String openingHours;
  final String contactPhone;
  final double rating;
  final int reviewCount;
  final int reviewsCount;
  final bool isHighRated;
  final List<ReviewItemModel> sampleReviews;
  final String imageUrl;
  final String? thumbnailUrl;
  final bool isSponsored;
  final String? sponsorLabel;
  final String dataSource;
  final String lastUpdatedAt;

  const RestaurantModel({
    required this.id,
    required this.provinceId,
    this.provinceName = 'TP. Hồ Chí Minh',
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.cuisineType,
    required this.specialtyDishes,
    this.specialties = '',
    required this.priceRange,
    required this.openingHours,
    required this.contactPhone,
    required this.rating,
    required this.reviewCount,
    this.reviewsCount = 120,
    this.isHighRated = true,
    this.sampleReviews = const [],
    required this.imageUrl,
    this.thumbnailUrl,
    this.isSponsored = false,
    this.sponsorLabel,
    this.dataSource = 'internal',
    this.lastUpdatedAt = '30/10/2026',
  });

  String get resolvedThumbnailUrl =>
      thumbnailUrl ?? AppConfig.buildThumbnailUrl(imageUrl);

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['image_url'] ?? '').toString();
    final rawReviews = (json['sample_reviews'] as List<dynamic>?) ?? [];
    final parsedReviews = rawReviews
        .map((r) => ReviewItemModel.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();

    final rScore = (json['rating'] as num?)?.toDouble() ?? 4.6;
    final revCnt = (json['reviews_count'] as num?)?.toInt() ??
        (json['review_count'] as num?)?.toInt() ??
        120;
    final isHigh = json['is_high_rated'] as bool? ??
        (rScore >= 4.2 && revCnt >= 50);

    return RestaurantModel(
      id: (json['id'] as num).toInt(),
      provinceId: (json['province_id'] as num?)?.toInt() ?? 1,
      provinceName: (json['province_name'] ?? 'TP. Hồ Chí Minh').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      cuisineType: (json['cuisine_type'] ?? 'Đặc sản Sài Gòn').toString(),
      specialtyDishes: (json['specialty_dishes'] ?? '').toString(),
      specialties: (json['specialties'] ?? json['specialty_dishes'] ?? '').toString(),
      priceRange: (json['price_range'] ?? '50.000đ - 120.000đ').toString(),
      openingHours: (json['opening_hours'] ?? '06:30 - 22:00').toString(),
      contactPhone: (json['contact_phone'] ?? '').toString(),
      rating: rScore,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? revCnt,
      reviewsCount: revCnt,
      isHighRated: isHigh,
      sampleReviews: parsedReviews,
      imageUrl: rawUrl,
      thumbnailUrl: json['thumbnail_url']?.toString() ??
          AppConfig.buildThumbnailUrl(rawUrl),
      isSponsored: json['is_sponsored'] as bool? ?? false,
      sponsorLabel: json['sponsor_label']?.toString(),
      dataSource: (json['data_source'] ?? 'internal').toString(),
      lastUpdatedAt: (json['last_updated_at'] ?? '30/10/2026').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'province_id': provinceId,
        'province_name': provinceName,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'cuisine_type': cuisineType,
        'specialty_dishes': specialtyDishes,
        'specialties': specialties,
        'price_range': priceRange,
        'opening_hours': openingHours,
        'contact_phone': contactPhone,
        'rating': rating,
        'review_count': reviewCount,
        'reviews_count': reviewsCount,
        'is_high_rated': isHighRated,
        'sample_reviews': sampleReviews.map((e) => e.toJson()).toList(),
        'image_url': imageUrl,
        'thumbnail_url': resolvedThumbnailUrl,
        'is_sponsored': isSponsored,
        'sponsor_label': sponsorLabel,
        'data_source': dataSource,
        'last_updated_at': lastUpdatedAt,
      };
}

/// Kết quả nhà hàng nằm trong hành lang dọc tuyến đường (Bounding Box + Shapely Corridor Search - Mục 9)
class CorridorRestaurantResult {
  final RestaurantModel restaurant;
  final double distanceFromRouteKm;
  final double detourDistanceKm;
  final int estimatedDetourMins;
  final double nearestRouteLat;
  final double nearestRouteLng;
  final double routeProgressPct;
  final double corridorScore;

  const CorridorRestaurantResult({
    required this.restaurant,
    required this.distanceFromRouteKm,
    required this.detourDistanceKm,
    required this.estimatedDetourMins,
    required this.nearestRouteLat,
    required this.nearestRouteLng,
    required this.routeProgressPct,
    this.corridorScore = 0.0,
  });

  factory CorridorRestaurantResult.fromJson(Map<String, dynamic> json) {
    final nearestPoint = (json['nearest_route_point'] as List<dynamic>?);
    final nearestLat = (json['nearest_route_point_lat'] as num?)?.toDouble() ??
        (nearestPoint != null && nearestPoint.isNotEmpty
            ? (nearestPoint.first as num).toDouble()
            : 10.7769);
    final nearestLng = (json['nearest_route_point_lng'] as num?)?.toDouble() ??
        (nearestPoint != null && nearestPoint.length > 1
            ? (nearestPoint.last as num).toDouble()
            : 106.7009);
    return CorridorRestaurantResult(
      restaurant: RestaurantModel.fromJson(json),
      distanceFromRouteKm:
          (json['distance_from_route_km'] as num?)?.toDouble() ?? 0.35,
      detourDistanceKm:
          (json['detour_distance_km'] as num?)?.toDouble() ?? 0.70,
      estimatedDetourMins:
          (json['estimated_detour_mins'] as num?)?.toInt() ?? 3,
      nearestRouteLat: nearestLat,
      nearestRouteLng: nearestLng,
      routeProgressPct:
          (json['route_progress_pct'] as num?)?.toDouble() ?? 50.0,
      corridorScore:
          (json['corridor_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        ...restaurant.toJson(),
        'distance_from_route_km': distanceFromRouteKm,
        'detour_distance_km': detourDistanceKm,
        'estimated_detour_mins': estimatedDetourMins,
        'nearest_route_point_lat': nearestRouteLat,
        'nearest_route_point_lng': nearestRouteLng,
        'route_progress_pct': routeProgressPct,
        'corridor_score': corridorScore,
      };
}

/// Phản hồi tổng hợp từ API `POST /api/v1/restaurants/corridor-search` (Goong Maps + Bounding Box + Shapely)
class CorridorSearchResponseModel {
  final String encodedPolyline;
  final List<List<double>> polyline;
  final Map<String, double> boundingBox;
  final double corridorRadiusKm;
  final double totalRouteKm;
  final int estimatedDriveMins;
  final int matchedCount;
  final String mapProvider;
  final String spatialEngine;
  final List<CorridorRestaurantResult> results;

  const CorridorSearchResponseModel({
    required this.encodedPolyline,
    required this.polyline,
    required this.boundingBox,
    required this.corridorRadiusKm,
    required this.totalRouteKm,
    required this.estimatedDriveMins,
    required this.matchedCount,
    this.mapProvider = 'goong_maps',
    this.spatialEngine = 'postgresql_btree_bbox_plus_shapely_linestring',
    required this.results,
  });

  factory CorridorSearchResponseModel.fromJson(Map<String, dynamic> json) {
    final rawPoly = (json['polyline'] as List<dynamic>?) ?? [];
    final poly = rawPoly.map((pt) {
      if (pt is Map<String, dynamic>) {
        return [
          (pt['lat'] as num).toDouble(),
          (pt['lng'] as num).toDouble(),
        ];
      }
      return (pt as List<dynamic>)
          .map((coord) => (coord as num).toDouble())
          .toList();
    }).toList();

    final rawBbox = (json['bounding_box'] as Map<String, dynamic>?) ?? {};
    final bbox = <String, double>{
      'min_lat': (rawBbox['min_lat'] as num?)?.toDouble() ?? 10.75,
      'max_lat': (rawBbox['max_lat'] as num?)?.toDouble() ?? 10.80,
      'min_lng': (rawBbox['min_lng'] as num?)?.toDouble() ?? 106.67,
      'max_lng': (rawBbox['max_lng'] as num?)?.toDouble() ?? 106.71,
    };

    final rawResults = ((json['restaurants'] ?? json['results']) as List<dynamic>?) ?? [];
    final totalRouteKm = ((json['total_route_distance_km'] ?? json['total_route_km']) as num?)?.toDouble() ?? 2.5;
    final matchedCount = ((json['results_count'] ?? json['matched_count']) as num?)?.toInt() ?? rawResults.length;
    return CorridorSearchResponseModel(
      encodedPolyline: (json['encoded_polyline'] ?? '').toString(),
      polyline: poly,
      boundingBox: bbox,
      corridorRadiusKm:
          (json['corridor_radius_km'] as num?)?.toDouble() ?? 2.0,
      totalRouteKm: totalRouteKm,
      estimatedDriveMins:
          (json['estimated_drive_mins'] as num?)?.toInt() ?? 10,
      matchedCount: matchedCount,
      mapProvider: (json['map_provider'] ?? 'goong_maps').toString(),
      spatialEngine: (json['spatial_engine'] ??
              'postgresql_btree_bbox_plus_shapely_linestring')
          .toString(),
      results: rawResults
          .map((e) => CorridorRestaurantResult.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ItineraryStopModel {
  final int id;
  final int dayNumber;
  final int stopOrder;
  final String stopType; // 'destination', 'restaurant', 'custom'
  final int? referenceId;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String plannedTime;
  final int durationMins;
  final String notes;

  const ItineraryStopModel({
    required this.id,
    this.dayNumber = 1,
    required this.stopOrder,
    required this.stopType,
    this.referenceId,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.plannedTime = '08:30 - 10:00',
    this.durationMins = 90,
    this.notes = '',
  });

  ItineraryStopModel copyWith({
    int? id,
    int? dayNumber,
    int? stopOrder,
    String? stopType,
    int? referenceId,
    String? title,
    String? address,
    double? latitude,
    double? longitude,
    String? plannedTime,
    int? durationMins,
    String? notes,
  }) {
    return ItineraryStopModel(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      stopOrder: stopOrder ?? this.stopOrder,
      stopType: stopType ?? this.stopType,
      referenceId: referenceId ?? this.referenceId,
      title: title ?? this.title,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      plannedTime: plannedTime ?? this.plannedTime,
      durationMins: durationMins ?? this.durationMins,
      notes: notes ?? this.notes,
    );
  }

  factory ItineraryStopModel.fromJson(Map<String, dynamic> json) {
    return ItineraryStopModel(
      id: (json['id'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      stopOrder: (json['stop_order'] as num?)?.toInt() ?? 1,
      stopType: (json['stop_type'] ?? 'destination').toString(),
      referenceId: (json['reference_id'] as num?)?.toInt(),
      title: (json['title'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.7769,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.7009,
      plannedTime: (json['planned_time'] ?? '08:30 - 10:00').toString(),
      durationMins: (json['duration_mins'] as num?)?.toInt() ?? 90,
      notes: (json['notes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'day_number': dayNumber,
        'stop_order': stopOrder,
        'stop_type': stopType,
        'reference_id': referenceId,
        'title': title,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'planned_time': plannedTime,
        'duration_mins': durationMins,
        'notes': notes,
      };
}

class ItineraryModel {
  final int id;
  final int provinceId;
  final String provinceName;
  final String title;
  final String description;
  final int totalDays;
  final bool isTemplate;
  final bool isSyncedWithServer;
  final List<ItineraryStopModel> stops;

  const ItineraryModel({
    required this.id,
    required this.provinceId,
    this.provinceName = 'TP. Hồ Chí Minh',
    required this.title,
    required this.description,
    this.totalDays = 1,
    this.isTemplate = false,
    this.isSyncedWithServer = true,
    required this.stops,
  });

  ItineraryModel copyWith({
    int? id,
    int? provinceId,
    String? provinceName,
    String? title,
    String? description,
    int? totalDays,
    bool? isTemplate,
    bool? isSyncedWithServer,
    List<ItineraryStopModel>? stops,
  }) {
    return ItineraryModel(
      id: id ?? this.id,
      provinceId: provinceId ?? this.provinceId,
      provinceName: provinceName ?? this.provinceName,
      title: title ?? this.title,
      description: description ?? this.description,
      totalDays: totalDays ?? this.totalDays,
      isTemplate: isTemplate ?? this.isTemplate,
      isSyncedWithServer: isSyncedWithServer ?? this.isSyncedWithServer,
      stops: stops ?? this.stops,
    );
  }

  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    final rawStops = (json['stops'] as List<dynamic>?) ?? [];
    return ItineraryModel(
      id: (json['id'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      provinceId: (json['province_id'] as num?)?.toInt() ?? 1,
      provinceName: (json['province_name'] ?? 'TP. Hồ Chí Minh').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      totalDays: (json['total_days'] as num?)?.toInt() ?? 1,
      isTemplate: json['is_template'] as bool? ?? false,
      isSyncedWithServer: json['is_synced_with_server'] as bool? ?? true,
      stops: rawStops
          .map((e) => ItineraryStopModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'province_id': provinceId,
        'province_name': provinceName,
        'title': title,
        'description': description,
        'total_days': totalDays,
        'is_template': isTemplate,
        'is_synced_with_server': isSyncedWithServer,
        'stops': stops.map((s) => s.toJson()).toList(),
      };
}

class ContentReportRecord {
  final int id;
  final String targetType;
  final int targetId;
  final String targetName;
  final String issueType;
  final String description;
  final String status;
  final String createdAt;

  const ContentReportRecord({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.issueType,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
  });
}
