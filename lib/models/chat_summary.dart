class ChatSummary {
  final String jid;
  final String name;
  final bool isGroup;
  final int unreadCount;
  final String lastMessageBody;
  final DateTime? lastMessageTimestamp;
  final bool pinned;

  ChatSummary({
    required this.jid,
    required this.name,
    required this.isGroup,
    required this.unreadCount,
    required this.lastMessageBody,
    required this.lastMessageTimestamp,
    required this.pinned,
  });

  factory ChatSummary.fromJson(Map<String, dynamic> json) => ChatSummary(
        jid: (json['jid'] ?? '').toString(),
        name: (json['name'] as String?)?.trim().isNotEmpty == true ? json['name'] : (json['jid'] ?? '(İsimsiz)'),
        isGroup: json['is_group'] ?? false,
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        lastMessageBody: json['last_message_body'] ?? '',
        lastMessageTimestamp:
            json['last_message_timestamp'] != null ? DateTime.tryParse(json['last_message_timestamp'].toString()) : null,
        pinned: json['pinned'] ?? false,
      );
}
