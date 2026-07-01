import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/stat_card.dart';

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<StatCard>> getStatCards() async {
    try {
      final resp = await _dio.get('/dashboard/stats-cards');
      final list = resp.data as List;
      return list.map((e) => StatCard.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Home ekranındaki 4 sayısal kart (Bekleyen Mail, Onay Bekleyen İş,
  /// Kayıtlı Kişi, Hatırlatıcı) için ham sayaçlar.
  Future<Map<String, int>> getHomeCounts() async {
    try {
      final statsResp = await _dio.get('/dashboard/stats');
      final stats = statsResp.data as Map<String, dynamic>;
      int reminderCount = 0;
      try {
        final reminderResp = await _dio.get('/reminders/unread-count');
        reminderCount = (reminderResp.data['count'] as num?)?.toInt() ?? 0;
      } catch (_) {
        // Hatırlatıcı sayısı alınamazsa 0 göster, tüm ekranı bozma.
      }
      return {
        'pending_mails': (stats['pending_mails'] as num?)?.toInt() ?? 0,
        'pending_tasks': (stats['pending_tasks'] as num?)?.toInt() ?? 0,
        'total_contacts': (stats['total_contacts'] as num?)?.toInt() ?? 0,
        'reminders': reminderCount,
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
