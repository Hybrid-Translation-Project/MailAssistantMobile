import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import 'admin_ui.dart';

/// Kullanıcı Yönetimi — web admin panelindeki "Kullanıcılar" sekmesinin
/// mobil karşılığı: listele, oluştur, aktif/pasif, şifre sıfırla, sil.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AdminUser> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await AdminService.instance.listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final popped = await handleAdminError(context, e);
      if (popped || !mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Web'deki generateTempPassword ile aynı politika:
  /// min 8 karakter, en az 1 harf ve 1 rakam (validate_password_strength).
  static String generatePassword() {
    const letters = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ';
    const digits = '23456789';
    const all = '$letters$digits';
    final rng = Random.secure();
    final chars = <String>[
      letters[rng.nextInt(letters.length)],
      digits[rng.nextInt(digits.length)],
      for (var i = 0; i < 10; i++) all[rng.nextInt(all.length)],
    ]..shuffle(rng);
    return chars.join();
  }

  // ─── İşlemler ────────────────────────────────────────────────────────────

  Future<void> _toggleUser(AdminUser user) async {
    final confirmed = await _confirmDialog(
      title: user.isActive ? 'Kullanıcıyı pasifleştir' : 'Kullanıcıyı aktifleştir',
      message: user.isActive
          ? '${user.username} pasif yapılacak ve giriş yapamayacak. Emin misiniz?'
          : '${user.username} yeniden aktif yapılacak. Emin misiniz?',
      confirmText: user.isActive ? 'Pasifleştir' : 'Aktifleştir',
      destructive: user.isActive,
    );
    if (confirmed != true) return;
    try {
      await AdminService.instance.toggleUser(user.id);
      await _load();
    } catch (e) {
      if (mounted) await handleAdminError(context, e);
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await _confirmDialog(
      title: 'Kullanıcıyı sil',
      message:
          "'${user.username}' ve tüm mesajlaşma yapılandırmaları kalıcı olarak silinecek. Bu işlem geri alınamaz!",
      confirmText: 'Sil',
      destructive: true,
    );
    if (confirmed != true) return;
    try {
      await AdminService.instance.deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'${user.username}' silindi.")),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) await handleAdminError(context, e);
    }
  }

  Future<void> _resetPassword(AdminUser user) async {
    final result = await showModalBottomSheet<_ResetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResetPasswordSheet(username: user.username),
    );
    if (result == null) return;
    try {
      await AdminService.instance.resetPassword(
        user.id,
        result.password,
        forcePasswordChange: result.forcePasswordChange,
      );
      await _load();
      if (mounted) {
        await _showCredentialDialog(
            username: user.username, password: result.password);
      }
    } catch (e) {
      if (mounted) await handleAdminError(context, e);
    }
  }

  Future<void> _createUser() async {
    final result = await showModalBottomSheet<_CreateResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateUserSheet(),
    );
    if (result == null) return;
    try {
      await AdminService.instance.createUser(
        username: result.username,
        fullName: result.fullName,
        password: result.password,
        role: result.role,
        notificationEmail: result.notificationEmail,
        forcePasswordChange: result.forcePasswordChange,
      );
      await _load();
      if (mounted) {
        await _showCredentialDialog(
            username: result.username, password: result.password);
      }
    } catch (e) {
      if (mounted) await handleAdminError(context, e);
    }
  }

  /// Tek seferlik kimlik bilgisi dialogu — web'deki "Geçici Şifre Teslim
  /// Modalı"nın karşılığı. Şifre bir daha görüntülenemez; kapatmadan önce
  /// kopyalanması beklenir.
  Future<void> _showCredentialDialog({
    required String username,
    required String password,
  }) {
    final c = AppColors.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.key_outlined, color: kAdminAccent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Giriş Bilgileri',
                  style: TextStyle(color: c.textPrimary, fontSize: 17)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu şifre bir daha GÖRÜNTÜLENEMEZ. Kapatmadan önce kopyalayıp kullanıcıya güvenli bir kanaldan iletin.',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            _credRow(c, 'Kullanıcı adı', username),
            const SizedBox(height: 8),
            _credRow(c, 'Geçici şifre', password),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                  text: 'Kullanıcı adı: $username\nŞifre: $password'));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Bilgiler panoya kopyalandı.')),
                );
              }
            },
            icon: const Icon(Icons.copy, color: kAdminAccent, size: 16),
            label: const Text('Bilgileri Kopyala',
                style: TextStyle(color: kAdminAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Kapat', style: TextStyle(color: c.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _credRow(AppColors c, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.textHint, fontSize: 10)),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool destructive = false,
  }) {
    final c = AppColors.of(context);
    final color = destructive ? kAdminRed : kAdminAccent;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: c.textPrimary, fontSize: 17)),
        content: Text(message,
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Vazgeç', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmText,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Görünüm ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: buildAdminAppBar(context, 'Kullanıcı Yönetimi'),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        backgroundColor: kAdminAccent,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAdminAccent))
          : _error != null
              ? _buildError(c)
              : RefreshIndicator(
                  color: kAdminAccent,
                  onRefresh: _load,
                  child: _users.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Icon(Icons.group_off_outlined,
                                color: c.textHint, size: 48),
                            const SizedBox(height: 12),
                            Center(
                              child: Text('Kullanıcı bulunamadı',
                                  style: TextStyle(
                                      color: c.textSecondary, fontSize: 13)),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                          itemCount: _users.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildUserCard(c, _users[i]),
                        ),
                ),
    );
  }

  Widget _buildError(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: c.textHint, size: 48),
            const SizedBox(height: 12),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kAdminAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Tekrar Dene',
                  style: TextStyle(color: kAdminAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AppColors c, AdminUser user) {
    final initials = user.fullName.isNotEmpty
        ? user.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join()
        : user.username.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty ? user.username : user.fullName,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('@${user.username}',
                        style: TextStyle(color: c.textHint, fontSize: 11)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: c.iconTertiary, size: 20),
                color: c.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (action) {
                  switch (action) {
                    case 'toggle':
                      _toggleUser(user);
                    case 'reset':
                      _resetPassword(user);
                    case 'delete':
                      _deleteUser(user);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          user.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          color: kAdminOrange,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(user.isActive ? 'Pasifleştir' : 'Aktifleştir',
                            style: TextStyle(
                                color: c.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        const Icon(Icons.lock_reset,
                            color: kAdminAccent, size: 18),
                        const SizedBox(width: 10),
                        Text('Şifre Sıfırla',
                            style: TextStyle(
                                color: c.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            color: kAdminRed, size: 18),
                        const SizedBox(width: 10),
                        const Text('Sil',
                            style:
                                TextStyle(color: kAdminRed, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              buildAdminBadge(user.role == 'admin' ? 'Admin' : 'Kullanıcı',
                  user.role == 'admin' ? kAdminAccent : const Color(0xFF64748B)),
              buildAdminBadge(user.isActive ? 'Aktif' : 'Pasif',
                  user.isActive ? kAdminGreen : kAdminRed),
              if (user.mustChangePassword)
                buildAdminBadge('Şifre değiştirmeli', kAdminOrange),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${user.mailCount} mail · ${user.taskCount} görev · ${user.accountCount} hesap',
            style: TextStyle(color: c.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Şifre Sıfırlama Sheet'i ────────────────────────────────────────────────

class _ResetResult {
  final String password;
  final bool forcePasswordChange;
  _ResetResult(this.password, this.forcePasswordChange);
}

class _ResetPasswordSheet extends StatefulWidget {
  final String username;
  const _ResetPasswordSheet({required this.username});

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  final _passwordController =
      TextEditingController(text: _AdminUsersScreenState.generatePassword());
  bool _obscure = false;
  bool _forceChange = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return _SheetScaffold(
      title: 'Şifre Sıfırla — @${widget.username}',
      c: c,
      children: [
        _PasswordField(
          controller: _passwordController,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          onGenerate: () => setState(() => _passwordController.text =
              _AdminUsersScreenState.generatePassword()),
          c: c,
        ),
        const SizedBox(height: 12),
        _ForceChangeSwitch(
          value: _forceChange,
          onChanged: (v) => setState(() => _forceChange = v),
          c: c,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final password = _passwordController.text.trim();
              if (password.length < 8) return;
              Navigator.pop(context, _ResetResult(password, _forceChange));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kAdminAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Şifreyi Sıfırla',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}

// ─── Kullanıcı Oluşturma Sheet'i ───────────────────────────────────────────

class _CreateResult {
  final String username;
  final String fullName;
  final String password;
  final String role;
  final String? notificationEmail;
  final bool forcePasswordChange;

  _CreateResult({
    required this.username,
    required this.fullName,
    required this.password,
    required this.role,
    this.notificationEmail,
    required this.forcePasswordChange,
  });
}

class _CreateUserSheet extends StatefulWidget {
  const _CreateUserSheet();

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController =
      TextEditingController(text: _AdminUsersScreenState.generatePassword());
  String _role = 'user';
  bool _obscure = false;
  bool _forceChange = true;
  String? _validationError;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final password = _passwordController.text.trim();

    String? error;
    if (username.isEmpty) {
      error = 'Kullanıcı adı zorunlu.';
    } else if (fullName.isEmpty) {
      error = 'Ad soyad zorunlu.';
    } else if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Za-z]')) ||
        !password.contains(RegExp(r'[0-9]'))) {
      error = 'Şifre en az 8 karakter olmalı, harf ve rakam içermeli.';
    }
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    Navigator.pop(
      context,
      _CreateResult(
        username: username,
        fullName: fullName,
        password: password,
        role: _role,
        notificationEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        forcePasswordChange: _forceChange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return _SheetScaffold(
      title: 'Yeni Kullanıcı',
      c: c,
      children: [
        _TextField(controller: _usernameController, label: 'Kullanıcı adı', c: c),
        const SizedBox(height: 10),
        _TextField(controller: _fullNameController, label: 'Ad soyad', c: c),
        const SizedBox(height: 10),
        _TextField(
          controller: _emailController,
          label: 'Bildirim e-postası (isteğe bağlı)',
          keyboardType: TextInputType.emailAddress,
          c: c,
        ),
        const SizedBox(height: 10),
        // Rol seçimi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _role,
              isExpanded: true,
              dropdownColor: c.card,
              style: TextStyle(color: c.textPrimary, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Kullanıcı')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'user'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _PasswordField(
          controller: _passwordController,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          onGenerate: () => setState(() => _passwordController.text =
              _AdminUsersScreenState.generatePassword()),
          c: c,
        ),
        const SizedBox(height: 12),
        _ForceChangeSwitch(
          value: _forceChange,
          onChanged: (v) => setState(() => _forceChange = v),
          c: c,
        ),
        if (_validationError != null) ...[
          const SizedBox(height: 10),
          Text(_validationError!,
              style: const TextStyle(color: kAdminRed, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: kAdminAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Kullanıcı Oluştur',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}

// ─── Sheet parçaları ────────────────────────────────────────────────────────

class _SheetScaffold extends StatelessWidget {
  final String title;
  final AppColors c;
  final List<Widget> children;
  const _SheetScaffold(
      {required this.title, required this.c, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final AppColors c;
  const _TextField(
      {required this.controller,
      required this.label,
      this.keyboardType,
      required this.c});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: c.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.textHint, fontSize: 12),
        filled: true,
        fillColor: c.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAdminAccent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onGenerate;
  final AppColors c;
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.onGenerate,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(
                color: c.textPrimary, fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'Geçici şifre',
              labelStyle: TextStyle(color: c.textHint, fontSize: 12),
              filled: true,
              fillColor: c.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kAdminAccent),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: c.iconTertiary,
                  size: 18,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onGenerate,
          tooltip: 'Şifre Üret',
          style: IconButton.styleFrom(
            backgroundColor: kAdminAccent.withValues(alpha: 0.15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.autorenew, color: kAdminAccent, size: 20),
        ),
      ],
    );
  }
}

class _ForceChangeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors c;
  const _ForceChangeSwitch(
      {required this.value, required this.onChanged, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('İlk girişte şifre değişikliği zorunlu',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('Kullanıcı geçici şifreyle girince yeni şifre belirler',
                  style: TextStyle(color: c.textHint, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: kAdminAccent,
          inactiveThumbColor: c.switchInactiveThumb,
          inactiveTrackColor: c.switchInactiveTrack,
        ),
      ],
    );
  }
}
