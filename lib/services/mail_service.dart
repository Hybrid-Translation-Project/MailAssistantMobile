import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/mail_summary.dart';

class InboxPage {
  final List<MailSummary> mails;
  final int page;
  final int totalPages;
  InboxPage({required this.mails, required this.page, required this.totalPages});
  bool get hasMore => page < totalPages;
}

class MailService {
  MailService._();
  static final MailService instance = MailService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<InboxPage> getInbox({int page = 1}) async {
    try {
      final resp = await _dio.get('/dashboard/inbox', queryParameters: {'page': page});
      final data = resp.data as Map<String, dynamic>;
      final mails = (data['mails'] as List).map((e) => MailSummary.fromJson(e as Map<String, dynamic>)).toList();
      return InboxPage(
        mails: mails,
        page: (data['page'] as num?)?.toInt() ?? page,
        totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<MailSummary>> getArchive() async {
    try {
      final resp = await _dio.get('/dashboard/archive');
      final mails = resp.data as List;
      return mails.map((e) => MailSummary.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Backend thread'i mail listesi olarak döner; en son mail asıl gösterilecek olandır.
  Future<List<MailDetail>> getMailThread(String mailId) async {
    try {
      final resp = await _dio.get('/dashboard/mail/$mailId');
      final list = resp.data as List;
      return list.map((e) => MailDetail.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> moveToFolder(String mailId, String folder) async {
    try {
      await _dio.patch('/dashboard/mail/$mailId', data: {'folder': folder});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteMail(String mailId) async {
    try {
      await _dio.delete('/dashboard/mail/$mailId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
