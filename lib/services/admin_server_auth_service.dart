import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/admin_user.dart';

const _tokenKey = 'farmers_admin_auth_token';

class AdminServerAuthService {
  static const _connectTimeout = Duration(seconds: 30);
  static const _receiveTimeout = Duration(seconds: 30);

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
    ),
  );
  
  final _storage = SharedPreferences.getInstance();

  final StreamController<AdminUser?> _authController =
      StreamController<AdminUser?>.broadcast();

  AdminUser? _currentUser;
  String? _token;

  AdminServerAuthService() {
    _loadStoredAuth();
  }

  Stream<AdminUser?> get authStateChanges => _authController.stream;

  AdminUser? get currentUser => _currentUser;

  /// Current JWT for API calls (e.g. AdminPostService). Null if not logged in.
  String? get authToken => _token;

  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await _storage;
      final token = prefs.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        _authController.add(null);
        return;
      }
      _token = token;
      final user = await _fetchMe();
      if (user != null) {
        _currentUser = user;
        _authController.add(user);
        // Save user data to SharedPreferences for other widgets
        final prefs = await _storage;
        await prefs.setString('user_id', user.id);
        await prefs.setString('user_email', user.email);
        await prefs.setString('user_name', user.username ?? '');
        await prefs.setString('userType', user.userType);
        await prefs.setString('userRole', user.role);
      } else {
        final prefs = await _storage;
        await prefs.remove(_tokenKey);
        _token = null;
        _currentUser = null;
        _authController.add(null);
      }
    } catch (_) {
      final prefs = await _storage;
      await prefs.remove(_tokenKey);
      _token = null;
      _currentUser = null;
      _authController.add(null);
    }
  }

  void _setAuth(String token, AdminUser user) {
    _token = token;
    _currentUser = user;
    _authController.add(user);
  }

  Future<void> _saveToken(String token) async {
    print('DEBUG: Saving token to SharedPreferences...');
    final prefs = await _storage;
    await prefs.setString(_tokenKey, token);
    print('DEBUG: Token saved successfully.');
  }

  Future<void> _clearToken() async {
    final prefs = await _storage;
    await prefs.remove(_tokenKey);
    _token = null;
    _currentUser = null;
    _authController.add(null);
  }

  Dio get _dioWithAuth {
    final d = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
      ),
    );
    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            final value = 'Bearer $_token';
            options.headers['Authorization'] = value;
            options.headers['X-Authorization'] = value;
          }
          return handler.next(options);
        },
      ),
    );
    return d;
  }

  /// Login with email, password, passkey, and optional optionkey (for admin).
  Future<AdminUser> login({
    required String email,
    required String password,
    required String passkey,
    String? optionkey,
  }) async {
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'passkey': passkey,
      if (optionkey != null && optionkey.isNotEmpty) 'optionkey': optionkey,
    };
    print('DEBUG: Attempting login for $email');
    print('DEBUG: API URL: ${apiBaseUrl}/admin/auth/login');
    try {
      final res = await _dio.post<Map<String, dynamic>>('/admin/auth/login', data: body);
      print('DEBUG: Received response: ${res.statusCode}');
      print('DEBUG: Response data: ${res.data}');
      final data = res.data;
      if (data == null || data['success'] != true) {
        final msg = data?['message'] as String? ?? 'Login failed';
        throw AdminAuthException(msg);
      }
      final token = data['token'] as String?;
      final userMap = data['user'] as Map<String, dynamic>?;
      if (token == null || userMap == null) {
        throw AdminAuthException('Invalid response from server');
      }
      final user = AdminUser.fromJson(userMap);
      await _saveToken(token);
      _setAuth(token, user);
      return user;
    } on DioException catch (e) {
      print('DEBUG: DioException during login: ${e.type} - ${e.message}');
      if (e.response != null) {
        print('DEBUG: Error response status: ${e.response?.statusCode}');
        print('DEBUG: Error response data: ${e.response?.data}');
      }
      final resp = e.response?.data;
      final serverMsg = resp is Map ? resp['message'] as String? : null;
      
      // Provide user-friendly error messages
      String userMessage;
      if (serverMsg != null && serverMsg.isNotEmpty) {
        userMessage = serverMsg.length > 100 ? '${serverMsg.substring(0, 100)}...' : serverMsg;
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        userMessage = 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        userMessage = 'Network error. Please check your internet connection.';
      } else if (e.response?.statusCode == 401) {
        userMessage = 'Invalid credentials. Please check your email, password, and passkey.';
      } else if (e.response?.statusCode == 404) {
        userMessage = 'Server not found. Please try again later.';
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        userMessage = 'Server error. Please try again later.';
      } else {
        userMessage = 'Login failed. Please try again.';
      }
      throw AdminAuthException(userMessage);
    }
  }

  /// Sign up (create sub-admin). Does not log in.
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String passkey,
  }) async {
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'username': username.trim(),
      'passkey': passkey,
    };
    try {
      final res = await _dio.post<Map<String, dynamic>>('/admin/auth/signup', data: body);
      final data = res.data;
      if (data == null || data['success'] != true) {
        final msg = data?['message'] as String? ?? 'Sign up failed';
        throw AdminAuthException(msg);
      }
    } on DioException catch (e) {
      final resp = e.response?.data;
      final serverMsg = resp is Map ? resp['message'] as String? : null;
      
      // Provide user-friendly error messages
      String userMessage;
      if (serverMsg != null && serverMsg.isNotEmpty) {
        userMessage = serverMsg.length > 100 ? '${serverMsg.substring(0, 100)}...' : serverMsg;
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        userMessage = 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        userMessage = 'Network error. Please check your internet connection.';
      } else if (e.response?.statusCode == 409) {
        userMessage = 'Email or username already exists.';
      } else if (e.response?.statusCode == 400) {
        userMessage = 'Invalid information. Please check your details.';
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        userMessage = 'Server error. Please try again later.';
      } else {
        userMessage = 'Sign up failed. Please try again.';
      }
      throw AdminAuthException(userMessage);
    }
  }

  /// Sign out (clear token and emit null).
  Future<void> signOut() async {
    await _clearToken();
  }

  Future<AdminUser?> _fetchMe() async {
    if (_token == null) return null;
    try {
      final res = await _dioWithAuth.get<Map<String, dynamic>>('/admin/me');
      final data = res.data;
      if (data == null || data['success'] != true) return null;
      final userMap = data['user'] as Map<String, dynamic>?;
      if (userMap == null) return null;
      return AdminUser.fromJson(userMap);
    } catch (_) {
      return null;
    }
  }
}

class AdminAuthException implements Exception {
  final String message;
  AdminAuthException(this.message);
  @override
  String toString() => message;
}
