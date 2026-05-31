// services/deleted_users_api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/deleted_user_model.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

const _tokenKey = 'farmers_admin_auth_token';

class DeletedUsersApiService {
  DeletedUsersApiService(this._authService);

  final AdminServerAuthService _authService;

  static const _connectTimeout = Duration(seconds: 30);
  static const _receiveTimeout = Duration(seconds: 30);

  Dio get _dio {
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
      ),
    );
    final token = _authService.authToken;
    if (token != null && token.isNotEmpty) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['X-Authorization'] = 'Bearer $token';
            return handler.next(options);
          },
        ),
      );
    }
    return dio;
  }

  Future<String?> _getToken() async {
    // First try in-memory token
    var token = _authService.authToken;
    if (token != null && token.isNotEmpty) {
      return token;
    }
    // Fallback to storage
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    return token;
  }

  Future<String?> getTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<List<DeletedUserModel>> getDeletedUsers({int limit = 100}) async {
    debugPrint('[DELETED_USERS_API] Fetching deleted users...');
    
    final token = await _getToken();
    debugPrint('[DELETED_USERS_API] Auth token: ${token != null ? 'present' : 'NULL'}');

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/deleted-users',
        queryParameters: {'limit': limit},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Authorization': 'Bearer $token',
          },
        ),
      );
      final data = res.data;
      debugPrint('[DELETED_USERS_API] Response: $data');
      if (data == null || data['success'] != true) return [];
      final users = data['users'] as List<dynamic>? ?? [];
      return users.map((u) => DeletedUserModel.fromMap(u as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      debugPrint('[DELETED_USERS_API] DioError: ${e.message}');
      debugPrint('[DELETED_USERS_API] DioError type: ${e.type}');
      debugPrint('[DELETED_USERS_API] DioError response: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<DeletedUserFullDetails?> getFullDetails(String userId) async {
    debugPrint('[DELETED_USERS_API] Fetching full details for user: $userId');
    debugPrint('[DELETED_USERS_API] API URL: ${apiBaseUrl}/admin/deleted-users/$userId/full-details');
    
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[DELETED_USERS_API] ERROR: No auth token');
      throw Exception('Not authenticated. Please log in again.');
    }
    debugPrint('[DELETED_USERS_API] Token present: ${token.substring(0, 20)}...');

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/deleted-users/$userId/full-details',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Authorization': 'Bearer $token',
          },
        ),
      );
      final data = res.data;
      debugPrint('[DELETED_USERS_API] Success! Response keys: ${data?.keys.toList()}');
      if (data == null || data['success'] != true) {
        debugPrint('[DELETED_USERS_API] Response success=false or null data');
        return null;
      }
      return DeletedUserFullDetails.fromMap(data);
    } on DioException catch (e) {
      debugPrint('[DELETED_USERS_API] DioError in getFullDetails: ${e.message}');
      debugPrint('[DELETED_USERS_API] Status code: ${e.response?.statusCode}');
      debugPrint('[DELETED_USERS_API] Response data: ${e.response?.data}');
      debugPrint('[DELETED_USERS_API] Error type: ${e.type}');
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      }
      if (e.response?.statusCode == 500) {
        final debugInfo = e.response?.data?['debug'] ?? 'No debug info';
        throw Exception('Server error (500): $debugInfo');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('[DELETED_USERS_API] Unexpected error: $e');
      debugPrint('[DELETED_USERS_API] Stack trace: $stackTrace');
      throw Exception('Error loading details: $e');
    }
  }

  Future<Map<String, dynamic>> transferDeletedUserPosts({
    required String userId,
    required String targetUserId,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/deleted-users/$userId/transfer-posts',
      data: {'targetUserId': targetUserId},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'X-Authorization': 'Bearer $token',
        },
      ),
    );

    final data = res.data;
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Failed to transfer posts');
    }
    return data;
  }

  Future<int> getDeletedUsersCount() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return 0;
      
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/deleted-users',
        queryParameters: {'limit': 500},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Authorization': 'Bearer $token',
          },
        ),
      );
      final data = res.data;
      if (data == null || data['success'] != true) return 0;
      final usersList = data['users'] as List<dynamic>? ?? [];
      return usersList.length;
    } catch (e) {
      debugPrint('[DELETED_USERS_API] Error getting count: $e');
      return 0;
    }
  }
}
