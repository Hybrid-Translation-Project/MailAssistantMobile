import 'package:dio/dio.dart';

/// Backend'in `{"detail": "..."}` formatındaki hatalarını kullanıcıya
/// gösterilebilecek Türkçe bir mesaja çevirir.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map && data['detail'] != null) {
      return ApiException(data['detail'].toString(), statusCode: statusCode);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Sunucuya bağlanılamadı. Bağlantınızı kontrol edin.');
      case DioExceptionType.connectionError:
        return ApiException('Sunucuya ulaşılamıyor. Sunucu adresini kontrol edin.');
      default:
        return ApiException('Beklenmeyen bir hata oluştu.', statusCode: statusCode);
    }
  }

  @override
  String toString() => message;
}
