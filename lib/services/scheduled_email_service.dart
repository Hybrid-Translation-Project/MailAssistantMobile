import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

/// Zamanlanmış maile eklenmiş dosya referansı (GridFS).
class ScheduledAttachment {
  final String gridfsId;
  final String filename;
  final String contentType;
  final int sizeBytes;

  ScheduledAttachment({
    required this.gridfsId,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
  });

  factory ScheduledAttachment.fromJson(Map<String, dynamic> j) => ScheduledAttachment(
        gridfsId: (j['gridfs_id'] ?? '').toString(),
        filename: (j['filename'] ?? '').toString(),
        contentType: (j['content_type'] ?? '').toString(),
        sizeBytes: (j['size_bytes'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'gridfs_id': gridfsId,
        'filename': filename,
        'content_type': contentType,
        'size_bytes': sizeBytes,
      };
}

class ScheduledEmailItem {
  final String id;
  final String fromEmail;
  final List<String> toEmails;
  final String subject;
  final String status; // scheduled | sending | sent | failed | cancelled
  final DateTime? scheduledForLocal;
  final List<ScheduledAttachment> attachments;
  final String? errorMessage;

  ScheduledEmailItem({
    required this.id,
    required this.fromEmail,
    required this.toEmails,
    required this.subject,
    required this.status,
    required this.scheduledForLocal,
    required this.attachments,
    required this.errorMessage,
  });

  factory ScheduledEmailItem.fromJson(Map<String, dynamic> j) => ScheduledEmailItem(
        id: (j['id'] ?? '').toString(),
        fromEmail: (j['from_email'] ?? '').toString(),
        toEmails: (j['to_emails'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        subject: (j['subject'] ?? '(Konu yok)').toString(),
        status: (j['status'] ?? '').toString(),
        scheduledForLocal: j['scheduled_for_local'] != null
            ? DateTime.tryParse(j['scheduled_for_local'].toString())
            : (j['scheduled_for'] != null ? DateTime.tryParse(j['scheduled_for'].toString()) : null),
        attachments: (j['attachments'] as List?)
                ?.map((e) => ScheduledAttachment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        errorMessage: j['error_message']?.toString(),
      );
}

class ScheduledEmailService {
  ScheduledEmailService._();
  static final ScheduledEmailService instance = ScheduledEmailService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Bir dosyayı GridFS'e yükler; sonuç zamanlama isteğinde attachments'a konur.
  Future<ScheduledAttachment> uploadAttachment(String filePath, String filename) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });
      final resp = await _dio.post('/writer/upload-attachment', data: form);
      return ScheduledAttachment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Yeni zamanlanmış mail oluşturur. [scheduledFor] cihazın yerel saatidir;
  /// [timezone] ile birlikte gönderilir (backend yerel saati o dilime göre yorumlar).
  Future<ScheduledEmailItem> schedule({
    required String fromEmail,
    required List<String> toEmails,
    required String subject,
    required String bodyHtml,
    required DateTime scheduledFor,
    String timezone = 'Europe/Istanbul',
    List<ScheduledAttachment> attachments = const [],
  }) async {
    try {
      final resp = await _dio.post('/writer/schedule', data: {
        'from_email': fromEmail,
        'to_emails': toEmails,
        'cc_emails': <String>[],
        'subject': subject,
        'body_html': bodyHtml,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        // Offset'siz (naive) yerel zaman — backend timezone ile yorumlar.
        'scheduled_for': scheduledFor.toIso8601String(),
        'timezone': timezone,
      });
      return ScheduledEmailItem.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ScheduledEmailItem>> list({String? status}) async {
    try {
      final resp = await _dio.get('/writer/scheduled-emails', queryParameters: {
        'status': ?status,
      });
      final list = resp.data as List;
      return list.map((e) => ScheduledEmailItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> cancel(String emailId) async {
    try {
      await _dio.post('/writer/scheduled-emails/$emailId/cancel');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
