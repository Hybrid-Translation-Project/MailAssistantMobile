import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../core/network/realtime_service.dart';
import '../models/chat_summary.dart';
import '../services/messaging_service.dart';
import '../theme/app_colors.dart';
import 'conversation_screen.dart';

/// WhatsApp/Telegram sekmelerinin ortak sohbet listesi görünümü.
class ChatListView extends StatefulWidget {
  final MessagingPlatform platform;
  const ChatListView({super.key, required this.platform});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  bool _loading = true;
  String? _error;
  List<ChatSummary> _chats = [];
  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _load();
    final eventType = widget.platform == MessagingPlatform.whatsapp ? 'whatsapp_message_received' : 'telegram_message_received';
    _realtimeSub = RealtimeService.instance.events.listen((event) {
      if (event['type'] == eventType) _load();
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chats = await MessagingService.instance.getChats(widget.platform);
      if (!mounted) return;
      setState(() {
        _chats = chats;
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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: c.textSecondary)));
    }
    if (_chats.isEmpty) {
      return Center(child: Text('Henüz sohbet yok', style: TextStyle(color: c.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chats.length,
        itemBuilder: (context, index) => _buildTile(_chats[index], c),
      ),
    );
  }

  Widget _buildTile(ChatSummary chat, AppColors c) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConversationScreen(platform: widget.platform, chat: chat)),
        );
        _load();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (widget.platform == MessagingPlatform.whatsapp ? const Color(0xFF16A34A) : const Color(0xFF0EA5E9))
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                chat.isGroup ? Icons.groups_outlined : Icons.person_outline,
                color: widget.platform == MessagingPlatform.whatsapp ? const Color(0xFF16A34A) : const Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat.name,
                      style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(chat.lastMessageBody,
                      style: TextStyle(color: c.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (chat.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(10)),
                child: Text('${chat.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}
