class MailSummary {
  final String id;
  final String subject;
  final String fromEmail;
  final String bodyPreview;
  final DateTime? date;
  final String status;
  final int threadCount;

  MailSummary({
    required this.id,
    required this.subject,
    required this.fromEmail,
    required this.bodyPreview,
    required this.date,
    required this.status,
    required this.threadCount,
  });

  factory MailSummary.fromJson(Map<String, dynamic> json) {
    final body = (json['body'] ?? '') as String;
    return MailSummary(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      subject: json['subject'] ?? '(Konu yok)',
      fromEmail: json['from_email'] ?? json['from'] ?? '',
      bodyPreview: body.length > 140 ? '${body.substring(0, 140)}…' : body,
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      status: json['status'] ?? '',
      threadCount: (json['thread_count'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Bir maildeki tek ek dosya. url alanı backend'de sabit localhost adresiyle
/// saklanır (mobilden işe yaramaz); indirme URL'i message_id + filename'den
/// cihaza kayıtlı sunucu adresine göre yeniden kurulur (bkz. mail_detail_screen).
class MailAttachment {
  final String filename;
  final String contentType;
  /// IMAP eklerinde dolu (localhost download linki), OAuth eklerinde boş.
  /// Sadece IMAP/OAuth ayrımı için kullanılır, host'u kullanılmaz.
  final String rawUrl;

  MailAttachment({required this.filename, required this.contentType, required this.rawUrl});

  bool get isOauth => rawUrl.isEmpty;

  bool get isImage {
    final ct = contentType.toLowerCase();
    if (ct.startsWith('image/')) return true;
    final name = filename.toLowerCase();
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp') ||
        name.endsWith('.bmp');
  }

  factory MailAttachment.fromJson(Map<String, dynamic> json) => MailAttachment(
        filename: (json['filename'] ?? 'dosya').toString(),
        contentType: (json['content_type'] ?? '').toString(),
        rawUrl: (json['url'] ?? '').toString(),
      );
}

class MailDetail {
  final String id;
  final String subject;
  final String fromEmail;
  final String body;
  final DateTime? date;
  final bool isOwner;
  final String messageId;
  final String replyDraft;
  final List<String> tags;
  final List<MailAttachment> attachments;

  MailDetail({
    required this.id,
    required this.subject,
    required this.fromEmail,
    required this.body,
    required this.date,
    required this.isOwner,
    this.messageId = '',
    this.replyDraft = '',
    this.tags = const [],
    this.attachments = const [],
  });

  factory MailDetail.fromJson(Map<String, dynamic> json) => MailDetail(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        subject: json['subject'] ?? '(Konu yok)',
        fromEmail: json['from'] ?? json['from_email'] ?? '',
        body: json['body'] ?? '',
        date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
        isOwner: json['is_owner'] ?? false,
        messageId: (json['message_id'] ?? '').toString(),
        replyDraft: (json['reply_draft'] ?? '').toString(),
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        attachments: (json['attachments'] as List?)
                ?.map((e) => MailAttachment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
