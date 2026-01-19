import 'package:shared_preferences/shared_preferences.dart';

/// Permission helper class to check user permissions based on their role.
///
/// Roles:
/// - 'admin' (Super Admin): Full access to everything
/// - 'edit': Can only perform edit operations
/// - 'delete': Can only perform delete operations
/// - 'full': Full access (edit, delete, add)
class PermissionHelper {
  /// Check if the current user can perform edit operations
  static Future<bool> canEdit() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType');
    final role = prefs.getString('userRole') ?? 'full';

    // Super admin can do everything
    if (userType == 'admin') return true;

    // Sub-admin permission check
    return role == 'edit' || role == 'full';
  }

  /// Check if the current user can perform delete operations
  static Future<bool> canDelete() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType');
    final role = prefs.getString('userRole') ?? 'full';

    // Super admin can do everything
    if (userType == 'admin') return true;

    // Sub-admin permission check
    return role == 'delete' || role == 'full';
  }

  /// Check if the current user can perform add operations
  static Future<bool> canAdd() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType');
    final role = prefs.getString('userRole') ?? 'full';

    // Super admin can do everything
    if (userType == 'admin') return true;

    // Only full access sub-admins can add
    return role == 'full';
  }

  /// Check if the current user is a super admin
  static Future<bool> isSuperAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType');
    return userType == 'admin';
  }

  /// Get the current user's role
  static Future<String> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType');

    if (userType == 'admin') return 'Super Admin';

    final role = prefs.getString('userRole') ?? 'full';
    switch (role) {
      case 'edit':
        return 'Edit Only';
      case 'delete':
        return 'Delete Only';
      case 'full':
        return 'Full Access';
      default:
        return 'Unknown';
    }
  }

  /// Get role display name from role code
  static String getRoleDisplayName(String? roleCode) {
    switch (roleCode) {
      case 'edit':
        return 'Edit Only';
      case 'delete':
        return 'Delete Only';
      case 'full':
        return 'Full Access';
      default:
        return 'Full Access';
    }
  }
}
