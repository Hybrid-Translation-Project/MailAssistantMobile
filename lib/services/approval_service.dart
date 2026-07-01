import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/mail_summary.dart';

/// "Onay Bekleyen İş" kuyruğu — WAITING_APPROVAL durumundaki AI taslakları.
class ApprovalService {
  ApprovalService._();
  static final ApprovalService instance = ApprovalService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Sırada bekleyen mail yoksa null döner.
  Future<MailDetail?> nextMail() async {
    try {
      final resp = await _dio.get('/next-mail');
      final data = resp.data as Map<String, dynamic>;
      if (data['message'] == 'NO_MAIL') return null;
      return MailDetail.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> approve(String mailId) async {
    try {
      await _dio.post('/mail/$mailId/approve');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> cancel(String mailId) async {
    try {
      await _dio.post('/mail/$mailId/cancel');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
