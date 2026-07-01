import 'package:flutter/material.dart';
import 'app_root.dart';
import 'core/network/api_client.dart';
import 'login/login.dart';
import 'services/push_notification_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Oturum tamamen geçersiz kaldığında (refresh de başarısız) herhangi bir
  // ekrandan login'e dönebilmek için merkezi navigator key kullanılır.
  ApiClient.instance.onUnauthorized = () {
    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  };

  // Firebase projesi henüz tanımlı değilse sessizce no-op olur (bkz. PushNotificationService).
  PushNotificationService.instance.initialize();

  runApp(const MagiAiApp());
}

class MagiAiApp extends StatelessWidget {
  const MagiAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Magi AI',
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F0EB),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
            ),
          ),
          home: const AppRoot(),
        );
      },
    );
  }
}
