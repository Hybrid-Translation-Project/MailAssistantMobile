import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../services/accounts_service.dart';
import '../services/writer_service.dart';
import '../theme/app_colors.dart';

class WriterComposeScreen extends StatefulWidget {
  const WriterComposeScreen({super.key});

  @override
  State<WriterComposeScreen> createState() => _WriterComposeScreenState();
}

class _WriterComposeScreenState extends State<WriterComposeScreen> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _aiPromptController = TextEditingController();

  MailAccount? _selectedAccount;
  bool _loadingAccounts = true;
  bool _generating = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await AccountsService.instance.getAccounts();
      if (!mounted) return;
      final active = accounts.where((a) => a.isActive).toList();
      setState(() {
        _selectedAccount = active.isNotEmpty ? active.first : null;
        _loadingAccounts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAccounts = false);
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = 'AI için ne yazılacağını girin.');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final content = await WriterService.instance.generate(prompt: prompt, currentContent: _bodyController.text);
      if (!mounted) return;
      setState(() => _bodyController.text = content);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _send() async {
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (_selectedAccount == null) {
      setState(() => _error = 'Gönderen hesap bulunamadı. Önce web panelinden bir mail hesabı ekleyin.');
      return;
    }
    if (to.isEmpty || subject.isEmpty || body.isEmpty) {
      setState(() => _error = 'Alıcı, konu ve içerik gerekli.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await WriterService.instance.sendNew(
        senderEmail: _selectedAccount!.email,
        toEmail: to,
        subject: subject,
        body: body,
      );
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
        title: Text('Yeni Mail', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                : const Text('Gönder', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loadingAccounts
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_selectedAccount != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Gönderen: ${_selectedAccount!.email}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  ),
                _buildField(_toController, 'Alıcı e-posta', c),
                const SizedBox(height: 12),
                _buildField(_subjectController, 'Konu', c),
                const SizedBox(height: 12),
                _buildField(_bodyController, 'İçerik', c, maxLines: 10),
                const SizedBox(height: 20),
                Text('AI ile Yaz', style: TextStyle(color: c.sectionLabel, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildField(_aiPromptController, 'Ne yazmak istersin?', c, maxLines: 2)),
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
