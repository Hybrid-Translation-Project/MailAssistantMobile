import 'package:flutter/material.dart';
import 'login/login.dart'; // Bizim yazdığımız ekranı içeri aktarıyor

void main() {
  runApp(const MagiAiApp());
}

class MagiAiApp extends StatelessWidget {
  const MagiAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // Sağ üstteki gıcık DEBUG yazısını kaldırır
      title: 'Magi AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primarySwatch: Colors.deepPurple,
      ),
      home: const LoginScreen(), // Uygulama direkt bizim ekrandan başlar
    );
  }
}
