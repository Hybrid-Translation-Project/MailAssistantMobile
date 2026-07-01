import 'package:flutter/material.dart';
import '../auth/license_gate_screen.dart';
import '../auth/server_config_screen.dart';
import '../core/network/api_exception.dart';
import '../core/network/realtime_service.dart';
import '../mainpage/mainpage.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';

/// Giriş ekranı — Kullanıcı adı ve şifre ile giriş yapılır.
/// Hesaplar admin tarafından web panelinden oluşturulur; burada kayıt
/// ekranı yoktur (self-servis kayıt akışı yok).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Kullanıcı adı ve şifre gerekli.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.instance.login(username, password);
      if (!mounted) return;
      PushNotificationService.instance.registerCurrentToken();
      RealtimeService.instance.connect();

      final license = await AuthService.instance.licenseStatus();
      if (!mounted) return;

      if (!license.valid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LicenseGateScreen(reason: license.reason, isAdmin: license.isAdmin),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Giriş yapılamadı. Tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPasswordInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Şifremi Unuttum', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Şifre sıfırlama işlemi sistem yöneticiniz tarafından web panelinden yapılır. '
          'Lütfen yöneticinizle iletişime geçin.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    );
  }

  void _openServerConfig() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ServerConfigScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Arka plana koyu lacivert gradient efekti
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF1E293B), // Sol üst — açık lacivert
              Color(0xFF0F172A), // Zemin — koyu lacivert
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

                  // ─── Logo İkonu ───
                  _buildLogoIcon(),
                  const SizedBox(height: 24),

                  // ─── Başlık ───
                  const Text(
                    "Magi AI",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ─── Alt Başlık ───
                  const Text(
                    "Devam etmek için panel yetkilerinizi doğrulayın.",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // ─── Kullanıcı Adı Alanı ───
                  _buildTextField(
                    label: "Kullanıcı Adı",
                    icon: Icons.person,
                    hint: "kullanici_adi",
                    controller: _usernameController,
                  ),

                  const SizedBox(height: 24),

                  // ─── Şifre Alanı (göster/gizle toggle'lı) ───
                  _buildTextField(
                    label: "Panel Giriş Şifresi",
                    icon: Icons.lock,
                    hint: "Panel şifrenizi girin",
                    controller: _passwordController,
                    isPassword: true,
                  ),

                  const SizedBox(height: 16),

                  // ─── Beni Hatırla + Şifremi Unuttum Satırı ───
                  _buildRememberForgotRow(),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ─── Giriş Butonu ───
                  _buildLoginButton(),

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: _openServerConfig,
                    child: const Text(
                      "Farklı bir sunucuya bağlan",
                      style: TextStyle(fontSize: 12, color: Colors.white38, decoration: TextDecoration.underline),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Versiyon Bilgisi ───
                  Text(
                    "v1.0.0 — Magi AI",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.25),
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

  // ═══════════════════════════════════════════════════════════════
  //  YARDIMCI WIDGET'LAR
  // ═══════════════════════════════════════════════════════════════

  /// Mor gradient'li Shield logo ikonu oluşturur.
  Widget _buildLogoIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.shield_outlined,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  /// "Beni Hatırla" checkbox'ı ve "Şifremi Unuttum?" linkini yan yana gösterir.
  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        // Sol taraf — Beni Hatırla checkbox'ı
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberMe = !_rememberMe;
            });
          },
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF6366F1),
                  side: const BorderSide(
                    color: Colors.white38,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              const Text(
                "Beni Hatırla",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Sağ taraf — Şifremi Unuttum linki
        GestureDetector(
          onTap: _showForgotPasswordInfo,
          child: const Text(
            "Şifremi Unuttum?",
            style: TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

      ],
    );
  }

  /// "Güvenli Giriş Yap" butonu — basıldığında backend'e login isteği atar.
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _loading ? null : _submit,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Güvenli Giriş Yap",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Özelleştirilmiş text input alanı oluşturur.
  /// [isPassword] true ise şifre gizleme/gösterme toggle'ı eklenir.
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Üst kısımdaki ikon + etiket satırı
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

        // Input alanı
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1E293B),

            // Şifre alanı için göz ikonu toggle'ı
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                  )
                : null,

            // Normal durumdaki border
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24, width: 1),
            ),

            // Aktif olmayan durumdaki border
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24, width: 1),
            ),

            // Tıklanıp yazı yazılırken (focus) border — mor tonunda
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
