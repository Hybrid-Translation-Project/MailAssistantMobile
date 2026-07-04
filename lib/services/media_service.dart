import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';

/// WhatsApp/Telegram üzerinden gelen bir medya dosyası (/media/gallery).
class MediaItem {
  final String id;
  final String platform; // whatsapp | telegram
  final String fileType; // image | video | document
  final String fileName;
  final String localPath;
  final int fileSizeBytes;
  final String sender;
  final String caption;
  final DateTime? receivedAt;
  final bool existsOnDisk;

  MediaItem({
    required this.id,
    required this.platform,
    required this.fileType,
    required this.fileName,
    required this.localPath,
    required this.fileSizeBytes,
    required this.sender,
    required this.caption,
    required this.receivedAt,
    required this.existsOnDisk,
  });

  bool get isImage => fileType == 'image';
  bool get isVideo => fileType == 'video';

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        id: (j['id'] ?? '').toString(),
        platform: (j['platform'] ?? '').toString(),
        fileType: (j['file_type'] ?? 'document').toString(),
        fileName: (j['file_name'] ?? 'dosya').toString(),
        localPath: (j['local_path'] ?? '').toString(),
        fileSizeBytes: (j['file_size_bytes'] as num?)?.toInt() ?? 0,
        sender: (j['sender'] ?? '').toString(),
        caption: (j['caption'] ?? '').toString(),
        receivedAt: j['received_at'] != null ? DateTime.tryParse(j['received_at'].toString()) : null,
        existsOnDisk: j['exists_on_disk'] ?? false,
      );
}

class MediaPage {
  final int total;
  final List<MediaItem> items;
  MediaPage({required this.total, required this.items});
}

class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<MediaPage> getGallery({
    String? platform, // whatsapp | telegram | null(hepsi)
    String? folder, // images | video | documents | null
    String? search,
    String sort = 'newest',
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final resp = await _dio.get('/media/gallery', queryParameters: {
        'platform': ?platform,
        'folder': ?folder,
        if (search != null && search.isNotEmpty) 'search': search,
        'sort': sort,
        'skip': skip,
        'limit': limit,
      });
      final data = resp.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return MediaPage(total: (data['total'] as num?)?.toInt() ?? items.length, items: items);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Dosyanın stream URL'ini kurar (auth-free /media/file endpoint'i).
  Future<String?> fileUrl(String localPath) async {
    final server = await SecureStorageService.instance.getServerUrl();
    if (server == null || server.isEmpty || localPath.isEmpty) return null;
    return '$server/api/v1/media/file?path=${Uri.encodeQueryComponent(localPath)}';
  }
}
