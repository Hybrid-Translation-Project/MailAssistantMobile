import 'package:flutter/material.dart';
import 'login/login.dart';

/// Uygulamanın başlangıç noktası
void main() {
  runApp(const MagiAiApp());
}

/// Ana uygulama widget'ı — Tüm tema ve rota ayarları burada yapılır.
class MagiAiApp extends StatelessWidget {
  const MagiAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Sağ üstteki "DEBUG" bandını kaldırır
      debugShowCheckedModeBanner: false,

      title: 'Magi AI',

      // Uygulama genelinde geçerli olan koyu tema ayarları
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),

      // Uygulama başladığında ilk gösterilecek ekran
      home: const LoginScreen(),
    );
  }
}
