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

class MailDetail {
  final String id;
  final String subject;
  final String fromEmail;
  final String body;
  final DateTime? date;
  final bool isOwner;

  MailDetail({
    required this.id,
    required this.subject,
    required this.fromEmail,
    required this.body,
    required this.date,
    required this.isOwner,
  });

  factory MailDetail.fromJson(Map<String, dynamic> json) => MailDetail(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        subject: json['subject'] ?? '(Konu yok)',
        fromEmail: json['from'] ?? json['from_email'] ?? '',
        body: json['body'] ?? '',
        date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
        isOwner: json['is_owner'] ?? false,
      );
}
