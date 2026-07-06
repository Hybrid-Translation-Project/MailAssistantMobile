import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/admin_models.dart';

/// Admin panel API'leri (/admin/*). Tüm endpoint'ler sunucuda require_admin
/// ile korunur — admin olmayan token 403 alır, ekranlar bunu zarifçe yönetir.
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<AdminUser>> listUsers() async {
    try {
      final resp = await _dio.get('/admin/users');
      return ((resp.data as List?) ?? const [])
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> createUser({
    required String username,
    required String fullName,
    required String password,
    required String role,
    String? notificationEmail,
    bool forcePasswordChange = true,
  }) async {
    try {
      await _dio.post('/admin/users', data: {
        'username': username,
        'full_name': fullName,
        'password': password,
        'role': role,
        'notification_email':
            (notificationEmail == null || notificationEmail.isEmpty)
                ? null
                : notificationEmail,
        'force_password_change': forcePasswordChange,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Aktif/pasif durumunu tersine çevirir; sunucunun döndüğü yeni durumu döner.
  Future<bool> toggleUser(String userId) async {
    try {
      final resp = await _dio.patch('/admin/users/$userId/toggle');
      return (resp.data as Map)['is_active'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> resetPassword(
    String userId,
    String newPassword, {
    bool forcePasswordChange = true,
  }) async {
    try {
      await _dio.post('/admin/users/$userId/reset-password', data: {
        'new_password': newPassword,
        'force_password_change': forcePasswordChange,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _dio.delete('/admin/users/$userId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminSystemStats> systemStats() async {
    try {
      final resp = await _dio.get('/admin/stats');
      return AdminSystemStats.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminAiStats> aiStats({int days = 30}) async {
    try {
      final resp =
          await _dio.get('/admin/ai-stats', queryParameters: {'days': days});
      return AdminAiStats.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminBackupStatus> backupStatus() async {
    try {
      final resp = await _dio.get('/admin/backup/status');
      return AdminBackupStatus.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
