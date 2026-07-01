import 'package:flutter/material.dart';
import '../services/messaging_service.dart';
import '../services/telegram_connection_service.dart';
import '../services/whatsapp_connection_service.dart';
import '../theme/app_colors.dart';
import 'chat_list_view.dart';
import 'telegram_connect_view.dart';
import 'whatsapp_connect_view.dart';

class MessagingHubScreen extends StatefulWidget {
  const MessagingHubScreen({super.key});

  @override
  State<MessagingHubScreen> createState() => _MessagingHubScreenState();
}

class _MessagingHubScreenState extends State<MessagingHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text('Mesajlar', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: c.textSecondary,
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [Tab(text: 'WhatsApp'), Tab(text: 'Telegram')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PlatformChatsTab(platform: MessagingPlatform.whatsapp),
          _PlatformChatsTab(platform: MessagingPlatform.telegram),
        ],
      ),
    );
  }
}

class _PlatformChatsTab extends StatefulWidget {
  final MessagingPlatform platform;
  const _PlatformChatsTab({required this.platform});

  @override
  State<_PlatformChatsTab> createState() => _PlatformChatsTabState();
}

class _PlatformChatsTabState extends State<_PlatformChatsTab> {
  bool _loading = true;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _loading = true);
    try {
      bool connected;
      if (widget.platform == MessagingPlatform.whatsapp) {
        final status = await WhatsAppConnectionService.instance.status();
        connected = status['connected'] == true;
      } else {
        final status = await TelegramConnectionService.instance.status();
        connected = status['connected'] == true;
      }
      if (!mounted) return;
      setState(() {
        _connected = connected;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    if (!_connected) {
      return widget.platform == MessagingPlatform.whatsapp
          ? WhatsAppConnectView(onConnected: _checkConnection)
          : TelegramConnectView(onConnected: _checkConnection);
    }
    return ChatListView(platform: widget.platform);
  }
}
