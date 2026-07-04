import 'package:local_auth/local_auth.dart';
import '../core/storage/secure_storage_service.dart';

/// Cihaz kilidi (yüz tanıma / parmak izi / cihaz PIN'i) ile uygulama açılışını
/// güvence altına alır. Tercih cihazda saklanır — sunucu bilmez, bu tamamen
/// yerel bir güvenlik katmanıdır.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isEnabled() => SecureStorageService.instance.getBiometricEnabled();
  Future<void> setEnabled(bool value) =>
      SecureStorageService.instance.setBiometricEnabled(value);

  /// Cihaz biyometrik veya PIN/şifre doğrulaması yapabiliyor mu?
  Future<bool> canCheck() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Kullanıcıdan doğrulama ister. Cihaz PIN/şifresine de izin verir
  /// (biometricOnly: false), böylece parmak izi kayıtlı olmayan cihazlarda da çalışır.
  Future<bool> authenticate({String reason = 'Devam etmek için kimliğinizi doğrulayın'}) async {
    try {
      // local_auth 3.x: seçenekler adlandırılmış parametrelere taşındı.
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
