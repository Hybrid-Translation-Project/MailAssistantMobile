import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

/// Kullanıcının hatırlatıcı ve tarama sıklığı tercihleri (/settings/preferences).
/// Hatırlatıcı alanları GÜN, tarama aralıkları DAKİKA cinsindendir.
class UserPreferences {
  final bool reminderDraftEnabled;
  final int reminderDraftDays;
  final bool reminderAiPendingEnabled;
  final int reminderAiPendingDays;
  final bool reminderAwaitingReplyEnabled;
  final int reminderAwaitingReplyDays;
  final int inboxCheckInterval;
  final int sentCheckInterval;
  final int whatsappCheckInterval;
  final int telegramCheckInterval;

  UserPreferences({
    required this.reminderDraftEnabled,
    required this.reminderDraftDays,
    required this.reminderAiPendingEnabled,
    required this.reminderAiPendingDays,
    required this.reminderAwaitingReplyEnabled,
    required this.reminderAwaitingReplyDays,
    required this.inboxCheckInterval,
    required this.sentCheckInterval,
    required this.whatsappCheckInterval,
    required this.telegramCheckInterval,
  });

  static bool _b(dynamic v, [bool def = false]) => v is bool ? v : def;
  static int _i(dynamic v, int def) => v is num ? v.toInt() : def;

  factory UserPreferences.fromJson(Map<String, dynamic> j) => UserPreferences(
        reminderDraftEnabled: _b(j['reminder_draft_enabled']),
        reminderDraftDays: _i(j['reminder_draft_days'], 3),
        reminderAiPendingEnabled: _b(j['reminder_ai_pending_enabled']),
        reminderAiPendingDays: _i(j['reminder_ai_pending_days'], 3),
        reminderAwaitingReplyEnabled: _b(j['reminder_awaiting_reply_enabled']),
        reminderAwaitingReplyDays: _i(j['reminder_awaiting_reply_days'], 3),
        inboxCheckInterval: _i(j['inbox_check_interval'], 5),
        sentCheckInterval: _i(j['sent_check_interval'], 15),
        whatsappCheckInterval: _i(j['whatsapp_check_interval'], 15),
        telegramCheckInterval: _i(j['telegram_check_interval'], 15),
      );
}

class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<UserPreferences> getPreferences() async {
    try {
      final resp = await _dio.get('/settings/preferences');
      return UserPreferences.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Sadece verilen alanları günceller (backend kısmi güncellemeyi destekler).
  Future<void> update(Map<String, dynamic> fields) async {
    try {
      await _dio.post('/settings/preferences', data: fields);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
