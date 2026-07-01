class ContactItem {
  final String id;
  final String name;
  final String email;
  final String? company;
  final List<String> platforms;
  final bool isVip;
  final bool aiProcessingEnabled;
  final String relationshipLabel;
  final int mailCount;

  ContactItem({
    required this.id,
    required this.name,
    required this.email,
    required this.company,
    required this.platforms,
    required this.isVip,
    required this.aiProcessingEnabled,
    required this.relationshipLabel,
    required this.mailCount,
  });

  factory ContactItem.fromJson(Map<String, dynamic> json) => ContactItem(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] as String?)?.trim().isNotEmpty == true ? json['name'] : (json['email'] ?? '(İsimsiz)'),
        email: json['email'] ?? '',
        company: json['company'],
        platforms: (json['platforms'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isVip: json['is_vip'] ?? false,
        aiProcessingEnabled: json['ai_processing_enabled'] ?? true,
        relationshipLabel: json['relationship_label'] ?? 'Yeni',
        mailCount: (json['mail_count'] as num?)?.toInt() ?? 0,
      );
}
