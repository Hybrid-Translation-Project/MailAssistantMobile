import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import 'admin_ui.dart';

/// İstatistikler & AI Kullanımı — web'deki "İstatistikler" ve "AI Kullanımı"
/// sekmelerinin salt-okunur mobil özeti. Günlük bar grafiği bilinçli olarak
/// yok; özellik bazlı oransal liste yeterli (detay web panelinde).
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  AdminSystemStats? _stats;
  AdminAiStats? _aiStats;
  int _days = 30;
  bool _loading = true;
  bool _aiLoading = false;
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
        AdminService.instance.aiStats(days: _days),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as AdminSystemStats;
        _aiStats = results[1] as AdminAiStats;
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

  Future<void> _changeDays(int days) async {
    setState(() {
      _days = days;
      _aiLoading = true;
    });
    try {
      final aiStats = await AdminService.instance.aiStats(days: days);
      if (!mounted) return;
      setState(() {
        _aiStats = aiStats;
        _aiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiLoading = false);
      await handleAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: buildAdminAppBar(context, 'İstatistikler & AI'),
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
                        buildAdminSectionTitle('KULLANICI İSTATİSTİKLERİ', c),
                        const SizedBox(height: 10),
                        _buildUserStats(c),
                        const SizedBox(height: 24),
                        buildAdminSectionTitle('AI KULLANIMI', c),
                        const SizedBox(height: 10),
                        _buildDaysSelector(c),
                        const SizedBox(height: 12),
                        _aiLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: kAdminAccent)),
                              )
                            : _buildAiStats(c),
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

  // ─── Kullanıcı istatistikleri ────────────────────────────────────────────

  Widget _buildUserStats(AppColors c) {
    final users = _stats?.users ?? const <AdminUserStat>[];
    if (users.isEmpty) {
      return buildAdminCard(
        c: c,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Kullanıcı verisi yok',
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
        ),
      );
    }
    return buildAdminCard(
      c: c,
      child: Column(
        children: [
          for (var i = 0; i < users.length; i++)
            _buildUserStatRow(c, users[i], isLast: i == users.length - 1),
        ],
      ),
    );
  }

  Widget _buildUserStatRow(AppColors c, AdminUserStat u, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: c.divider, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  u.fullName.isEmpty ? u.username : u.fullName,
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!u.isActive) buildAdminBadge('Pasif', kAdminRed),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Haftalık ${u.weeklyMails} mail · toplam ${u.totalMails} mail · ${u.completedTasks}/${u.totalTasks} görev',
            style: TextStyle(color: c.textHint, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: u.taskCompletionRate / 100,
                    minHeight: 5,
                    backgroundColor: c.divider,
                    color: kAdminGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('%${u.taskCompletionRate.toStringAsFixed(0)}',
                  style: TextStyle(color: c.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── AI kullanımı ────────────────────────────────────────────────────────

  Widget _buildDaysSelector(AppColors c) {
    return Row(
      children: [
        for (final days in const [7, 30, 90]) ...[
          ChoiceChip(
            label: Text('$days gün'),
            selected: _days == days,
            onSelected: (_) => _changeDays(days),
            selectedColor: kAdminAccent.withValues(alpha: 0.2),
            backgroundColor: c.card,
            labelStyle: TextStyle(
              color: _days == days ? kAdminAccent : c.textSecondary,
              fontSize: 12,
              fontWeight: _days == days ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
                color: _days == days ? kAdminAccent : c.cardBorder),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildAiStats(AppColors c) {
    final ai = _aiStats;
    if (ai == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toplam kartları — 2 sütunlu küçük metrik grid'i
        Row(
          children: [
            Expanded(
                child: _buildMetricCard(c, 'AI Çağrısı',
                    ai.totalCalls.toString(), Icons.bolt_outlined)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildMetricCard(c, 'Toplam Token',
                    _formatCount(ai.totalTokens), Icons.token_outlined)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildMetricCard(
                    c,
                    'Ort. Yanıt',
                    '${ai.avgDurationMs.toStringAsFixed(0)} ms',
                    Icons.speed_outlined)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildMetricCard(c, 'Spam Atlandı',
                    ai.promoSkipped.toString(), Icons.block_outlined)),
          ],
        ),
        const SizedBox(height: 10),
        _buildMetricCard(
          c,
          'Tahmini Maliyet (${ai.periodDays} gün)',
          '\$${ai.estimatedCostUsd.toStringAsFixed(4)}',
          Icons.attach_money_outlined,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        buildAdminSectionTitle('ÖZELLİK BAZLI KULLANIM', c),
        const SizedBox(height: 10),
        if (ai.byFeature.isEmpty)
          buildAdminCard(
            c: c,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Bu dönemde AI kullanımı yok',
                  style: TextStyle(color: c.textSecondary, fontSize: 12)),
            ),
          )
        else
          buildAdminCard(
            c: c,
            child: Column(
              children: [
                for (var i = 0; i < ai.byFeature.length; i++)
                  _buildFeatureRow(
                    c,
                    ai.byFeature[i],
                    maxTokens: ai.byFeature.first.totalTokens,
                    isLast: i == ai.byFeature.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMetricCard(AppColors c, String label, String value, IconData icon,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kAdminAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kAdminAccent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: TextStyle(color: c.textHint, fontSize: 10.5),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(AppColors c, AiFeatureUsage f,
      {required int maxTokens, required bool isLast}) {
    final fraction = maxTokens > 0 ? f.totalTokens / maxTokens : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: c.divider, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _featureLabel(f.feature),
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${f.calls} çağrı · ${_formatCount(f.totalTokens)} token',
                style: TextStyle(color: c.textHint, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: c.divider,
              color: kAdminAccent,
            ),
          ),
        ],
      ),
    );
  }

  static String _featureLabel(String feature) {
    switch (feature) {
      case 'classifier':
        return 'Sınıflandırıcı';
      case 'extractor':
        return 'Bilgi Çıkarıcı';
      case 'reply_generator':
        return 'Yanıt Üretici';
      case 'calendar':
        return 'Takvim';
      case 'writer':
        return 'Mail Yazarı';
      default:
        return feature;
    }
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
