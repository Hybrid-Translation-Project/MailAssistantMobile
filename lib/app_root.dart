import 'package:flutter/material.dart';
import 'auth/biometric_lock_screen.dart';
import 'auth/license_gate_screen.dart';
import 'auth/server_config_screen.dart';
import 'core/storage/secure_storage_service.dart';
import 'login/login.dart';
import 'mainpage/mainpage.dart';
import 'core/network/realtime_service.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/push_notification_service.dart';

/// Uygulama açılışında sırayla kontrol eder:
/// 1) Sunucu adresi tanımlı mı → değilse ServerConfigScreen
/// 2) Oturum token'ı var mı → yoksa LoginScreen
/// 3) Token geçerli mi (ApiClient 401'de otomatik refresh dener) → değilse LoginScreen
/// 4) Lisans geçerli mi → değilse LicenseGateScreen
/// 5) Hepsi tamamsa → MainPage (oto-login)
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    final serverUrl = await SecureStorageService.instance.getServerUrl();
    if (serverUrl == null || serverUrl.isEmpty) {
      _replaceWith(const ServerConfigScreen());
      return;
    }

    final accessToken = await SecureStorageService.instance.getAccessToken();
    if (accessToken == null) {
      _replaceWith(const LoginScreen());
      return;
    }

    final tokenValid = await AuthService.instance.verifyToken();
    if (!tokenValid) {
      _replaceWith(const LoginScreen());
      return;
    }

    try {
      final license = await AuthService.instance.licenseStatus();
      if (!license.valid) {
        _replaceWith(LicenseGateScreen(reason: license.reason, isAdmin: license.isAdmin));
        return;
      }
    } catch (_) {
      // Lisans servisi cevap veremiyorsa kullanıcıyı kilitleme; girişe devam et.
    }

    // Biyometrik/cihaz kilidi açıksa MainPage'den önce doğrulama iste.
    final biometricOn = await BiometricService.instance.isEnabled();
    if (biometricOn && await BiometricService.instance.canCheck()) {
      _replaceWith(BiometricLockScreen(onUnlocked: _startSessionFrom));
      return;
    }

    _startSession();
    _replaceWith(const MainPage());
  }

  /// Oturum yan etkilerini başlatır (push token + realtime).
  void _startSession() {
    PushNotificationService.instance.registerCurrentToken();
    RealtimeService.instance.connect();
  }

  /// Kilit ekranı doğrulamayı geçince çağrılır: oturumu başlatıp MainPage'e geçer.
  void _startSessionFrom(BuildContext ctx) {
    _startSession();
    Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
  }

  void _replaceWith(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      ),
    );
  }
}
