import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../login/login.dart';

/// Backend lisans zorunluluğu açıkken (LICENSE_ENFORCED=1) lisans geçersizse
/// bu ekran gösterilir. Admin'e "lisans aktive et" mesajı, normal kullanıcıya
/// "yöneticinize başvurun" mesajı gösterilir — panel tarafındaki davranışla aynı.
class LicenseGateScreen extends StatelessWidget {
  final String? reason;
  final bool isAdmin;

  const LicenseGateScreen({super.key, this.reason, required this.isAdmin});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock_outlined, size: 64, color: Color(0xFFF59E0B)),
              const SizedBox(height: 24),
              const Text(
                'Lisans Geçersiz',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                isAdmin
                    ? 'Bu kurulumun lisansı geçersiz veya süresi dolmuş. Lisansı aktive etmek için web panelinden Admin > Lisans bölümüne gidin.'
                    : 'Bu kurulumun lisansı geçersiz. Lütfen sistem yöneticinize başvurun.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              if (reason != null) ...[
                const SizedBox(height: 8),
                Text(reason!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white38)),
              ],
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => _logout(context),
                child: const Text('Çıkış Yap', style: TextStyle(color: Color(0xFF8B5CF6))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
