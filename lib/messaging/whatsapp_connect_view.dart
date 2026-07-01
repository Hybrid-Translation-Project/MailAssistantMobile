import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/whatsapp_connection_service.dart';
import '../theme/app_colors.dart';

/// WhatsApp henüz bağlı değilse gösterilen QR kod bağlantı ekranı.
/// Bağlantı sağlanınca [onConnected] tetiklenir.
class WhatsAppConnectView extends StatefulWidget {
  final VoidCallback onConnected;
  const WhatsAppConnectView({super.key, required this.onConnected});

  @override
  State<WhatsAppConnectView> createState() => _WhatsAppConnectViewState();
}

class _WhatsAppConnectViewState extends State<WhatsAppConnectView> {
  Timer? _timer;
  String? _qrBase64;
  String _status = 'loading';
  String? _error;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final data = await WhatsAppConnectionService.instance.getQr();
      if (!mounted) return;
      final status = data['status'] as String? ?? 'no_qr';
      if (status == 'connected') {
        _timer?.cancel();
        widget.onConnected();
        return;
      }
      setState(() {
        _status = status;
        _qrBase64 = data['qr'] as String?;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Bağlantı durumu alınamadı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 48, color: c.textHint),
            const SizedBox(height: 16),
            Text('WhatsApp Bağla', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Telefonunuzdaki WhatsApp > Bağlı Cihazlar bölümünden bu kodu okutun.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (_qrBase64 != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Image.memory(base64Decode(_qrBase64!.replaceFirst(RegExp(r'^data:image\/\w+;base64,'), '')), width: 220, height: 220),
              )
            else if (_status == 'loading' || _status == 'no_qr')
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
