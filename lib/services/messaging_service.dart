import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/chat_message_item.dart';
import '../models/chat_summary.dart';

enum MessagingPlatform { whatsapp, telegram }

extension on MessagingPlatform {
  String get segment => this == MessagingPlatform.whatsapp ? 'whatsapp' : 'telegram';
}

/// WhatsApp ve Telegram için backend sözleşmeleri neredeyse aynı şekilde
/// tasarlanmış (chat listesi + mesaj listesi + gönder) — tek servis altında
/// birleştirilerek mobil tarafta kod tekrarı önlenir.
class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<ChatSummary>> getChats(MessagingPlatform platform) async {
    try {
      final resp = await _dio.get('/messaging/${platform.segment}/chats');
      final list = resp.data as List;
      return list.map((e) => ChatSummary.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// [before]: WhatsApp tarafında daha eski mesajları çekmek için (ISO tarih,
  /// en eski yüklü mesajın received_at'i). Telegram tarafında backend'de
  /// böyle bir imleç parametresi yok, bu yüzden orada yok sayılır.
  Future<List<ChatMessageItem>> getMessages(MessagingPlatform platform, String jid, {String? before}) async {
    try {
      final encoded = Uri.encodeComponent(jid);
      final resp = platform == MessagingPlatform.whatsapp
          ? await _dio.get('/messaging/whatsapp/chats/$encoded/messages', queryParameters: before != null ? {'before': before} : null)
          : await _dio.get('/messaging/telegram/messages', queryParameters: {'sender': jid, 'limit': 50});
      final list = resp.data as List;
      return list.map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> sendText(
    MessagingPlatform platform, {
    required String recipient,
    required String message,
    required bool isGroup,
    String chatName = '',
  }) async {
    try {
      await _dio.post('/messaging/${platform.segment}/send', data: {
        'recipient': recipient,
        'message': message,
        'chat_type': isGroup ? 'group' : 'direct',
        'chat_name': chatName,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markRead(MessagingPlatform platform, String jid) async {
    try {
      final encoded = Uri.encodeComponent(jid);
      if (platform == MessagingPlatform.whatsapp) {
        await _dio.post('/messaging/whatsapp/chats/$encoded/read');
      } else {
        await _dio.post('/messaging/telegram/chats/$encoded/read');
      }
    } on DioException catch (_) {
      // Okundu işaretleme kritik değil, sessizce yut.
    }
  }
}
