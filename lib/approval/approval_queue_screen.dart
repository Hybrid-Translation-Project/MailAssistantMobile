import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../models/mail_summary.dart';
import '../services/approval_service.dart';
import '../theme/app_colors.dart';

/// "Onay Bekleyen İş" — AI'nın oluşturduğu ve gönderilmeden önce insan
/// onayı bekleyen taslak mailler. FIFO sırayla tek tek gösterilir.
class ApprovalQueueScreen extends StatefulWidget {
  const ApprovalQueueScreen({super.key});

  @override
  State<ApprovalQueueScreen> createState() => _ApprovalQueueScreenState();
}

class _ApprovalQueueScreenState extends State<ApprovalQueueScreen> {
  bool _loading = true;
  bool _acting = false;
  String? _error;
  MailDetail? _current;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mail = await ApprovalService.instance.nextMail();
      if (!mounted) return;
      setState(() {
        _current = mail;
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

  Future<void> _act(Future<void> Function(String) action) async {
    final mail = _current;
    if (mail == null) return;
    setState(() => _acting = true);
    try {
      await action(mail.id);
      await _loadNext();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting = false);
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
        title: Text('Onay Bekleyen İşler', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(c),
    );
  }

  Widget _buildBody(AppColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: c.textSecondary)));
    }
    if (_current == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 56, color: c.textHint),
            const SizedBox(height: 12),
            Text('Onay bekleyen iş kalmadı 🎉', style: TextStyle(color: c.textSecondary)),
          ],
        ),
      );
    }

    final mail = _current!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mail.subject, style: TextStyle(color: c.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Alıcı: ${mail.fromEmail}', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    Text(mail.body, style: TextStyle(color: c.textPrimary, fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _acting ? null : () => _act(ApprovalService.instance.cancel),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.close, color: Color(0xFFEF4444), size: 18),
                  label: const Text('Reddet', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _acting ? null : () => _act(ApprovalService.instance.approve),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text('Onayla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
