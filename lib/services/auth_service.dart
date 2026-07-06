import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/realtime_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_info.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Sunucunun ayakta olup olmadığını ve kurulumunun tamamlanıp
  /// tamamlanmadığını kontrol eder (server URL ekranında kullanılır).
  Future<bool> checkServerReachable(String baseUrl) async {
    try {
      final probe = Dio(BaseOptions(
        baseUrl: '$baseUrl/api/v1',
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
      await probe.get('/auth/check-setup');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserInfo> login(String username, String password) async {
    try {
      final deviceToken = await SecureStorageService.instance.getDeviceToken();
      final resp = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
        'device_token': deviceToken ?? '',
      });
      final data = resp.data as Map<String, dynamic>;
      await SecureStorageService.instance.setAccessToken(data['access_token']);
      await SecureStorageService.instance.setRefreshToken(data['refresh_token']);
      final userInfo = UserInfo.fromJson(data['user']);
      // Admin girişi (Yönetici Paneli butonu) için rol bilgisini sakla.
      await SecureStorageService.instance.setIsAdmin(userInfo.role == 'admin');
      return userInfo;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<bool> verifyToken() async {
    try {
      await _dio.get('/auth/verify-token');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<LicenseStatus> licenseStatus() async {
    final resp = await _dio.get('/auth/license-status');
    final status = LicenseStatus.fromJson(resp.data as Map<String, dynamic>);
    // Her başarılı kontrolde admin bayrağını tazele (boot + login sonrası
    // zaten çağrılıyor) — web'den yetki verilmiş/alınmışsa yeni girişte yansır.
    await SecureStorageService.instance.setIsAdmin(status.isAdmin);
    return status;
  }

  /// FCM token ilk elde edildiğinde ya da yenilendiğinde çağrılır.
  Future<void> registerDeviceToken(String token) async {
    try {
      await _dio.post('/auth/device-token', data: {'device_token': token});
    } catch (_) {
      // Push token kaydı başarısız olsa bile uygulama akışını bozmamalı.
    }
  }

  Future<void> logout() async {
    RealtimeService.instance.disconnect();
    try {
      final deviceToken = await SecureStorageService.instance.getDeviceToken();
      if (deviceToken != null) {
        await _dio.delete('/auth/device-token', data: {'device_token': deviceToken});
      }
    } catch (_) {
      // Sunucuya ulaşılamasa bile lokal oturum temizlenmeli.
    }
    await SecureStorageService.instance.clearAuth();
  }
}
