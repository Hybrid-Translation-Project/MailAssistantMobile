import 'package:flutter/material.dart';
import 'package:mail_assistant_mobile/main.dart' show themeNotifier;
import 'package:mail_assistant_mobile/theme/app_colors.dart';
import '../login/login.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

// ─── Profil Sayfası ───────────────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _fullName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.instance.getProfile();
      if (!mounted) return;
      setState(() {
        _fullName = profile.fullName;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String get _initials {
    final parts = _fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, c),
          const SizedBox(height: 24),
          _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
              : _buildProfileCard(c),
          const SizedBox(height: 20),
          _buildActionButtons(context, c),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profil',
          style: TextStyle(color: c.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.cardBorder),
            ),
            child: Icon(Icons.settings_outlined, color: c.textPrimary, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: c.card, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName.isEmpty ? 'Kullanıcı' : _fullName,
                      style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppColors c) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(Icons.settings_outlined, color: c.textSecondary, size: 16),
                label: Text('Ayarlar', style: TextStyle(color: c.textSecondary, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 16),
                label: const Text('Çıkış Yap', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Ana Ayarlar Sayfası ───────────────────────────────────────────────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_SettingsItem> _allItems = const [
    _SettingsItem(
      section: 'GENEL TERCİHLER',
      title: 'Profil Bilgileri',
      subtitle: 'İsim, e-posta, imza',
      icon: Icons.person_outline,
      color: Color(0xFF6366F1),
      page: _ProfileInfoPage(),
    ),
    _SettingsItem(
      section: 'GENEL TERCİHLER',
      title: 'Görünüm & Etiketler',
      subtitle: 'Tema, dil, etiket yönetimi',
      icon: Icons.palette_outlined,
      color: Color(0xFF0EA5E9),
      page: _AppearancePage(),
    ),
    _SettingsItem(
      section: 'GENEL TERCİHLER',
      title: 'Bildirimler',
      subtitle: 'Uyarılar, Telegram, mail sıklığı',
      icon: Icons.notifications_outlined,
      color: Color(0xFF8B5CF6),
      page: _NotificationsPage(),
    ),
    _SettingsItem(
      section: 'OPTİMİZASYON',
      title: 'Panel Şifresi',
      subtitle: 'Giriş güvenlik ayarları',
      icon: Icons.lock_outline,
      color: Color(0xFFEA580C),
      page: _SecurityPage(),
    ),
    _SettingsItem(
      section: 'OPTİMİZASYON',
      title: 'Oturumlar',
      subtitle: 'Aktif cihazlar ve oturum yönetimi',
      icon: Icons.devices_outlined,
      color: Color(0xFFF59E0B),
      page: _SecurityPage(),
    ),
    _SettingsItem(
      section: 'YARDIM',
      title: 'Yardım & Geri Bildirim',
      subtitle: 'SSS, destek, öneri gönder',
      icon: Icons.help_outline,
      color: Color(0xFF14B8A6),
      page: _HelpPage(),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final filtered = _searchQuery.isEmpty
        ? _allItems
        : _allItems
            .where((i) =>
                i.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                i.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final sections = <String>[];
    for (final item in filtered) {
      if (!sections.contains(item.section)) sections.add(item.section);
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
          style: TextStyle(color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: c.textPrimary),
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Ayarlar ara...',
                  hintStyle: TextStyle(color: c.textHint, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: c.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    child: Text(
                      section,
                      style: TextStyle(
                        color: c.sectionLabel,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Column(
                      children: filtered
                          .where((i) => i.section == section)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final isLast = idx ==
                            filtered
                                    .where((i) => i.section == section)
                                    .length -
                                1;
                        return _buildSettingsRow(context, item, isLast, c);
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(BuildContext context, _SettingsItem item, bool isLast, AppColors c) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => item.page),
      ),
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: c.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(color: c.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.iconSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final String section;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const _SettingsItem({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}

// ─── Görünüm & Etiketler ──────────────────────────────────────────────────
class _AppearancePage extends StatefulWidget {
  const _AppearancePage();

  @override
  State<_AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<_AppearancePage> {
  String _language = 'tr';

  final List<Map<String, dynamic>> _labels = [
    {'text': 'AKİL', 'color': const Color(0xFFEF4444)},
    {'text': 'ÇALIŞMA', 'color': const Color(0xFF3B82F6)},
    {'text': 'CV', 'color': const Color(0xFFF59E0B)},
    {'text': 'ÖNEMLİ', 'color': const Color(0xFF8B5CF6)},
    {'text': 'TOPLANTI', 'color': const Color(0xFF22C55E)},
    {'text': 'FATURA', 'color': const Color(0xFFEC4899)},
  ];

  void _showAddLabelDialog() {
    final controller = TextEditingController();
    Color selectedColor = const Color(0xFF6366F1);
    final palette = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF22C55E),
      const Color(0xFFEC4899),
      const Color(0xFF6366F1),
      const Color(0xFF14B8A6),
      const Color(0xFFEA580C),
    ];

    final c = AppColors.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: c.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Yeni Etiket',
                style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: TextStyle(color: c.textPrimary),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Etiket adı...',
                      hintStyle: TextStyle(color: c.textHint),
                      filled: true,
                      fillColor: c.inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Renk seç:',
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: palette.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                                : [],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('İptal', style: TextStyle(color: c.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final text = controller.text.trim().toUpperCase();
                    if (text.isNotEmpty) {
                      setState(() {
                        _labels.add({'text': text, 'color': selectedColor});
                      });
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Ekle', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context, 'Görünüm & Etiketler'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('DİL', c),
          const SizedBox(height: 10),
          _buildCard(
            c: c,
            child: Row(
              children: [
                Expanded(child: _buildLangButton('tr', 'Türkçe', '🇹🇷', c)),
                const SizedBox(width: 10),
                Expanded(child: _buildLangButton('en', 'English', '🇬🇧', c)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('TEMA', c),
          const SizedBox(height: 10),
          _buildCard(
            c: c,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, _, child) => Row(
                children: [
                  Expanded(child: _buildThemeButton(false, Icons.wb_sunny_outlined, 'Aydınlık', c)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildThemeButton(true, Icons.dark_mode_outlined, 'Karanlık', c)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('ETİKET YÖNETİMİ', c),
          const SizedBox(height: 10),
          _buildCard(
            c: c,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._labels.map((l) => _buildLabelChip(l, c)),
                    _buildAddLabelChip(c),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangButton(String value, String label, String flag, AppColors c) {
    final isSelected = _language == value;
    return GestureDetector(
      onTap: () => setState(() => _language = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.2)
              : c.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : c.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '$flag  $label',
            style: TextStyle(
              color: isSelected ? c.textPrimary : c.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(bool isDark, IconData icon, String label, AppColors c) {
    final isSelected = (themeNotifier.value == ThemeMode.dark) == isDark;
    const accent = Color(0xFF6366F1);
    return GestureDetector(
      onTap: () {
        themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.2) : c.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : c.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? accent : c.textHint, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? c.textPrimary : c.textHint,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelChip(Map<String, dynamic> label, AppColors c) {
    final color = label['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label['text'] as String,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _labels.remove(label)),
            child: Icon(Icons.close, color: color, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAddLabelChip(AppColors c) {
    return GestureDetector(
      onTap: _showAddLabelDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.inputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: c.textSecondary, size: 14),
            const SizedBox(width: 4),
            Text('EKLE', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Profil Bilgileri ─────────────────────────────────────────────────────
class _ProfileInfoPage extends StatefulWidget {
  const _ProfileInfoPage();

  @override
  State<_ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<_ProfileInfoPage> {
  final _nameController = TextEditingController();
  final _signatureController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.instance.getProfile();
      if (!mounted) return;
      setState(() {
        _nameController.text = profile.fullName;
        _signatureController.text = profile.signature;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ProfileService.instance.updateProfile(
        fullName: _nameController.text.trim(),
        signature: _signatureController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = _nameController.text.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: c.bg,
        appBar: _buildAppBar(context, 'Profil Bilgileri'),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }
    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context, 'Profil Bilgileri'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 2),
                    ),
                    child: Icon(Icons.camera_alt_outlined, color: c.textSecondary, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionTitle('KİŞİSEL BİLGİLER', c),
          const SizedBox(height: 10),
          _buildCard(
            c: c,
            child: Column(
              children: [
                _buildField('Ad Soyad', _nameController, Icons.person_outline, c),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('PROFİL İMZASI', c),
          const SizedBox(height: 10),
          _buildCard(
            c: c,
            child: TextField(
              controller: _signatureController,
              maxLines: 4,
              style: TextStyle(color: c.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'İmzanızı yazın...',
                hintStyle: TextStyle(color: c.textHint),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: c.textHint, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: c.textHint, fontSize: 11)),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  style: TextStyle(color: c.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: c.iconSecondary, size: 16),
        ],
      ),
    );
  }
}

// ─── Güvenlik ─────────────────────────────────────────────────────────────
class _SecurityPage extends StatefulWidget {
  const _SecurityPage();

  @override
  State<_SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<_SecurityPage> {
  bool _twoFactor = true;
  bool _biometric = true;
  bool _suspiciousAlert = true;

  void _showChangePasswordDialog(AppColors c) {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    bool saving = false;
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: c.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Şifre Değiştir', style: TextStyle(color: c.textPrimary, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldController,
                    obscureText: true,
                    style: TextStyle(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Mevcut şifre',
                      hintStyle: TextStyle(color: c.textHint),
                      filled: true,
                      fillColor: c.inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    style: TextStyle(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Yeni şifre',
                      hintStyle: TextStyle(color: c.textHint),
                      filled: true,
                      fillColor: c.inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('İptal', style: TextStyle(color: c.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          if (oldController.text.isEmpty || newController.text.isEmpty) {
                            setDialogState(() => error = 'Her iki alan da gerekli.');
                            return;
                          }
                          setDialogState(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            await ProfileService.instance.changePassword(
                              oldPassword: oldController.text,
                              newPassword: newController.text,
                            );
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                              error = e.toString();
                            });
                          }
                        },
                  child: Text(saving ? '...' : 'Kaydet', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context, 'Güvenlik'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF22C55E), size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hesabınız güvende',
                      style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Son kontrol: 12/5/2026',
                      style: TextStyle(color: c.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('PANEL GİRİŞ ŞİFRESİ', c),
          const SizedBox(height: 10),
          _buildCard(
            c: c,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: c.textHint, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '••••••••',
                          style: TextStyle(color: c.textSecondary, fontSize: 20, letterSpacing: 4),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showChangePasswordDialog(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Değiştir',
                            style: TextStyle(color: Color(0xFFEA580C), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('GÜVENLİK', c),
          const SizedBox(height: 10),
          _buildCard(
            c: c,
            child: Column(
              children: [
                _buildToggleRow(
                  c: c,
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF6366F1),
                  title: 'İki Adımlı Doğrulama',
                  subtitle: 'Giriş sırasında ek doğrulama iste',
                  value: _twoFactor,
                  onChanged: (v) => setState(() => _twoFactor = v),
                  isLast: false,
                ),
                _buildToggleRow(
                  c: c,
                  icon: Icons.fingerprint,
                  iconColor: const Color(0xFF22C55E),
                  title: 'Biyometrik Giriş',
                  subtitle: 'Parmak izi / yüz tanıma ile aç',
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                  isLast: false,
                ),
                _buildToggleRow(
                  c: c,
                  icon: Icons.warning_amber_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Şüpheli Giriş Bildirimi',
                  subtitle: 'Tanımadık cihazları bildir',
                  value: _suspiciousAlert,
                  onChanged: (v) => setState(() => _suspiciousAlert = v),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bildirimler ──────────────────────────────────────────────────────────
class _NotificationsPage extends StatefulWidget {
  const _NotificationsPage();

  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> {
  static const _notifFreqOpts = ['30 dk', '1 saat', '3 saat', '6 saat', '12 saat', '1 gün', '2 gün', '3 gün'];
  static const _mailFreqOpts  = ['1 dk', '5 dk', '15 dk', '30 dk', '1 saat', '3 saat'];

  late final List<Map<String, dynamic>> _notifItems;
  late final List<Map<String, dynamic>> _mailItems;

  @override
  void initState() {
    super.initState();
    _notifItems = [
      {'title': 'Haberleştir',           'subtitle': 'Yeni mailleri anlık olarak bildir', 'icon': Icons.notifications_active_outlined, 'color': const Color(0xFF6366F1), 'value': true,  'freq': '3 gün', 'freqOpts': _notifFreqOpts},
      {'title': 'Taslak Haberleştirici', 'subtitle': 'Taslaklar için hatırlatıcı gönder', 'icon': Icons.drafts_outlined,               'color': const Color(0xFF0EA5E9), 'value': true,  'freq': '3 gün', 'freqOpts': _notifFreqOpts},
      {'title': 'AI Cevap Bildirimi',    'subtitle': 'AI yanıt oluşturduğunda bildir',    'icon': Icons.auto_awesome_outlined,         'color': const Color(0xFF8B5CF6), 'value': true,  'freq': '3 gün', 'freqOpts': _notifFreqOpts},
      {'title': 'Cevap Sıklısı',         'subtitle': 'Cevapsız mailleri tekrar hatırlat', 'icon': Icons.replay_outlined,               'color': const Color(0xFFEC4899), 'value': false, 'freq': '3 gün', 'freqOpts': _notifFreqOpts},
    ];
    _mailItems = [
      {'title': 'Mail Kontrol Sıklığı', 'subtitle': 'Arka planda mail tarama aralığı', 'icon': Icons.sync_outlined,   'color': const Color(0xFF22C55E), 'value': true,  'freq': '1 dk', 'freqOpts': _mailFreqOpts},
      {'title': 'Gelen Kutusu',         'subtitle': 'Yeni gelen mailleri izle',        'icon': Icons.inbox_outlined,  'color': const Color(0xFFF59E0B), 'value': true,  'freq': null,   'freqOpts': null},
      {'title': 'Giden Kutusu',         'subtitle': 'Gönderilen mail durumunu izle',   'icon': Icons.outbox_outlined, 'color': const Color(0xFFEA580C), 'value': false, 'freq': null,   'freqOpts': null},
    ];
  }


  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context, 'Bildirimler'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('BİLDİRİMLER', c),
          const SizedBox(height: 10),
          _buildCard(
            c: c,
            child: Column(
              children: _notifItems.asMap().entries.map((e) =>
                _buildNotifRow(c, e.value, e.key, _notifItems, isLast: e.key == _notifItems.length - 1),
              ).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('MAIL KONTROL', c),
          const SizedBox(height: 10),
          _buildCard(
            c: c,
            child: Column(
              children: _mailItems.asMap().entries.map((e) =>
                _buildNotifRow(c, e.value, e.key, _mailItems, isLast: e.key == _mailItems.length - 1),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifRow(
    AppColors c,
    Map<String, dynamic> item,
    int idx,
    List<Map<String, dynamic>> list, {
    required bool isLast,
  }) {
    final icon     = item['icon']     as IconData;
    final color    = item['color']    as Color;
    final title    = item['title']    as String;
    final subtitle = item['subtitle'] as String;
    final value    = item['value']    as bool;
    final freq     = item['freq']     as String?;
    final freqOpts = item['freqOpts'] as List<String>?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: c.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: c.textHint, fontSize: 11)),
              ],
            ),
          ),
          if (freq != null && freqOpts != null) ...[
            const SizedBox(width: 6),
            Builder(builder: (chipCtx) => GestureDetector(
              onTap: value ? () async {
                final box = chipCtx.findRenderObject() as RenderBox;
                final offset = box.localToGlobal(Offset.zero);
                final size = box.size;
                final screen = MediaQuery.of(chipCtx).size;
                const accent = Color(0xFF6366F1);

                final selected = await showMenu<String>(
                  context: chipCtx,
                  position: RelativeRect.fromLTRB(
                    offset.dx,
                    offset.dy + size.height + 4,
                    screen.width - offset.dx - size.width,
                    screen.height - offset.dy - size.height - 4,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: c.card,
                  elevation: c.isDark ? 8 : 3,
                  constraints: const BoxConstraints(minWidth: 120),
                  items: freqOpts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final opt = entry.value;
                    final isSelected = opt == freq;
                    return PopupMenuItem<String>(
                      value: opt,
                      padding: EdgeInsets.zero,
                      height: 40,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? accent.withValues(alpha: 0.1) : Colors.transparent,
                          border: i < freqOpts.length - 1
                              ? Border(bottom: BorderSide(color: c.divider, width: 0.5))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(opt, style: TextStyle(
                              color: isSelected ? accent : c.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            )),
                            const Spacer(),
                            if (isSelected) const Icon(Icons.check_rounded, color: accent, size: 14),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );

                if (!mounted) return;
                if (selected != null) setState(() => list[idx]['freq'] = selected);
              } : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: value ? color.withValues(alpha: 0.15) : c.inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: value ? color.withValues(alpha: 0.4) : c.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(freq, style: TextStyle(color: value ? color : c.textHint, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, color: value ? color : c.textHint, size: 12),
                  ],
                ),
              ),
            )),
          ],
          Switch(
            value: value,
            onChanged: (v) => setState(() => list[idx]['value'] = v),
            activeThumbColor: const Color(0xFF6366F1),
            activeTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
            inactiveThumbColor: c.switchInactiveThumb,
            inactiveTrackColor: c.switchInactiveTrack,
          ),
        ],
      ),
    );
  }
}

// ─── Yardım & Geri Bildirim ───────────────────────────────────────────────
class _HelpPage extends StatelessWidget {
  const _HelpPage();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context, 'Yardım & Geri Bildirim'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildCard(
            c: c,
            child: Column(
              children: [
                _buildHelpRow(Icons.question_answer_outlined, const Color(0xFF6366F1), 'Sık Sorulan Sorular', false, c),
                _buildHelpRow(Icons.support_agent_outlined, const Color(0xFF22C55E), 'Destek Ekibi ile İletişim', false, c),
                _buildHelpRow(Icons.feedback_outlined, const Color(0xFF0EA5E9), 'Geri Bildirim Gönder', false, c),
                _buildHelpRow(Icons.info_outline, const Color(0xFFF59E0B), 'Uygulama Hakkında', true, c),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'AI Mail Asistan v1.0.0',
              style: TextStyle(color: c.textHint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRow(IconData icon, Color color, String title, bool isLast, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: c.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: TextStyle(color: c.textPrimary, fontSize: 14)),
          ),
          Icon(Icons.chevron_right_rounded, color: c.iconSecondary, size: 20),
        ],
      ),
    );
  }
}

// ─── Paylaşılan yardımcılar ───────────────────────────────────────────────

AppBar _buildAppBar(BuildContext context, String title) {
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

Widget _buildSectionTitle(String title, AppColors c) {
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

Widget _buildCard({required Widget child, required AppColors c}) {
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

Widget _buildToggleRow({
  required AppColors c,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  String? badge,
  required bool value,
  required ValueChanged<bool> onChanged,
  required bool isLast,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : Border(bottom: BorderSide(color: c.divider, width: 0.5)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge, style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: c.textHint, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF6366F1),
          activeTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
          inactiveThumbColor: c.switchInactiveThumb,
          inactiveTrackColor: c.switchInactiveTrack,
        ),
      ],
    ),
  );
}
