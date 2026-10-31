/// Model chuyến đi (Module 1, 2, 6) — khớp schema `/trips` của backend.
library;

class TripStop {
  const TripStop({
    required this.id,
    required this.order,
    required this.kind,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.stayMins,
    this.placeId,
    this.arriveAt,
    this.travelMinsFromPrev,
    this.distanceKmFromPrev,
    this.estCost,
    this.source = 'manual',
    this.note,
  });

  final int id;
  final int order;
  final String kind;
  final String? placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? arriveAt;
  final int stayMins;
  final int? travelMinsFromPrev;
  final double? distanceKmFromPrev;
  final int? estCost;
  final String source;
  final String? note;

  factory TripStop.fromJson(Map<String, dynamic> json) => TripStop(
        id: (json['id'] as num).toInt(),
        order: (json['order'] as num?)?.toInt() ?? 0,
        kind: (json['kind'] ?? 'destination').toString(),
        placeId: json['place_id']?.toString(),
        name: (json['name'] ?? '').toString(),
        address: (json['address'] ?? '').toString(),
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        arriveAt: json['arrive_at']?.toString(),
        stayMins: (json['stay_mins'] as num?)?.toInt() ?? 60,
        travelMinsFromPrev: (json['travel_mins_from_prev'] as num?)?.toInt(),
        distanceKmFromPrev: (json['distance_km_from_prev'] as num?)?.toDouble(),
        estCost: (json['est_cost'] as num?)?.toInt(),
        source: (json['source'] ?? 'manual').toString(),
        note: json['note']?.toString(),
      );
}

class TripDay {
  const TripDay({
    required this.id,
    required this.dayNumber,
    required this.stops,
    this.date,
    this.title,
  });

  final int id;
  final int dayNumber;
  final String? date;
  final String? title;
  final List<TripStop> stops;

  factory TripDay.fromJson(Map<String, dynamic> json) => TripDay(
        id: (json['id'] as num).toInt(),
        dayNumber: (json['day_number'] as num).toInt(),
        date: json['date']?.toString(),
        title: json['title']?.toString(),
        stops: ((json['stops'] as List?) ?? const [])
            .map((e) => TripStop.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class TripTotals {
  const TripTotals({
    this.distanceKm = 0,
    this.travelMins = 0,
    this.estCost = 0,
    this.spent = 0,
    this.stopCount = 0,
  });

  final double distanceKm;
  final int travelMins;
  final int estCost;
  final int spent;
  final int stopCount;

  factory TripTotals.fromJson(Map<String, dynamic> json) => TripTotals(
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        travelMins: (json['travel_mins'] as num?)?.toInt() ?? 0,
        estCost: (json['est_cost'] as num?)?.toInt() ?? 0,
        spent: (json['spent'] as num?)?.toInt() ?? 0,
        stopCount: (json['stop_count'] as num?)?.toInt() ?? 0,
      );
}

class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.status,
    required this.originName,
    required this.originLat,
    required this.originLng,
    required this.totalDays,
    required this.partySize,
    required this.vehicle,
    required this.budgetLevel,
    required this.days,
    required this.totals,
    this.destinationName,
    this.destinationLat,
    this.destinationLng,
    this.startDate,
    this.budgetAmount,
    this.preferences = const [],
    this.aiGenerated = false,
    this.shareToken,
  });

  final int id;
  final String title;
  final String status;
  final String originName;
  final double originLat;
  final double originLng;
  final String? destinationName;
  final double? destinationLat;
  final double? destinationLng;
  final String? startDate;
  final int totalDays;
  final int partySize;
  final String vehicle;
  final String budgetLevel;
  final int? budgetAmount;
  final List<String> preferences;
  final List<TripDay> days;
  final TripTotals totals;
  final bool aiGenerated;
  final String? shareToken;

  int get stopCount => totals.stopCount;

  /// Tâm bản đồ: ưu tiên điểm đến, không có thì điểm đi.
  ({double lat, double lng}) get centerPoint => (
        lat: destinationLat ?? originLat,
        lng: destinationLng ?? originLng,
      );

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: (json['id'] as num).toInt(),
        title: (json['title'] ?? '').toString(),
        status: (json['status'] ?? 'draft').toString(),
        originName: (json['origin_name'] ?? '').toString(),
        originLat: (json['origin_lat'] as num).toDouble(),
        originLng: (json['origin_lng'] as num).toDouble(),
        destinationName: json['destination_name']?.toString(),
        destinationLat: (json['destination_lat'] as num?)?.toDouble(),
        destinationLng: (json['destination_lng'] as num?)?.toDouble(),
        startDate: json['start_date']?.toString(),
        totalDays: (json['total_days'] as num?)?.toInt() ?? 1,
        partySize: (json['party_size'] as num?)?.toInt() ?? 2,
        vehicle: (json['vehicle'] ?? 'motorbike').toString(),
        budgetLevel: (json['budget_level'] ?? 'balanced').toString(),
        budgetAmount: (json['budget_amount'] as num?)?.toInt(),
        preferences: ((json['preferences'] as List?) ?? const []).map((e) => e.toString()).toList(),
        days: ((json['days'] as List?) ?? const [])
            .map((e) => TripDay.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        totals: TripTotals.fromJson((json['totals'] as Map<String, dynamic>?) ?? const {}),
        aiGenerated: json['ai_generated'] == true,
        shareToken: json['share_token']?.toString(),
      );
}
