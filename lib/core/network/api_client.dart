import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Tüm backend isteklerinin geçtiği tek Dio örneği.
///
/// baseUrl sabit değildir: her müşteri kendi sunucusuna kurulum yaptığı için
/// adres cihazda saklanır ve her istekte okunur. Access token süresi dolunca
/// refresh token ile otomatik yenilenir; refresh de başarısız olursa
/// [onUnauthorized] çağrılıp oturum temizlenir (login ekranına dönülür).
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final baseUrl = await SecureStorageService.instance.getServerUrl();
        if (baseUrl != null && baseUrl.isNotEmpty) {
          options.baseUrl = '$baseUrl/api/v1';
        }

        if (!_isAuthFreePath(options.path)) {
          final token = await SecureStorageService.instance.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        if (error.response?.statusCode == 401 && !_isAuthFreePath(path)) {
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            try {
              final retried = await _retry(error.requestOptions);
              return handler.resolve(retried);
            } catch (_) {
              // Retry de başarısız oldu, aşağıdaki genel hataya düş.
            }
          }
          await SecureStorageService.instance.clearAuth();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  /// AppRoot tarafından atanır: oturum tamamen geçersiz olduğunda
  /// kullanıcıyı login ekranına yönlendirmek için kullanılır.
  void Function()? onUnauthorized;

  Future<bool>? _refreshFuture;

  bool _isAuthFreePath(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/check-setup');
  }

  /// Aynı anda birden fazla istek 401 alırsa tek bir refresh çağrısına düşürür.
  Future<bool> _refreshAccessToken() {
    _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await SecureStorageService.instance.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final baseUrl = await SecureStorageService.instance.getServerUrl();
      final refreshDio = Dio(BaseOptions(baseUrl: '$baseUrl/api/v1'));
      final resp = await refreshDio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      final newAccessToken = resp.data['access_token'] as String;
      await SecureStorageService.instance.setAccessToken(newAccessToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await SecureStorageService.instance.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
