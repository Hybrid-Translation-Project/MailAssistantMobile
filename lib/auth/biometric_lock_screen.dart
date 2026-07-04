import 'package:flutter/material.dart';
import '../services/biometric_service.dart';

/// Biyometrik kilit açık olduğunda MainPage öncesi gösterilir.
/// Açılışta otomatik doğrulama ister; başarısız olursa "Tekrar Dene" sunar.
class BiometricLockScreen extends StatefulWidget {
  /// Doğrulama başarılı olunca çağrılır (kilit ekranının context'i ile).
  final void Function(BuildContext context) onUnlocked;
  const BiometricLockScreen({super.key, required this.onUnlocked});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final ok = await BiometricService.instance.authenticate(
      reason: 'Uygulamaya girmek için kimliğinizi doğrulayın',
    );
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked(context);
    } else {
      setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Uygulama Kilitli',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Devam etmek için kimliğinizi doğrulayın',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 32),
            if (_authenticating)
              const CircularProgressIndicator(color: Color(0xFF6366F1))
            else
              ElevatedButton.icon(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.fingerprint, color: Colors.white),
                label: const Text('Tekrar Dene', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}
