import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/contact_item.dart';

class ContactsService {
  ContactsService._();
  static final ContactsService instance = ContactsService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<ContactItem>> getContacts() async {
    try {
      final resp = await _dio.get('/contacts/');
      final list = resp.data as List;
      return list.map((e) => ContactItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<bool> toggleVip(String contactId) async {
    try {
      final resp = await _dio.patch('/contacts/$contactId/vip');
      return resp.data['is_vip'] as bool;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> toggleAiProcessing(String contactId, bool enabled) async {
    try {
      await _dio.patch('/contacts/$contactId/ai-processing', data: {'enabled': enabled});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteContact(String contactId) async {
    try {
      await _dio.delete('/contacts/$contactId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
