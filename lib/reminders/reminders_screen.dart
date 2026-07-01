import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../models/reminder_item.dart';
import '../services/reminders_service.dart';
import '../theme/app_colors.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _loading = true;
  String? _error;
  List<ReminderItem> _reminders = [];

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
      final reminders = await RemindersService.instance.getReminders();
      if (!mounted) return;
      setState(() {
        _reminders = reminders;
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

  Future<void> _markAllRead() async {
    try {
      await RemindersService.instance.markAllRead();
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _dismiss(ReminderItem r) async {
    setState(() => _reminders.remove(r));
    try {
      await RemindersService.instance.dismiss(r.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      _load();
    }
  }

  Future<void> _markRead(ReminderItem r) async {
    if (r.isRead) return;
    try {
      await RemindersService.instance.markRead(r.id);
      _load();
    } on ApiException catch (_) {
      // sessizce yut, kritik değil
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
        title: Text('Hatırlatıcılar', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          if (_reminders.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tümünü Okundu Yap', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12)),
            ),
        ],
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
    if (_reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 56, color: c.textHint),
            const SizedBox(height: 12),
            Text('Hatırlatıcı yok', style: TextStyle(color: c.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final r = _reminders[index];
          return Dismissible(
            key: ValueKey(r.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _dismiss(r),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            child: InkWell(
              onTap: () => _markRead(r),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: r.isRead ? c.cardBorder : const Color(0xFF6366F1).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    if (!r.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.mailSubject,
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 14,
                                  fontWeight: r.isRead ? FontWeight.normal : FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(r.mailFrom, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (r.triggerAt != null)
                      Text('${r.triggerAt!.day}/${r.triggerAt!.month}', style: TextStyle(color: c.textHint, fontSize: 11)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
