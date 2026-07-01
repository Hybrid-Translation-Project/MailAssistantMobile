import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../models/mail_summary.dart';
import '../services/mail_service.dart';
import '../theme/app_colors.dart';

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
        ],
      ),
    );
  }
}
