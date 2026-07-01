class ChatMessageItem {
  final String id;
  final String senderName;
  final String body;
  final String messageType;
  final bool isMine;
  final DateTime? receivedAt;
  final int mediaCount;

  ChatMessageItem({
    required this.id,
    required this.senderName,
    required this.body,
    required this.messageType,
    required this.isMine,
    required this.receivedAt,
    required this.mediaCount,
  });

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) => ChatMessageItem(
        id: (json['id'] ?? '').toString(),
        senderName: json['sender_name'] ?? json['participant_name'] ?? '',
        body: json['body'] ?? '',
        messageType: json['message_type'] ?? 'text',
        isMine: (json['direction'] ?? '') == 'outbound' || json['key_from_me'] == true,
        receivedAt: json['received_at'] != null ? DateTime.tryParse(json['received_at'].toString()) : null,
        mediaCount: (json['media'] as List?)?.length ?? 0,
      );
}
