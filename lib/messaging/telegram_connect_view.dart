import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/telegram_connection_service.dart';
import '../theme/app_colors.dart';

enum _TgStep { choose, qrWaiting, phoneEntry, codeEntry, twoFaEntry }

/// Telegram userbot bağlantı sihirbazı — QR ya da telefon numarasıyla giriş.
class TelegramConnectView extends StatefulWidget {
  final VoidCallback onConnected;
  const TelegramConnectView({super.key, required this.onConnected});

  @override
  State<TelegramConnectView> createState() => _TelegramConnectViewState();
}

class _TelegramConnectViewState extends State<TelegramConnectView> {
  _TgStep _step = _TgStep.choose;
  Timer? _qrTimer;
  String? _qrBase64;
  String? _error;
  bool _busy = false;

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _qrTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _startQr() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resp = await TelegramConnectionService.instance.qrStart();
      if (resp['success'] != true) {
        setState(() => _error = resp['error']?.toString() ?? 'QR başlatılamadı.');
        return;
      }
      setState(() {
        _step = _TgStep.qrWaiting;
        _qrBase64 = resp['qr'] as String?;
      });
      _qrTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollQr());
    } catch (e) {
      setState(() => _error = 'QR başlatılamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pollQr() async {
    try {
      final resp = await TelegramConnectionService.instance.qrPoll();
      final status = resp['status'] as String?;
      if (status == 'connected') {
        _qrTimer?.cancel();
        widget.onConnected();
        return;
      }
      if (!mounted) return;
      if (resp['qr'] != null) setState(() => _qrBase64 = resp['qr'] as String);
    } catch (_) {
      // Polling hatası kritik değil, bir sonraki denemede düzelebilir.
    }
  }

  Future<void> _sendPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resp = await TelegramConnectionService.instance.sendPhone(phone);
      if (resp['success'] == true) {
        setState(() => _step = _TgStep.codeEntry);
      } else {
        setState(() => _error = resp['error']?.toString() ?? 'Kod gönderilemedi.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resp = await TelegramConnectionService.instance.verifyCode(code);
      if (resp['success'] == true) {
        if (resp['status'] == 'waiting_2fa') {
          setState(() => _step = _TgStep.twoFaEntry);
        } else {
          widget.onConnected();
        }
      } else {
        setState(() => _error = resp['error']?.toString() ?? 'Kod hatalı.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify2fa() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resp = await TelegramConnectionService.instance.verify2fa(password);
      if (resp['success'] == true) {
        widget.onConnected();
      } else {
        setState(() => _error = resp['error']?.toString() ?? '2FA şifresi hatalı.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 48, color: c.textHint),
            const SizedBox(height: 16),
            Text('Telegram Bağla', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildStepContent(c),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(AppColors c) {
    switch (_step) {
      case _TgStep.choose:
        return Column(
          children: [
            _actionButton('QR Kod ile Bağlan', Icons.qr_code_2, _busy ? null : _startQr),
            const SizedBox(height: 12),
            _actionButton('Telefon Numarası ile Bağlan', Icons.phone_outlined, _busy ? null : () => setState(() => _step = _TgStep.phoneEntry)),
          ],
        );
      case _TgStep.qrWaiting:
        return _qrBase64 == null
            ? const CircularProgressIndicator(color: Color(0xFF6366F1))
            : Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Image.memory(
                  base64Decode(_qrBase64!.replaceFirst(RegExp(r'^data:image\/\w+;base64,'), '')),
                  width: 220,
                  height: 220,
                ),
              );
      case _TgStep.phoneEntry:
        return Column(
          children: [
            _textField(_phoneController, 'Telefon numarası (+90...)', c),
            const SizedBox(height: 16),
            _actionButton('Kod Gönder', Icons.send, _busy ? null : _sendPhone),
          ],
        );
      case _TgStep.codeEntry:
        return Column(
          children: [
            _textField(_codeController, 'SMS/Telegram kodu', c),
            const SizedBox(height: 16),
            _actionButton('Doğrula', Icons.check, _busy ? null : _verifyCode),
          ],
        );
      case _TgStep.twoFaEntry:
        return Column(
          children: [
            _textField(_passwordController, '2FA şifresi', c, obscure: true),
            const SizedBox(height: 16),
            _actionButton('Doğrula', Icons.check, _busy ? null : _verify2fa),
          ],
        );
    }
  }

  Widget _textField(TextEditingController controller, String hint, AppColors c, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textHint),
        filled: true,
        fillColor: c.inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
