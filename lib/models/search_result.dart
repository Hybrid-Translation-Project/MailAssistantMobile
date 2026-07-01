class SearchResultItem {
  final String id;
  final String platform;
  final String title;
  final String preview;
  final String senderName;
  final DateTime? date;

  SearchResultItem({
    required this.id,
    required this.platform,
    required this.title,
    required this.preview,
    required this.senderName,
    required this.date,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) => SearchResultItem(
        id: json['id'].toString(),
        platform: json['platform'] ?? 'mail',
        title: json['title'] ?? json['sender_name'] ?? '(Başlıksız)',
        preview: json['preview'] ?? '',
        senderName: json['sender_name'] ?? json['sender'] ?? '',
        date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      );
}
