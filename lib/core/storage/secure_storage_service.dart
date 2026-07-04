import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sunucu adresi ve oturum token'larını cihazda güvenli şekilde saklar.
/// Her müşteri kendi sunucusuna kurulum yaptığı için server URL sabit değildir.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage();

  static const _kServerUrl = 'server_url';
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kDeviceToken = 'device_token';
  static const _kBiometricEnabled = 'biometric_enabled';

  Future<String?> getServerUrl() => _storage.read(key: _kServerUrl);
  Future<void> setServerUrl(String url) => _storage.write(key: _kServerUrl, value: url);

  /// Cihaz kilidi (biyometrik/PIN) açılışta istenip istenmeyeceği — cihaz-yerel
  /// tercih, sunucuya gönderilmez.
  Future<bool> getBiometricEnabled() async =>
      (await _storage.read(key: _kBiometricEnabled)) == 'true';
  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _kBiometricEnabled, value: enabled ? 'true' : 'false');

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<void> setAccessToken(String token) => _storage.write(key: _kAccessToken, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<void> setRefreshToken(String token) => _storage.write(key: _kRefreshToken, value: token);

  Future<String?> getDeviceToken() => _storage.read(key: _kDeviceToken);
  Future<void> setDeviceToken(String token) => _storage.write(key: _kDeviceToken, value: token);

  /// Çıkış yapılınca oturum bilgisini temizler, sunucu adresini korur.
  Future<void> clearAuth() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  /// Sunucu adresi değiştirilirken (farklı kuruluma geçiş) her şeyi temizler.
  Future<void> clearAll() => _storage.deleteAll();
}
