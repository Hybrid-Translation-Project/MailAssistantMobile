import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class MailAccount {
  final String id;
  final String email;
  final bool isActive;
  MailAccount({required this.id, required this.email, required this.isActive});

  factory MailAccount.fromJson(Map<String, dynamic> json) => MailAccount(
        id: json['id'].toString(),
        email: json['email'] ?? '',
        isActive: json['is_active'] ?? false,
      );
}

class AccountsService {
  AccountsService._();
  static final AccountsService instance = AccountsService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<MailAccount>> getAccounts() async {
    try {
      final resp = await _dio.get('/accounts/');
      final list = resp.data as List;
      return list.map((e) => MailAccount.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
