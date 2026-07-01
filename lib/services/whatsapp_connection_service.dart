import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class WhatsAppConnectionService {
  WhatsAppConnectionService._();
  static final WhatsAppConnectionService instance = WhatsAppConnectionService._();

  Dio get _dio => ApiClient.instance.dio;

  /// {connected: bool, status: str, hasQR: bool} — bridge'in ham cevabı.
  Future<Map<String, dynamic>> status() async {
    try {
      final resp = await _dio.get('/messaging/whatsapp/qr/status');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// {status: "waiting_qr"|"connected"|"no_qr", qr: base64|null}
  Future<Map<String, dynamic>> getQr() async {
    try {
      final resp = await _dio.get('/messaging/whatsapp/qr');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> disconnect() async {
    try {
      await _dio.post('/messaging/whatsapp/qr/disconnect');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> reconnect() async {
    try {
      await _dio.post('/messaging/whatsapp/qr/reconnect');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
