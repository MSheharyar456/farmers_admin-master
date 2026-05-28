/// Model for admin panel user (from server auth).
class AdminUser {
  final String id;
  final String email;
  final String? username;
  final String role;
  final String userType;

  const AdminUser({
    required this.id,
    required this.email,
    this.username,
    required this.role,
    required this.userType,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      role: json['role'] as String? ?? 'sub-admin',
      userType: json['userType'] as String? ?? 'sub-admin',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'role': role,
        'userType': userType,
      };

  /// Display name for header/menu (username or email).
  String get displayName => (username != null && username!.isNotEmpty) ? username! : email;
}
