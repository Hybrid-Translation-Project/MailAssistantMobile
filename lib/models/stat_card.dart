import 'package:flutter/material.dart';

/// Backend'in GET /dashboard/stats-cards yanıtındaki her bir kart.
/// label_key/desc_key sabit anahtarlar olduğu için burada Türkçeye çevrilir
/// (backend dinamik metin döndürmüyor, sadece anahtar döndürüyor).
class StatCard {
  final String id;
  final int value;
  final String icon;
  final Color color;

  StatCard({required this.id, required this.value, required this.icon, required this.color});

  factory StatCard.fromJson(Map<String, dynamic> json) => StatCard(
        id: json['id'] ?? '',
        value: (json['value'] as num?)?.toInt() ?? 0,
        icon: json['icon'] ?? '•',
        color: _parseColor(json['color']),
      );

  static Color _parseColor(dynamic hex) {
    if (hex is! String || hex.isEmpty) return const Color(0xFF6366F1);
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  static const Map<String, String> _labels = {
    'wp_approvals': 'WhatsApp Onayları',
    'urgent_notifications': 'Acil Bildirimler',
    'total_notifications': 'Toplam Bildirim',
    'task_completion': 'Tamamlanan Görev',
  };

  String get label => _labels[id] ?? id;
}
