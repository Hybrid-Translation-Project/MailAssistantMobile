import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../services/scheduled_email_service.dart';
import '../theme/app_colors.dart';

/// Zamanlanmış mailleri listeler ve iptal etmeyi sağlar.
class ScheduledEmailsScreen extends StatefulWidget {
  const ScheduledEmailsScreen({super.key});

  @override
  State<ScheduledEmailsScreen> createState() => _ScheduledEmailsScreenState();
}

class _ScheduledEmailsScreenState extends State<ScheduledEmailsScreen> {
  bool _loading = true;
  String? _error;
  List<ScheduledEmailItem> _items = [];
  final Set<String> _busy = {};

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
      final items = await ScheduledEmailService.instance.list();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _cancel(ScheduledEmailItem item) async {
    setState(() => _busy.add(item.id));
    try {
      await ScheduledEmailService.instance.cancel(item.id);
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  ({Color color, String label}) _statusInfo(String status) {
    switch (status) {
      case 'scheduled':
        return (color: const Color(0xFF6366F1), label: 'Zamanlandı');
      case 'sending':
        return (color: const Color(0xFFF59E0B), label: 'Gönderiliyor');
      case 'sent':
        return (color: const Color(0xFF22C55E), label: 'Gönderildi');
      case 'failed':
        return (color: const Color(0xFFEF4444), label: 'Başarısız');
      case 'cancelled':
        return (color: const Color(0xFF94A3B8), label: 'İptal edildi');
      default:
        return (color: const Color(0xFF94A3B8), label: status);
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
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
        title: Text('Zamanlanmış Mailler', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: c.textSecondary)))
              : _items.isEmpty
                  ? Center(child: Text('Zamanlanmış mail yok.', style: TextStyle(color: c.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, i) => _buildCard(_items[i], c),
                      ),
                    ),
    );
  }

  Widget _buildCard(ScheduledEmailItem item, AppColors c) {
    final s = _statusInfo(item.status);
    final canCancel = item.status == 'scheduled' || item.status == 'sending';
    final busy = _busy.contains(item.id);
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
          Row(
            children: [
              Expanded(
                child: Text(item.subject,
                    style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: s.color.withValues(alpha: 0.4)),
                ),
                child: Text(s.label, style: TextStyle(color: s.color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: c.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(item.toEmails.join(', '),
                    style: TextStyle(color: c.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: c.textHint),
              const SizedBox(width: 4),
              Text(_fmtDate(item.scheduledForLocal), style: TextStyle(color: c.textSecondary, fontSize: 12)),
              if (item.attachments.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.attach_file, size: 14, color: c.textHint),
                const SizedBox(width: 2),
                Text('${item.attachments.length}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ],
            ],
          ),
          if (item.errorMessage != null && item.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
          ],
          if (canCancel) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: busy ? null : () => _cancel(item),
                icon: busy
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)))
                    : const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 16),
                label: const Text('İptal Et', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
