import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../theme/app_colors.dart';

/// Admin ekranlarının ortak UI yardımcıları — settings.dart'taki file-private
/// yardımcıların (appbar/kart/bölüm başlığı) admin tarafındaki karşılığı.

const kAdminAccent = Color(0xFF6366F1);
const kAdminGreen = Color(0xFF22C55E);
const kAdminRed = Color(0xFFEF4444);
const kAdminOrange = Color(0xFFEA580C);

AppBar buildAdminAppBar(BuildContext context, String title) {
  final c = AppColors.of(context);
  return AppBar(
    backgroundColor: c.bg,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 20),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    centerTitle: false,
  );
}

Widget buildAdminSectionTitle(String title, AppColors c) {
  return Text(
    title,
    style: TextStyle(
      color: c.sectionLabel,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}

Widget buildAdminCard({required Widget child, required AppColors c}) {
  return Container(
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.cardBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: child,
    ),
  );
}

/// Rozet: renkli, yarı saydam pill (web'deki rol/durum rozetlerinin karşılığı).
Widget buildAdminBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
    ),
  );
}

/// Admin API hatalarını ortak biçimde yönetir.
///
/// 403 = web'den admin yetkisi kaldırılmış demektir: bayrağı düşür, kullanıcıyı
/// bilgilendir ve admin bölümünden çık. Diğer hatalarda yalnız SnackBar gösterir.
/// Dönüş: true → 403'tü ve ekrandan çıkıldı (çağıran setState yapmamalı).
Future<bool> handleAdminError(BuildContext context, Object error) async {
  if (error is ApiException && error.statusCode == 403) {
    await SecureStorageService.instance.setIsAdmin(false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yönetici yetkiniz kaldırılmış görünüyor.'),
          backgroundColor: kAdminRed,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    return true;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString()), backgroundColor: kAdminRed),
    );
  }
  return false;
}

/// 1234567 → "1.2 MB" biçiminde okunur boyut.
String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '-';
  const units = ['B', 'KB', 'MB', 'GB'];
  double value = bytes.toDouble();
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

/// UTC tarihini cihaz saatine çevirip "07.07.2026 14:30" biçiminde gösterir.
String formatDateTime(DateTime? dt) {
  if (dt == null) return '-';
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
}
