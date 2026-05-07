import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plana masaüstündeki gibi mavimsi gradient (degrade) efekti veriyoruz
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF1E293B), // Sol üstten gelen açık lacivert
              Color(0xFF0F172A), // Zemin rengi koyu lacivert
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Robot ikonu kaldırıldı, başlık doğrudan başlıyor
                  const Text(
                    "Magi AI",
                    style: TextStyle(
                      fontSize:
                          36, // İkon olmadığı için yazıyı bir tık büyüttüm
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Devam etmek için panel yetkilerinizi doğrulayın.",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Kullanıcı Adı Input
                  _buildTextField(
                    label: "Kullanıcı Adı",
                    icon: Icons.person,
                    hint: "kullanici_adi",
                  ),
                  const SizedBox(height: 24),

                  // Şifre Input
                  _buildTextField(
                    label: "Panel Giriş Şifresi",
                    icon: Icons.lock,
                    hint: "Panel şifrenizi girin",
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),

                  // Güvenli Giriş Yap Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF6366F1,
                        ), // Morumsu buton rengi
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // TODO: API'ye giriş isteği atılacak kısım
                      },
                      icon: const Icon(Icons.shield, color: Colors.white),
                      label: const Text(
                        "Güvenli Giriş Yap",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Inputları temiz tutmak için oluşturduğumuz özel Widget
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1E293B), // Koyu input rengi
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
