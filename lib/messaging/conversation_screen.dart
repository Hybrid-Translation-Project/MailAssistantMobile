import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../models/chat_message_item.dart';
import '../models/chat_summary.dart';
import '../services/messaging_service.dart';
import '../theme/app_colors.dart';

class ConversationScreen extends StatefulWidget {
  final MessagingPlatform platform;
  final ChatSummary chat;
  const ConversationScreen({super.key, required this.platform, required this.chat});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _loadingOlder = false;
  bool _hasMoreOlder = true;
  bool _sending = false;
  String? _error;
  List<ChatMessageItem> _messages = [];

  bool get _supportsOlderPaging => widget.platform == MessagingPlatform.whatsapp;

  @override
  void initState() {
    super.initState();
    _load();
    MessagingService.instance.markRead(widget.platform, widget.chat.jid);
    if (_supportsOlderPaging) _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingOlder || !_hasMoreOlder) return;
    // reverse:true listede en eski mesaja ulaşmak maxScrollExtent'e yaklaşmak demektir.
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 150) {
      _loadOlder();
    }
  }

  Future<void> _loadOlder() async {
    if (_messages.isEmpty) return;
    final oldest = _messages.first;
    if (oldest.receivedAt == null) {
      setState(() => _hasMoreOlder = false);
      return;
    }
    setState(() => _loadingOlder = true);
    try {
      final older = await MessagingService.instance.getMessages(
        widget.platform,
        widget.chat.jid,
        before: oldest.receivedAt!.toIso8601String(),
      );
      if (!mounted) return;
      setState(() {
        if (older.isEmpty) {
          _hasMoreOlder = false;
        } else {
          _messages = [...older, ..._messages];
        }
        _loadingOlder = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _loadingOlder = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await MessagingService.instance.getMessages(widget.platform, widget.chat.jid);
      if (!mounted) return;
      setState(() {
        _messages = messages;
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

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await MessagingService.instance.sendText(
        widget.platform,
        recipient: widget.chat.jid,
        message: text,
        isGroup: widget.chat.isGroup,
        chatName: widget.chat.name,
      );
      _messageController.clear();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        title: Text(widget.chat.name, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(c)),
          _buildComposer(c),
        ],
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
    if (_messages.isEmpty) {
      return Center(child: Text('Henüz mesaj yok', style: TextStyle(color: c.textSecondary)));
    }
    final showOlderFooter = _supportsOlderPaging && _loadingOlder;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + (showOlderFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _messages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2)),
            );
          }
          return _buildBubble(_messages[_messages.length - 1 - index], c);
        },
      ),
    );
  }

  Widget _buildBubble(ChatMessageItem message, AppColors c) {
    final bg = message.isMine ? const Color(0xFF6366F1) : c.card;
    final textColor = message.isMine ? Colors.white : c.textPrimary;
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: message.isMine ? null : Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.mediaCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file, size: 14, color: textColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text('${message.mediaCount} medya', style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 11)),
                  ],
                ),
              ),
            Text(message.body.isEmpty ? '(içerik yok)' : message.body, style: TextStyle(color: textColor, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(AppColors c) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.cardBorder),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Mesaj yaz...',
                    hintStyle: TextStyle(color: c.textHint),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                  : const Icon(Icons.send, color: Color(0xFF6366F1)),
            ),
          ],
        ),
      ),
    );
  }
}
