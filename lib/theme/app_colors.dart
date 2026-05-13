import 'package:flutter/material.dart';

class AppColors {
  final bool isDark;
  const AppColors(this.isDark);

  static AppColors of(BuildContext context) =>
      AppColors(Theme.of(context).brightness == Brightness.dark);

  Color get bg => isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F0EB);
  Color get card => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get inputBg =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF0EAE3);
  Color get cardBorder =>
      isDark ? const Color(0x1AFFFFFF) : const Color(0xFFECE5DC);
  Color get divider =>
      isDark ? const Color(0x1AFFFFFF) : const Color(0xFFECE5DC);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1E293B);
  Color get textSecondary => isDark ? Colors.white54 : const Color(0xFF64748B);
  Color get textHint => isDark ? Colors.white38 : const Color(0xFF94A3B8);
  Color get sectionLabel => isDark ? Colors.white38 : const Color(0xFF94A3B8);
  Color get iconSecondary => isDark ? Colors.white24 : const Color(0xFFB0BACC);
  Color get iconTertiary => isDark ? Colors.white38 : const Color(0xFF94A3B8);
  Color get navBg => isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get navBorder => isDark ? Colors.white10 : const Color(0xFFECE5DC);
  Color get switchInactiveThumb =>
      isDark ? Colors.white38 : const Color(0xFFB0BACC);
  Color get switchInactiveTrack =>
      isDark ? Colors.white12 : const Color(0xFFD9D3EA);
  List<Color> get bgGradient => isDark
      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
      : [const Color(0xFFF0EAE3), const Color(0xFFF5F0EB)];
}
