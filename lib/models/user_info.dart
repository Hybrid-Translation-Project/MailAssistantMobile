class UserInfo {
  final String fullName;
  final String companyName;
  final String role;

  UserInfo({required this.fullName, required this.companyName, required this.role});

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        fullName: json['full_name'] ?? '',
        companyName: json['company_name'] ?? '',
        role: json['role'] ?? 'user',
      );
}

class LicenseStatus {
  final bool valid;
  final String? reason;
  final bool isAdmin;

  LicenseStatus({required this.valid, this.reason, required this.isAdmin});

  factory LicenseStatus.fromJson(Map<String, dynamic> json) => LicenseStatus(
        valid: json['valid'] ?? false,
        reason: json['reason'],
        isAdmin: json['is_admin'] ?? false,
      );
}
