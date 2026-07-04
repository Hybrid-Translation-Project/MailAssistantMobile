import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../services/mail_service.dart';
import '../theme/app_colors.dart';

/// Mevcut bir mail thread'ine yanıt yazma ekranı.
/// Gönderim backend'de "Re:" ekleyip imzalar ve maili arşivler (/writer/send).
/// AI ile taslak üretme /writer/generate (action=neutral) kullanır.
class ReplyComposerScreen extends StatefulWidget {
  final String mailId;
  final String subject;
  final String toEmail;
  final String? initialDraft;

  const ReplyComposerScreen({
    super.key,
    required this.mailId,
    required this.subject,
    required this.toEmail,
    this.initialDraft,
  });

  @override
  State<ReplyComposerScreen> createState() => _ReplyComposerScreenState();
}

class _ReplyComposerScreenState extends State<ReplyComposerScreen> {
  late final TextEditingController _bodyController;
  final _aiPromptController = TextEditingController();

  bool _generating = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController(text: widget.initialDraft ?? '');
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final draft = await MailService.instance.generateAiDraft(
        widget.mailId,
        currentContent: _bodyController.text,
        customPrompt: _aiPromptController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        if (draft.isNotEmpty) _bodyController.text = draft;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Yanıt içeriği boş olamaz.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await MailService.instance.sendReply(widget.mailId, body);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
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
        title: Text('Yanıtla', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                : const Text('Gönder', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Kime: ${widget.toEmail}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Konu: Re: ${widget.subject}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ),
          _buildField(_bodyController, 'Yanıtınızı yazın...', c, maxLines: 12),
          const SizedBox(height: 20),
          Text('AI ile Yanıtla', style: TextStyle(color: c.sectionLabel, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildField(_aiPromptController, 'Nasıl bir yanıt? (opsiyonel)', c, maxLines: 2)),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _generating ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _generating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, AppColors c, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textHint),
        filled: true,
        fillColor: c.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
      ),
    );
  }
}
