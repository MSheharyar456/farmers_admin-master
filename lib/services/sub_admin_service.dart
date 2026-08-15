import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service to manage sub-admin users via backend API
class SubAdminService {
  /// Get token from shared preferences
  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try multiple possible token keys
      String? token = prefs.getString(
        'farmers_admin_auth_token',
      ); // AdminServerAuthService key
      token ??= prefs.getString('auth_token'); // AuthService key

      final tokenValue = token ?? '';
      print(
        'DEBUG: SubAdminService - Token retrieved: ${tokenValue.isEmpty ? "EMPTY" : "EXISTS (${tokenValue.length} chars)"}',
      );
      return tokenValue;
    } catch (e) {
      print('DEBUG: SubAdminService - Error getting token: $e');
      return '';
    }
  }

  /// Fetch all sub-admins (users with is_admin = 1)
  Future<List<Map<String, dynamic>>> fetchSubAdmins() async {
    try {
      final token = await _getToken();

      // If token is empty, provide helpful error
      if (token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/admin/auth/admin-users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      }

      if (response.statusCode == 403) {
        throw Exception('You do not have permission to access this resource.');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['admins'] is List) {
          final List<Map<String, dynamic>> admins = [];
          for (var admin in data['admins']) {
            final roleValue = (admin['role'] ?? 'sub-admin')
                .toString()
                .toLowerCase();
            if (roleValue == 'admin') continue;

            admins.add({
              'id': admin['id'] ?? '',
              'username': admin['username'] ?? '',
              'email': admin['email'] ?? '',
              'isAdmin': true,
              'role': admin['role'] ?? 'sub-admin',
              'createdAt': admin['createdAt'] ?? admin['created_at'] ?? '',
            });
          }
          print(
            'DEBUG: Found ${admins.length} sub-admin users from admin_users table',
          );
          return admins;
        }
      }
      return [];
    } catch (e) {
      print('DEBUG: SubAdminService.fetchSubAdmins error: $e');
      rethrow;
    }
  }

  /// Create a new sub-admin user
  Future<SubAdminResult> createSubAdmin({
    required String username,
    required String email,
    required String password,
    required String passkey,
    required String role,
  }) async {
    try {
      final token = await _getToken();

      // If token is empty, provide helpful error
      if (token.isEmpty) {
        return SubAdminResult.failure(
          message: 'Session expired. Please login again.',
        );
      }

      // Create user in the users table
      final response = await http.post(
        Uri.parse('$apiBaseUrl/admin/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'passkey': passkey.trim(),
          'role': role.trim().isNotEmpty ? role.trim() : 'sub-admin',
        }),
      );

      if (response.statusCode == 401) {
        return SubAdminResult.failure(
          message: 'Authentication failed. Please login again.',
        );
      }

      if (response.statusCode == 403) {
        return SubAdminResult.failure(
          message: 'You do not have permission to create sub-admins.',
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print(
          'DEBUG: Sub-admin created successfully - ID: ${data['user']?['id']}, Email: $email',
        );
        return SubAdminResult.success(
          message: 'Sub Admin created successfully!',
          userId: data['user']?['id'] ?? '',
        );
      } else if (response.statusCode == 409) {
        // Email already exists
        return SubAdminResult.failure(
          message: 'Email already exists. Please use a different email.',
        );
      } else {
        return SubAdminResult.failure(
          message: data['message'] ?? 'Failed to create sub admin',
        );
      }
    } catch (e) {
      print('DEBUG: SubAdminService.createSubAdmin error: $e');
      return SubAdminResult.failure(message: 'Error: $e');
    }
  }

  /// Delete a sub-admin user
  Future<SubAdminResult> deleteSubAdmin(String userId) async {
    try {
      final token = await _getToken();

      // If token is empty, provide helpful error
      if (token.isEmpty) {
        return SubAdminResult.failure(
          message: 'Session expired. Please login again.',
        );
      }

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/admin/auth/admin-users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        return SubAdminResult.failure(
          message: 'Authentication failed. Please login again.',
        );
      }

      if (response.statusCode == 403) {
        return SubAdminResult.failure(
          message: 'You do not have permission to delete sub-admins.',
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return SubAdminResult.success(
          message: 'Sub Admin deleted successfully!',
          userId: userId,
        );
      } else {
        return SubAdminResult.failure(
          message: data['message'] ?? 'Failed to delete sub admin',
        );
      }
    } catch (e) {
      print('DEBUG: SubAdminService.deleteSubAdmin error: $e');
      return SubAdminResult.failure(message: 'Error: $e');
    }
  }
}

/// Result class for sub-admin operations
class SubAdminResult {
  final bool success;
  final String message;
  final String? userId;

  SubAdminResult({required this.success, required this.message, this.userId});

  factory SubAdminResult.success({required String message, String? userId}) {
    return SubAdminResult(success: true, message: message, userId: userId);
  }

  factory SubAdminResult.failure({required String message}) {
    return SubAdminResult(success: false, message: message);
  }
}
