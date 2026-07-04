import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../services/media_service.dart';
import '../theme/app_colors.dart';

/// WhatsApp/Telegram medya galerisi (/media/gallery).
class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  bool _loading = true;
  String? _error;
  List<MediaItem> _items = [];
  String _serverUrl = '';

  String? _platform; // null=hepsi
  String? _folder; // null=hepsi

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _serverUrl = (await SecureStorageService.instance.getServerUrl()) ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await MediaService.instance.getGallery(platform: _platform, folder: _folder);
      if (!mounted) return;
      setState(() {
        _items = page.items;
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

  String _fileUrl(String localPath) =>
      '$_serverUrl/api/v1/media/file?path=${Uri.encodeQueryComponent(localPath)}';

  Future<void> _openExternal(MediaItem item) async {
    final uri = Uri.parse(_fileUrl(item.localPath));
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dosya açılamadı.')));
    }
  }

  void _openImage(MediaItem item) {
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
                    child: Text(item.fileName,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                  onPressed: () => _openExternal(item),
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
                  _fileUrl(item.localPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, e, s) => Padding(
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
        title: Text('Medya Galerisi', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildFilters(c),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: c.textSecondary)))
                    : _items.isEmpty
                        ? Center(child: Text('Medya bulunamadı.', style: TextStyle(color: c.textSecondary)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, i) => _buildTile(_items[i], c),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppColors c) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          _chip(c, 'Tümü', _platform == null, () => _setPlatform(null)),
          _chip(c, 'WhatsApp', _platform == 'whatsapp', () => _setPlatform('whatsapp')),
          _chip(c, 'Telegram', _platform == 'telegram', () => _setPlatform('telegram')),
          Container(width: 1, height: 24, color: c.divider, margin: const EdgeInsets.symmetric(horizontal: 8)),
          _chip(c, 'Görseller', _folder == 'images', () => _setFolder('images')),
          _chip(c, 'Video', _folder == 'video', () => _setFolder('video')),
          _chip(c, 'Belgeler', _folder == 'documents', () => _setFolder('documents')),
        ],
      ),
    );
  }

  void _setPlatform(String? p) {
    setState(() => _platform = p);
    _load();
  }

  void _setFolder(String? f) {
    setState(() => _folder = _folder == f ? null : f); // aynısına basınca temizle
    _load();
  }

  Widget _chip(AppColors c, String label, bool active, VoidCallback onTap) {
    const accent = Color(0xFF6366F1);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.2) : c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? accent : c.cardBorder),
          ),
          child: Text(label,
              style: TextStyle(
                color: active ? accent : c.textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              )),
        ),
      ),
    );
  }

  Widget _buildTile(MediaItem item, AppColors c) {
    return GestureDetector(
      onTap: () => item.isImage ? _openImage(item) : _openExternal(item),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.isImage && item.existsOnDisk)
              Image.network(
                _fileUrl(item.localPath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _iconPlaceholder(item, c),
                loadingBuilder: (ctx, child, progress) =>
                    progress == null ? child : Center(child: Icon(Icons.image, color: c.textHint, size: 28)),
              )
            else
              _iconPlaceholder(item, c),
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  item.platform == 'whatsapp' ? Icons.chat : Icons.send,
                  size: 12,
                  color: item.platform == 'whatsapp' ? const Color(0xFF25D366) : const Color(0xFF229ED9),
                ),
              ),
            ),
            if (item.isVideo)
              const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 34)),
          ],
        ),
      ),
    );
  }

  Widget _iconPlaceholder(MediaItem item, AppColors c) {
    IconData icon;
    if (item.isVideo) {
      icon = Icons.videocam_outlined;
    } else if (item.isImage) {
      icon = Icons.image_outlined;
    } else {
      icon = Icons.insert_drive_file_outlined;
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: c.textHint, size: 30),
          const SizedBox(height: 6),
          Text(item.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textHint, fontSize: 10)),
        ],
      ),
    );
  }
}
