import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

/// Backend'de "/writer/writer/..." şeklinde iç içe prefix var (writer.py'nin
/// kendi router'ı hem dış prefix /writer hem de içeride ek /writer taşıyor).
/// Bu, mevcut sunucudaki gerçek yol — web tarafı da aynısını kullanıyor.
class WriterService {
  WriterService._();
  static final WriterService instance = WriterService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Serbest metin isteğinden AI ile mail içeriği üretir.
  Future<String> generate({required String prompt, String currentContent = ''}) async {
    try {
      final resp = await _dio.post('/writer/writer/generate', data: {
        'prompt': prompt,
        'current_content': currentContent,
      });
      return (resp.data['content'] ?? resp.data['draft'] ?? '').toString();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Yeni bir mail oluşturup gönderir (yanıt değil, sıfırdan compose).
  Future<void> sendNew({
    required String senderEmail,
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    try {
      await _dio.post('/writer/writer/send', data: {
        'mail_id': null,
        'sender_email': senderEmail,
        'to_email': toEmail,
        'subject': subject,
        'body': body,
        'ai_prompt': '',
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
