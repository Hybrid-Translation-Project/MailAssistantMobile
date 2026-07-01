import 'package:flutter/material.dart';
import '../contacts/contacts_screen.dart';
import '../core/network/api_exception.dart';
import '../services/voice_service.dart';
import '../theme/app_colors.dart';
import '../writer/writer_compose_screen.dart';

/// Sesli komut ekranı. Şu an yazılı komut girişi kullanır — gerçek
/// mikrofon/konuşma-metin dönüşümü mic izni + kayıt eklentisi gerektirir,
/// ayrı bir adımda eklenebilir. Backend zaten POST /voice/command ile
/// sesli dosya da kabul ediyor.
class VoiceCommandScreen extends StatefulWidget {
  const VoiceCommandScreen({super.key});

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final _textController = TextEditingController();
  bool _loading = false;
  String? _error;
  VoiceCommandResult? _result;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await VoiceService.instance.sendTextCommand(text);
      if (!mounted) return;
      setState(() => _result = result);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleAction(VoiceCommandAction action) {
    if (action.action != 'navigate' || action.target == null) return;
    switch (action.target) {
      case '/contacts':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
        break;
      case '/writer':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WriterComposeScreen()));
        break;
      case '/dashboard':
        Navigator.pop(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu yönlendirme henüz mobilde desteklenmiyor.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sesli Komut', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mic, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ne yapmamı istersin? Örn: "yeni mail yaz", "kişilere git"',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Komutunu yaz...',
                      hintStyle: TextStyle(color: c.textHint),
                      filled: true,
                      fillColor: c.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.cardBorder)),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                      : const Icon(Icons.send, color: Color(0xFF6366F1)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFEF4444))),
            if (_result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.cardBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_result!.message, style: TextStyle(color: c.textPrimary, fontSize: 14)),
                    if (_result!.actions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _result!.actions
                            .where((a) => a.action == 'navigate')
                            .map((a) => ActionChip(
                                  label: Text(a.target ?? a.action),
                                  onPressed: () => _handleAction(a),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
