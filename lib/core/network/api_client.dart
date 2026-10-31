import '../storage/offline_cache_service.dart';
import 'dio_client.dart';

/// Lớp `ApiClient` kế thừa từ `DioApiClient` (`dio` + `Hive` Offline Cache)
/// đảm bảo tương thích ngược với toàn bộ các màn hình và bài kiểm thử hiện hữu.
class ApiClient extends DioApiClient {
  ApiClient({
    super.baseUrl,
    OfflineCacheService? cacheService,
  }) : super(cacheService: cacheService);
}
