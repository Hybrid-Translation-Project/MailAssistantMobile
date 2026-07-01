import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../mail/mail_detail_screen.dart';
import '../models/search_result.dart';
import '../services/search_service.dart';
import '../theme/app_colors.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  const SearchResultsScreen({super.key, required this.initialQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);
  bool _loading = true;
  String? _error;
  List<SearchResultItem> _results = [];

  @override
  void initState() {
    super.initState();
    _search(widget.initialQuery);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await SearchService.instance.search(query.trim());
      if (!mounted) return;
      setState(() {
        _results = results;
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

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'whatsapp':
        return Icons.chat_bubble_outline;
      case 'telegram':
        return Icons.send_outlined;
      default:
        return Icons.mail_outline;
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
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: 'Ara...',
            hintStyle: TextStyle(color: c.textHint),
            border: InputBorder.none,
          ),
          onSubmitted: _search,
        ),
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
    if (_results.isEmpty) {
      return Center(
        child: Text('Sonuç bulunamadı', style: TextStyle(color: c.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final r = _results[index];
        return InkWell(
          onTap: () {
            if (r.platform == 'mail') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MailDetailScreen(mailId: r.id)));
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Bu platform için detay ekranı yakında aktif olacak.')));
            }
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
              children: [
                Icon(_platformIcon(r.platform), color: const Color(0xFF6366F1), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title,
                          style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(r.senderName, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                      if (r.preview.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(r.preview, style: TextStyle(color: c.textHint, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
