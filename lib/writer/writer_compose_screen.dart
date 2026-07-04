import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../services/accounts_service.dart';
import '../services/scheduled_email_service.dart';
import '../services/writer_service.dart';
import '../theme/app_colors.dart';
import 'scheduled_emails_screen.dart';

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
  bool _scheduling = false;
  String? _error;

  final List<PlatformFile> _pickedFiles = [];

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

  Future<void> _pickFiles() async {
    // file_picker 11: pickFiles artık statik metot.
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.path != null) _pickedFiles.add(f);
      }
    });
  }

  /// Alanları doğrular; eksikse hata yazıp false döner.
  bool _validate() {
    if (_selectedAccount == null) {
      setState(() => _error = 'Gönderen hesap bulunamadı. Önce web panelinden bir mail hesabı ekleyin.');
      return false;
    }
    if (_toController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      setState(() => _error = 'Alıcı, konu ve içerik gerekli.');
      return false;
    }
    return true;
  }

  Future<void> _schedule() async {
    if (!_validate()) return;

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(minutes: 10)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))),
    );
    if (time == null || !mounted) return;

    final scheduledFor = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (scheduledFor.isBefore(now.add(const Duration(seconds: 30)))) {
      setState(() => _error = 'Zamanlama ileri bir tarih/saat olmalı.');
      return;
    }

    setState(() {
      _scheduling = true;
      _error = null;
    });
    try {
      // Önce ekleri yükle.
      final uploaded = <ScheduledAttachment>[];
      for (final f in _pickedFiles) {
        uploaded.add(await ScheduledEmailService.instance.uploadAttachment(f.path!, f.name));
      }
      await ScheduledEmailService.instance.schedule(
        fromEmail: _selectedAccount!.email,
        toEmails: [_toController.text.trim()],
        subject: _subjectController.text.trim(),
        bodyHtml: _bodyController.text.trim(),
        scheduledFor: scheduledFor,
        attachments: uploaded,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mail zamanlandı.')));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _scheduling = false);
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
          IconButton(
            tooltip: 'Zamanlanmışlar',
            icon: Icon(Icons.history_outlined, color: c.textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScheduledEmailsScreen()),
            ),
          ),
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
                const SizedBox(height: 20),
                _buildAttachmentsSection(c),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                ],
              ],
            ),
      bottomNavigationBar: _loadingAccounts ? null : _buildScheduleBar(c),
    );
  }

  Widget _buildAttachmentsSection(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('EKLER (zamanlı gönderim)',
                style: TextStyle(color: c.sectionLabel, fontSize: 11, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file, size: 16, color: Color(0xFF6366F1)),
              label: const Text('Dosya Ekle', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12)),
            ),
          ],
        ),
        if (_pickedFiles.isEmpty)
          Text('Ekli dosyalar yalnızca "Zamanla" ile gönderilir.',
              style: TextStyle(color: c.textHint, fontSize: 11))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pickedFiles.asMap().entries.map((e) {
              final f = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file_outlined, size: 15, color: c.textSecondary),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(f.name,
                          style: TextStyle(color: c.textPrimary, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _pickedFiles.removeAt(e.key)),
                      child: Icon(Icons.close, size: 14, color: c.textHint),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildScheduleBar(AppColors c) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: OutlinedButton.icon(
          onPressed: _scheduling ? null : _schedule,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF6366F1)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: _scheduling
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
              : const Icon(Icons.schedule, color: Color(0xFF6366F1), size: 18),
          label: const Text('Zamanla', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
        ),
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
