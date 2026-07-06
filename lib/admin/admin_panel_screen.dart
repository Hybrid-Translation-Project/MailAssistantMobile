import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import 'admin_stats_screen.dart';
import 'admin_ui.dart';
import 'admin_users_screen.dart';

/// Yönetici Paneli ana ekranı (hub).
///
/// Sistem geneli istatistik kartları, alt bölümlere geçiş tile'ları ve
/// salt-okunur yedekleme durumu kartı. Mobilde riskli işlemler (yedek başlatma,
/// güncelleme uygulama) bilinçli olarak YOKTUR — bunlar web panelinde kalır.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  AdminSystemStats? _stats;
  AdminBackupStatus? _backup;
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
      final results = await Future.wait([
        AdminService.instance.systemStats(),
        AdminService.instance.backupStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as AdminSystemStats;
        _backup = results[1] as AdminBackupStatus;
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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: buildAdminAppBar(context, 'Yönetici Paneli'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAdminAccent))
          : _error != null
              ? _buildError(c)
              : RefreshIndicator(
                  color: kAdminAccent,
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildAdminSectionTitle('SİSTEM ÖZETİ', c),
                        const SizedBox(height: 10),
                        _buildStatGrid(c),
                        const SizedBox(height: 24),
                        buildAdminSectionTitle('YÖNETİM', c),
                        const SizedBox(height: 10),
                        _buildNavTile(
                          c: c,
                          icon: Icons.group_outlined,
                          color: kAdminAccent,
                          title: 'Kullanıcı Yönetimi',
                          subtitle: 'Oluştur, aktif/pasif, şifre sıfırla, sil',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminUsersScreen()),
                          ).then((_) => _load()),
                        ),
                        const SizedBox(height: 10),
                        _buildNavTile(
                          c: c,
                          icon: Icons.insights_outlined,
                          color: const Color(0xFF0EA5E9),
                          title: 'İstatistikler & AI Kullanımı',
                          subtitle: 'Kullanıcı özeti, token ve maliyet',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminStatsScreen()),
                          ),
                        ),
                        const SizedBox(height: 24),
                        buildAdminSectionTitle('YEDEKLEME DURUMU', c),
                        const SizedBox(height: 10),
                        _buildBackupCard(c),
                      ],
                    ),
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

  Widget _buildStatGrid(AppColors c) {
    final s = _stats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.group_outlined,
                count: s?.totalUsers ?? 0,
                label: 'Toplam Kullanıcı',
                color: kAdminAccent,
                c: c,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_outline,
                count: s?.activeUsers ?? 0,
                label: 'Aktif Kullanıcı',
                color: const Color(0xFF16A34A),
                c: c,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.mail_outlined,
                count: s?.totalMails ?? 0,
                label: 'Toplam Mail',
                color: const Color(0xFF2563EB),
                c: c,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.assignment_outlined,
                count: s?.totalTasks ?? 0,
                label: 'Toplam Görev',
                color: const Color(0xFF7C3AED),
                c: c,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // mainpage.dart'taki _buildStatCard deseniyle aynı görünüm.
  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required AppColors c,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required AppColors c,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: c.textHint, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.iconSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(AppColors c) {
    final b = _backup;
    if (b == null) return const SizedBox.shrink();

    if (!b.available) {
      return buildAdminCard(
        c: c,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kAdminOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_off_outlined,
                  color: kAdminOrange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Yedekleme bu kurulumda kullanılamıyor. Ayrıntılar için web panelindeki Yedekleme sekmesine bakın.',
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final last = b.lastBackup;
    return buildAdminCard(
      c: c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (last?.isOk ?? false)
                      ? kAdminGreen.withValues(alpha: 0.15)
                      : kAdminOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  (last?.isOk ?? false)
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_outlined,
                  color: (last?.isOk ?? false) ? kAdminGreen : kAdminOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  last == null
                      ? 'Henüz yedek alınmamış'
                      : (last.isOk ? 'Son yedek başarılı' : 'Son yedek HATALI'),
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (b.s3Configured) buildAdminBadge('S3', const Color(0xFF0EA5E9)),
            ],
          ),
          if (b.isRunning) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: kAdminAccent, strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Şu an yedekleniyor…',
                    style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ],
            ),
          ],
          if (last != null) ...[
            const SizedBox(height: 10),
            Divider(color: c.divider, height: 1),
            const SizedBox(height: 10),
            _buildBackupInfoRow(c, 'Tarih', formatDateTime(last.finishedAt)),
            _buildBackupInfoRow(c, 'Boyut', formatBytes(last.sizeBytes)),
            _buildBackupInfoRow(c, 'Tür', last.kind),
            if (last.s3Uploaded != null)
              _buildBackupInfoRow(
                  c, 'S3 yükleme', last.s3Uploaded! ? 'Evet' : 'Hayır'),
            if (!last.isOk && last.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  last.error!,
                  style: const TextStyle(color: kAdminRed, fontSize: 11),
                ),
              ),
          ],
          const SizedBox(height: 10),
          Text(
            'Yedek başlatma ve indirme işlemleri web panelinden yapılır.',
            style: TextStyle(color: c.textHint, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupInfoRow(AppColors c, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: c.textHint, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
