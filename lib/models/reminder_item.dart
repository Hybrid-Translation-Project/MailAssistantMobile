class ReminderItem {
  final String id;
  final String? mailId;
  final String mailSubject;
  final String mailFrom;
  final String reminderType;
  final bool isRead;
  final DateTime? triggerAt;

  ReminderItem({
    required this.id,
    required this.mailId,
    required this.mailSubject,
    required this.mailFrom,
    required this.reminderType,
    required this.isRead,
    required this.triggerAt,
  });

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
        id: json['id'].toString(),
        mailId: json['mail_id'],
        mailSubject: json['mail_subject'] ?? '(Konu yok)',
        mailFrom: json['mail_from'] ?? '',
        reminderType: json['reminder_type'] ?? '',
        isRead: json['is_read'] ?? false,
        triggerAt: json['trigger_at'] != null ? DateTime.tryParse(json['trigger_at']) : null,
      );
}
