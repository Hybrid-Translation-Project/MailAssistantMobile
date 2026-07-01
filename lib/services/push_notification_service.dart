import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/storage/secure_storage_service.dart';
import 'auth_service.dart';

/// FCM push bildirim kurulumu.
///
/// ÖNEMLİ: Bu servis, her müşteri kurulumunun kendi Firebase projesini
/// tanımlamasını gerektirir (android/app/google-services.json ve
/// ios/Runner/GoogleService-Info.plist buraya eklenmeden bu dosyalar
/// oluşturulamaz — gerçek proje kimlik bilgileri içerir, üretilemez).
/// O yüzden her adım try/catch ile korunuyor: Firebase projesi henüz
/// kurulmamışsa uygulama çökmez, sadece push bildirimleri çalışmaz.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;

  /// Uygulama açılışında (oturum var/yok fark etmeksizin) bir kez çağrılır.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;

      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        SecureStorageService.instance.setDeviceToken(token);
        AuthService.instance.registerDeviceToken(token);
      });
    } catch (e) {
      // Firebase projesi tanımlı değil (google-services.json / GoogleService-Info.plist
      // eksik) — push bildirimleri devre dışı kalır, uygulamanın geri kalanı çalışmaya devam eder.
    }
  }

  /// Login sonrası ya da oto-login sonrası çağrılır: token'ı alıp backend'e kaydeder.
  Future<void> registerCurrentToken() async {
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await SecureStorageService.instance.setDeviceToken(token);
      await AuthService.instance.registerDeviceToken(token);
    } catch (_) {
      // Sessizce yut — push isteğe bağlı bir özellik.
    }
  }
}
