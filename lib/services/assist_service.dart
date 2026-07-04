import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

/// AI yardımcı işlemleri: mail özeti ve etiket önerisi.
/// Backend: /assist/summarize, /assist/suggest-label (Ollama ile üretir).
class AssistService {
  AssistService._();
  static final AssistService instance = AssistService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Mailin kısa özetini döner. Backend senkronize bir mailse kayıtlı özeti,
  /// değilse anlık AI özeti üretir.
  Future<String> summarize({
    required String subject,
    required String body,
    String? messageId,
  }) async {
    try {
      final resp = await _dio.post('/assist/summarize', data: {
        'subject': subject,
        'body': body,
        if (messageId != null && messageId.isNotEmpty) 'message_id': messageId,
      });
      return (resp.data['summary'] ?? '').toString();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Mail içeriğine göre tek kelimelik bir etiket önerir.
  Future<String> suggestLabel({
    required String subject,
    required String body,
    List<String> existingLabels = const [],
  }) async {
    try {
      final resp = await _dio.post('/assist/suggest-label', data: {
        'subject': subject,
        'body': body,
        'existing_labels': existingLabels,
      });
      return (resp.data['label'] ?? '').toString();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
