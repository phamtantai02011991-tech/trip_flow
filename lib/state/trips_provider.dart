import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/trip.dart';
import '../data/trips_api.dart';

/// Provider cho tầng API và danh sách/chi tiết chuyến đi.
final tripsApiProvider = Provider<TripsApi>((ref) => TripsApi());

final tripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) {
  return ref.watch(tripsApiProvider).list();
});

final tripDetailProvider = FutureProvider.autoDispose.family<Trip, int>((ref, tripId) {
  return ref.watch(tripsApiProvider).detail(tripId);
});
