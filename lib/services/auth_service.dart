import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service to handle all authentication operations via Node.js API
class AuthService {
  // Check if user is logged in by checking for existence of JWT token
  Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  /// Sign up new admin user (sub-admin)
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
    required String passkey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/admin/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'username': username.trim(),
          'passkey': passkey.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return AuthResult.success(
          message: data['message'] ?? 'Account created successfully! Please log in.',
        );
      } else {
        return AuthResult.failure(
          message: data['message'] ?? 'Signup failed.',
        );
      }
    } catch (e) {
      print('DEBUG: AuthService.signUp error: $e');
      return AuthResult.failure(
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Login admin user
  Future<AuthResult> login({
    required String email,
    required String password,
    required String passkey,
    String? optionkey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/admin/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'passkey': passkey.trim(),
          'optionkey': optionkey?.trim() ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save token and user info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_id', data['user']['id']);
        await prefs.setString('user_email', data['user']['email']);
        await prefs.setString('user_name', data['user']['username']);
        await prefs.setString('user_role', data['user']['role']);
        await prefs.setString('userType', data['user']['userType']);

        return AuthResult.success(
          message: 'Login successful!',
          userType: data['user']['userType'],
        );
      } else {
        return AuthResult.failure(
          message: data['message'] ?? 'Invalid credentials.',
        );
      }
    } catch (e) {
      print('DEBUG: AuthService.login error: $e');
      return AuthResult.failure(
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    await prefs.remove('userType');
    await prefs.remove('activeMenuIndex');
  }

  /// Get the stored auth token for API calls
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

/// Result class for auth operations
class AuthResult {
  final bool isSuccess;
  final String message;
  final String? userType;

  AuthResult._({required this.isSuccess, required this.message, this.userType});

  factory AuthResult.success({required String message, String? userType}) {
    return AuthResult._(isSuccess: true, message: message, userType: userType);
  }

  factory AuthResult.failure({required String message}) {
    return AuthResult._(isSuccess: false, message: message);
  }
}