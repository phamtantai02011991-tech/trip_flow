import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Interceptor gắn Bearer Token hiện tại cho mọi client API của app.
///
/// Token được `TripFlowAppState` lưu vào `AppConfig.authToken` sau khi xác thực
/// OTP thành công, nhờ đó các module Trips/Places/Assistant gọi API với đúng
/// danh tính thay vì luôn chạy ở chế độ khách.
Interceptor authInterceptor() {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = AppConfig.authToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      final guestToken = AppConfig.guestToken;
      if (guestToken != null && guestToken.isNotEmpty) {
        options.headers['X-Guest-Token'] = guestToken;
      }
      handler.next(options);
    },
    onError: (error, handler) {
      // 401: token hết hạn → xoá để lần gọi sau chạy ở chế độ khách.
      if (error.response?.statusCode == 401) {
        AppConfig.authToken = null;
      }
      handler.next(error);
    },
  );
}
