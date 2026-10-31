import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../storage/offline_cache_service.dart';
import '../utils/app_state.dart';

/// Provider cung cấp `OfflineCacheService` (Hive NoSQL Offline-first)
final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  return OfflineCacheService.instance;
});

/// Provider cung cấp `DioApiClient` (Dio + Interceptor + Hive Cache)
final dioClientProvider = Provider<DioApiClient>((ref) {
  final cache = ref.watch(offlineCacheServiceProvider);
  return DioApiClient(cacheService: cache);
});

/// Provider cung cấp `TripFlowAppState` cho toàn bộ các màn hình Flutter
final appStateProvider = Provider<TripFlowAppState>((ref) {
  final cache = ref.watch(offlineCacheServiceProvider);
  final dio = ref.watch(dioClientProvider);
  final state = TripFlowAppState(cacheService: cache, dioClient: dio);
  ref.onDispose(state.dispose);
  return state;
});

/// `StateNotifier` điều phối trạng thái ứng dụng TripFlow theo chuẩn Riverpod
class AppControllerNotifier extends StateNotifier<TripFlowAppState> {
  AppControllerNotifier(super.state);

  void selectTab(int index) => state.setTabIndex(index);

  Future<void> refreshDataFromBackend() => state.syncFromBackend();

  void toggleOfflineMode(bool offline) => state.toggleOfflineSimulation(offline);
}

final appControllerProvider =
    StateNotifierProvider<AppControllerNotifier, TripFlowAppState>((ref) {
  final appState = ref.watch(appStateProvider);
  return AppControllerNotifier(appState);
});
