import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class TelegramConnectionService {
  TelegramConnectionService._();
  static final TelegramConnectionService instance = TelegramConnectionService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<Map<String, dynamic>> status() async {
    try {
      final resp = await _dio.get('/messaging/telegram/userbot/status');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> qrStart() async {
    try {
      final resp = await _dio.post('/messaging/telegram/userbot/qr/start');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> qrPoll() async {
    try {
      final resp = await _dio.get('/messaging/telegram/userbot/qr');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> sendPhone(String phone) async {
    try {
      final resp = await _dio.post('/messaging/telegram/userbot/phone', data: {'phone': phone});
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> verifyCode(String code) async {
    try {
      final resp = await _dio.post('/messaging/telegram/userbot/verify', data: {'code': code});
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> verify2fa(String password) async {
    try {
      final resp = await _dio.post('/messaging/telegram/userbot/verify-2fa', data: {'password': password});
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> disconnect() async {
    try {
      await _dio.post('/messaging/telegram/userbot/disconnect');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
