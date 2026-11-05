import 'package:dio/dio.dart';

import '../core/config/app_config.dart';
import '../core/services/smart_ai_assistant_service.dart';

/// Kết quả một lượt chat với trợ lý: câu trả lời + hành động đã thực thi thật.
class AssistantReply {
  const AssistantReply({
    required this.reply,
    required this.tips,
    required this.applied,
    required this.rejected,
  });

  final String reply;
  final List<String> tips;
  final List<Map<String, dynamic>> applied;
  final List<String> rejected;
}

class AssistantApi {
  AssistantApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 5),
            ));

  final Dio _dio;

  Future<AssistantReply> chat({required String message, int? tripId}) async {
    try {
      final resp = await _dio.post('/assistant/chat', data: {
        'message': message,
        if (tripId != null) 'trip_id': tripId,
      });
      final data = resp.data as Map<String, dynamic>;
      final replyText = (data['reply'] ?? '').toString();
      if (replyText.isNotEmpty) {
        return AssistantReply(
          reply: replyText,
          tips: ((data['tips'] as List?) ?? const []).map((e) => e.toString()).toList(),
          applied: ((data['actions_applied'] as List?) ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          rejected: ((data['actions_rejected'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
      }
    } catch (_) {
      // Khi Backend offline hoặc môi trường Mobile không có server,
      // tự động kích hoạt bộ não SmartAiAssistantService tiếng Việt chạy offline ngay lập tức!
    }
    return SmartAiAssistantService.processQuestion(message: message, tripId: tripId);
  }
}
