// Admin panel API yanıtlarının veri modelleri.
// Backend: /api/v1/admin/* endpoint'leri (require_admin).

/// GET /admin/users — kullanıcı listesi elemanı.
class AdminUser {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;
  final bool mustChangePassword;
  final String? notificationEmail;
  final DateTime? createdAt;
  final int mailCount;
  final int taskCount;
  final int accountCount;

  AdminUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
    this.notificationEmail,
    this.createdAt,
    required this.mailCount,
    required this.taskCount,
    required this.accountCount,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final stats = (json['stats'] as Map?) ?? const {};
    return AdminUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? false,
      mustChangePassword: json['must_change_password'] ?? false,
      notificationEmail: json['notification_email'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      mailCount: (stats['mail_count'] ?? 0) as int,
      taskCount: (stats['task_count'] ?? 0) as int,
      accountCount: (stats['account_count'] ?? 0) as int,
    );
  }
}

/// GET /admin/stats — sistem geneli istatistikler.
class AdminSystemStats {
  final int totalUsers;
  final int activeUsers;
  final int totalMails;
  final int totalTasks;
  final List<AdminUserStat> users;

  AdminSystemStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalMails,
    required this.totalTasks,
    required this.users,
  });

  factory AdminSystemStats.fromJson(Map<String, dynamic> json) =>
      AdminSystemStats(
        totalUsers: json['total_users'] ?? 0,
        activeUsers: json['active_users'] ?? 0,
        totalMails: json['total_mails'] ?? 0,
        totalTasks: json['total_tasks'] ?? 0,
        users: ((json['users'] as List?) ?? const [])
            .map((e) => AdminUserStat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// GET /admin/stats → users[] — kullanıcı bazlı haftalık özet.
class AdminUserStat {
  final String userId;
  final String username;
  final String fullName;
  final bool isActive;
  final String role;
  final int totalMails;
  final int weeklyMails;
  final int totalTasks;
  final int completedTasks;
  final double taskCompletionRate;

  AdminUserStat({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.isActive,
    required this.role,
    required this.totalMails,
    required this.weeklyMails,
    required this.totalTasks,
    required this.completedTasks,
    required this.taskCompletionRate,
  });

  factory AdminUserStat.fromJson(Map<String, dynamic> json) => AdminUserStat(
        userId: json['user_id'] ?? '',
        username: json['username'] ?? '',
        fullName: json['full_name'] ?? '',
        isActive: json['is_active'] ?? false,
        role: json['role'] ?? 'user',
        totalMails: json['total_mails'] ?? 0,
        weeklyMails: json['weekly_mails'] ?? 0,
        totalTasks: json['total_tasks'] ?? 0,
        completedTasks: json['completed_tasks'] ?? 0,
        taskCompletionRate: (json['task_completion_rate'] ?? 0).toDouble(),
      );
}

/// GET /admin/ai-stats — AI (Gemini) kullanım istatistikleri.
/// Not: `by_day` bilinçli olarak modele alınmadı — mobilde günlük grafik yok.
class AdminAiStats {
  final int periodDays;
  final int totalCalls;
  final int totalTokens;
  final int totalPromptTokens;
  final int totalResponseTokens;
  final double avgDurationMs;
  final int promoSkipped;
  final double estimatedCostUsd;
  final List<AiFeatureUsage> byFeature;

  AdminAiStats({
    required this.periodDays,
    required this.totalCalls,
    required this.totalTokens,
    required this.totalPromptTokens,
    required this.totalResponseTokens,
    required this.avgDurationMs,
    required this.promoSkipped,
    required this.estimatedCostUsd,
    required this.byFeature,
  });

  factory AdminAiStats.fromJson(Map<String, dynamic> json) {
    final byFeature = <AiFeatureUsage>[];
    ((json['by_feature'] as Map?) ?? const {}).forEach((key, value) {
      byFeature.add(
          AiFeatureUsage.fromJson(key.toString(), value as Map<String, dynamic>));
    });
    // Çok kullanılan özellik en üstte görünsün.
    byFeature.sort((a, b) => b.totalTokens.compareTo(a.totalTokens));
    return AdminAiStats(
      periodDays: json['period_days'] ?? 0,
      totalCalls: json['total_calls'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
      totalPromptTokens: json['total_prompt_tokens'] ?? 0,
      totalResponseTokens: json['total_response_tokens'] ?? 0,
      avgDurationMs: (json['avg_duration_ms'] ?? 0).toDouble(),
      promoSkipped: json['promo_skipped'] ?? 0,
      estimatedCostUsd: (json['estimated_cost_usd'] ?? 0).toDouble(),
      byFeature: byFeature,
    );
  }
}

/// GET /admin/ai-stats → by_feature — özellik bazlı kullanım.
class AiFeatureUsage {
  final String feature;
  final int calls;
  final int totalTokens;

  AiFeatureUsage({
    required this.feature,
    required this.calls,
    required this.totalTokens,
  });

  factory AiFeatureUsage.fromJson(String feature, Map<String, dynamic> json) =>
      AiFeatureUsage(
        feature: feature,
        calls: json['calls'] ?? 0,
        totalTokens: json['total_tokens'] ?? 0,
      );
}

/// GET /admin/backup/status — yedekleme durumu (mobilde salt-okunur).
class AdminBackupStatus {
  final bool available;
  final bool s3Configured;
  final bool isRunning;
  final AdminLastBackup? lastBackup;

  AdminBackupStatus({
    required this.available,
    required this.s3Configured,
    required this.isRunning,
    this.lastBackup,
  });

  factory AdminBackupStatus.fromJson(Map<String, dynamic> json) {
    final current = (json['current'] as Map?) ?? const {};
    final last = json['last_backup'];
    return AdminBackupStatus(
      available: json['available'] ?? false,
      s3Configured: json['s3_configured'] ?? false,
      isRunning: current['state'] == 'running',
      lastBackup: last is Map
          ? AdminLastBackup.fromJson(last.cast<String, dynamic>())
          : null,
    );
  }
}

/// SystemConfig.last_backup — son yedeğin kalıcı sonucu.
class AdminLastBackup {
  final String status; // ok | error
  final String kind; // regular | preupdate | ...
  final String? filename;
  final DateTime? finishedAt;
  final int? sizeBytes;
  final bool? s3Uploaded;
  final String? error;

  AdminLastBackup({
    required this.status,
    required this.kind,
    this.filename,
    this.finishedAt,
    this.sizeBytes,
    this.s3Uploaded,
    this.error,
  });

  factory AdminLastBackup.fromJson(Map<String, dynamic> json) =>
      AdminLastBackup(
        status: json['status'] ?? '',
        kind: json['kind'] ?? '',
        filename: json['filename'],
        finishedAt: json['finished_at'] != null
            ? DateTime.tryParse(json['finished_at'].toString())
            : null,
        sizeBytes: json['size_bytes'],
        s3Uploaded: json['s3_uploaded'],
        error: json['error'],
      );

  bool get isOk => status == 'ok';
}
