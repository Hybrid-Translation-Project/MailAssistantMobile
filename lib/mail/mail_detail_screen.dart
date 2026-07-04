import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/mail_summary.dart';
import '../services/assist_service.dart';
import '../services/mail_service.dart';
import '../theme/app_colors.dart';
import 'reply_composer_screen.dart';

/// Bir mail thread'ini gösterir (backend thread'i tek liste olarak döner,
/// en altta en yeni mesaj gösterilir).
class MailDetailScreen extends StatefulWidget {
  final String mailId;
  const MailDetailScreen({super.key, required this.mailId});

  @override
  State<MailDetailScreen> createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends State<MailDetailScreen> {
  bool _loading = true;
  String? _error;
  List<MailDetail> _thread = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final thread = await MailService.instance.getMailThread(widget.mailId);
      if (!mounted) return;
      setState(() {
        _thread = thread;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _archive() async {
    try {
      await MailService.instance.moveToFolder(widget.mailId, 'archive');
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete() async {
    try {
      await MailService.instance.deleteMail(widget.mailId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Yanıtlanacak/AI'a verilecek asıl mesaj: thread'te bize gelen (owner olmayan)
  /// en yeni mesaj; hiç yoksa listedeki son mesaj.
  MailDetail? get _target {
    if (_thread.isEmpty) return null;
    for (final m in _thread.reversed) {
      if (!m.isOwner) return m;
    }
    return _thread.last;
  }

  Future<void> _reply() async {
    final target = _target;
    if (target == null) return;
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReplyComposerScreen(
          mailId: target.id,
          subject: target.subject,
          toEmail: target.fromEmail,
          initialDraft: target.replyDraft.isNotEmpty ? target.replyDraft : null,
        ),
      ),
    );
    if (sent == true && mounted) {
      Navigator.pop(context, true); // yanıt gönderildi → mail arşivlendi, listeyi tazele
    }
  }

  Future<void> _summarize() async {
    final target = _target;
    if (target == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
    );
    try {
      final summary = await AssistService.instance.summarize(
        subject: target.subject,
        body: target.body,
        messageId: target.messageId,
      );
      if (!mounted) return;
      Navigator.pop(context); // loader
      _showSummarySheet(summary);
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // loader
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _suggestLabel() async {
    final target = _target;
    if (target == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
    );
    try {
      final label = await AssistService.instance.suggestLabel(
        subject: target.subject,
        body: target.body,
        existingLabels: target.tags,
      );
      if (!mounted) return;
      Navigator.pop(context); // loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label.isEmpty ? 'Etiket önerilemedi.' : 'Önerilen etiket: $label')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // loader
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Ek dosyanın mutlak indirme URL'ini cihaza kayıtlı sunucu adresine göre kurar.
  /// Backend'de saklanan url localhost içerdiğinden host'u kullanmayız; sadece
  /// IMAP (download) / OAuth (oauth-download) ayrımı için rawUrl'e bakarız.
  Future<Uri?> _attachmentUri(MailAttachment att, String messageId) async {
    final server = await SecureStorageService.instance.getServerUrl();
    if (server == null || server.isEmpty || messageId.isEmpty) return null;
    final base = '$server/api/v1/attachments';
    final endpoint = att.isOauth ? 'oauth-download' : 'download';
    final mid = Uri.encodeComponent(messageId);
    final name = Uri.encodeComponent(att.filename);
    return Uri.parse('$base/$endpoint/$mid/$name');
  }

  Future<void> _openAttachment(MailAttachment att, String messageId) async {
    final uri = await _attachmentUri(att, messageId);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ek dosya adresi oluşturulamadı.')),
      );
      return;
    }
    if (att.isImage) {
      if (!mounted) return;
      _showImagePreview(uri, att.filename);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya açılamadı.')),
      );
    }
  }

  void _showImagePreview(Uri uri, String filename) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(filename,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                  onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  uri.toString(),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                        ),
                  errorBuilder: (context, error, stack) => Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('Görsel yüklenemedi', style: TextStyle(color: c.textHint)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSummarySheet(String summary) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 20),
                  const SizedBox(width: 8),
                  Text('AI Özeti', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    summary.isEmpty ? 'Özet üretilemedi.' : summary,
                    style: TextStyle(color: c.textPrimary, fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: Text('Mail', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(Icons.reply_rounded, color: c.textSecondary), onPressed: _thread.isEmpty ? null : _reply),
          IconButton(icon: Icon(Icons.archive_outlined, color: c.textSecondary), onPressed: _archive),
          IconButton(icon: Icon(Icons.delete_outline, color: c.textSecondary), onPressed: _delete),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: c.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _thread.length,
                    itemBuilder: (context, index) => _buildMessageCard(_thread[index], c),
                  ),
                ),
      bottomNavigationBar: (_loading || _error != null || _thread.isEmpty)
          ? null
          : _buildAiActionBar(c),
    );
  }

  Widget _buildAiActionBar(AppColors c) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _summarize,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 16),
                label: Text('AI Özet', style: TextStyle(color: c.textSecondary, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _suggestLabel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.label_outline, color: Color(0xFF0EA5E9), size: 16),
                label: Text('Etiket Öner', style: TextStyle(color: c.textSecondary, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(MailDetail mail, AppColors c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mail.subject, style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(mail.isOwner ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14, color: mail.isOwner ? const Color(0xFF6366F1) : const Color(0xFF16A34A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(mail.fromEmail, style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ),
              if (mail.date != null)
                Text(
                  '${mail.date!.day}/${mail.date!.month}/${mail.date!.year}',
                  style: TextStyle(color: c.textHint, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(mail.body, style: TextStyle(color: c.textPrimary, fontSize: 14, height: 1.4)),
          if (mail.attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: c.divider, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_file_rounded, size: 14, color: c.textSecondary),
                const SizedBox(width: 6),
                Text('Ekler (${mail.attachments.length})',
                    style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mail.attachments
                  .map((att) => _buildAttachmentChip(att, mail.messageId, c))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentChip(MailAttachment att, String messageId, AppColors c) {
    return GestureDetector(
      onTap: () => _openAttachment(att, messageId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(att.isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                size: 16, color: const Color(0xFF6366F1)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(att.filename,
                  style: TextStyle(color: c.textPrimary, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            Icon(att.isImage ? Icons.visibility_outlined : Icons.download_rounded,
                size: 14, color: c.textHint),
          ],
        ),
      ),
    );
  }
}
