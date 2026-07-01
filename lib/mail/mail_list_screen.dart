import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../core/network/realtime_service.dart';
import '../models/mail_summary.dart';
import '../services/mail_service.dart';
import '../theme/app_colors.dart';
import 'mail_detail_screen.dart';

enum MailFolder { inbox, archive }

/// GELENLER ve ARŞİV sekmelerinde kullanılan ortak mail listesi ekranı.
class MailListScreen extends StatefulWidget {
  final MailFolder folder;
  const MailListScreen({super.key, required this.folder});

  @override
  State<MailListScreen> createState() => _MailListScreenState();
}

class _MailListScreenState extends State<MailListScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<MailSummary> _mails = [];
  int _page = 1;
  bool _hasMore = false;
  StreamSubscription? _realtimeSub;
  final _scrollController = ScrollController();

  String get _title => widget.folder == MailFolder.inbox ? 'Gelen Kutusu' : 'Arşiv';

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.folder == MailFolder.inbox) {
      _realtimeSub = RealtimeService.instance.events.listen((event) {
        if (event['type'] == 'new_mail') _load();
      });
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.folder == MailFolder.inbox) {
        final result = await MailService.instance.getInbox();
        if (!mounted) return;
        setState(() {
          _mails = result.mails;
          _page = result.page;
          _hasMore = result.hasMore;
          _loading = false;
        });
      } else {
        final mails = await MailService.instance.getArchive();
        if (!mounted) return;
        setState(() {
          _mails = mails;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final result = await MailService.instance.getInbox(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _mails = [..._mails, ...result.mails];
        _page = result.page;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(_title, style: TextStyle(color: c.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: _buildBody(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: c.textSecondary)));
    }
    if (_mails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: c.textHint),
            const SizedBox(height: 12),
            Text('Burada henüz mail yok', style: TextStyle(color: c.textSecondary)),
          ],
        ),
      );
    }
    final showLoadingFooter = widget.folder == MailFolder.inbox && _loadingMore;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: widget.folder == MailFolder.inbox ? _scrollController : null,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: _mails.length + (showLoadingFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _mails.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2)),
            );
          }
          return _buildMailTile(_mails[index], c);
        },
      ),
    );
  }

  Widget _buildMailTile(MailSummary mail, AppColors c) {
    final isWaiting = mail.status == 'WAITING_APPROVAL';
    return InkWell(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => MailDetailScreen(mailId: mail.id)),
        );
        if (changed == true) _load();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isWaiting ? const Color(0xFFEA580C) : const Color(0xFF6366F1)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isWaiting ? Icons.hourglass_top_rounded : Icons.mail_outline,
                color: isWaiting ? const Color(0xFFEA580C) : const Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(mail.subject,
                            style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (mail.threadCount > 1)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.inputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${mail.threadCount}', style: TextStyle(color: c.textHint, fontSize: 10)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(mail.fromEmail, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(mail.bodyPreview,
                      style: TextStyle(color: c.textHint, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (mail.date != null)
              Text('${mail.date!.day}/${mail.date!.month}', style: TextStyle(color: c.textHint, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
