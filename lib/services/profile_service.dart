import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class ProfileInfo {
  final String fullName;
  final String signature;
  ProfileInfo({required this.fullName, required this.signature});

  factory ProfileInfo.fromJson(Map<String, dynamic> json) => ProfileInfo(
        fullName: json['full_name'] ?? '',
        signature: json['signature'] ?? '',
      );
}

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<ProfileInfo> getProfile() async {
    try {
      final resp = await _dio.get('/settings/profile');
      return ProfileInfo.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> updateProfile({required String fullName, required String signature}) async {
    try {
      await _dio.post('/settings/profile', data: {
        'full_name': fullName,
        'signature': signature,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    try {
      await _dio.post('/settings/password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
