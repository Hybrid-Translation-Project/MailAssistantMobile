import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/reminder_item.dart';

class RemindersService {
  RemindersService._();
  static final RemindersService instance = RemindersService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<ReminderItem>> getReminders() async {
    try {
      final resp = await _dio.get('/reminders/');
      final list = resp.data as List;
      return list.map((e) => ReminderItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markRead(String reminderId) async {
    try {
      await _dio.patch('/reminders/$reminderId/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> dismiss(String reminderId) async {
    try {
      await _dio.patch('/reminders/$reminderId/dismiss');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch('/reminders/mark-all-read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
