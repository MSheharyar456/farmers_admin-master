import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:farmers_admin/config/api_config.dart';

class AdminNotificationService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Send notification to a specific user or broadcast to all
  static Future<Map<String, dynamic>> sendNotification({
    required String title,
    required String message,
    String? userId, // null = broadcast to all
    String type = 'admin_broadcast',
    String? authToken,
  }) async {
    try {
      debugPrint('[AdminNotificationService] Sending notification...');
      debugPrint('[AdminNotificationService] Auth token: ${authToken != null ? "${authToken.substring(0, authToken.length > 20 ? 20 : authToken.length)}..." : "NULL"}');
      debugPrint('[AdminNotificationService] User ID: $userId');
      
      final response = await _dio.post(
        '/admin/notifications',
        data: {
          'title': title,
          'message': message,
          'userId': userId,
          'type': type,
        },
        options: Options(
          headers: authToken != null
              ? {
                  'Authorization': 'Bearer $authToken',
                  'X-Authorization': 'Bearer $authToken',
                }
              : {},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'notification': response.data['notification'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to send notification',
        };
      }
    } on DioException catch (e) {
      debugPrint('[AdminNotificationService] DioError: ${e.message}');
      debugPrint('[AdminNotificationService] Status code: ${e.response?.statusCode}');
      debugPrint('[AdminNotificationService] Response data: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      debugPrint('[AdminNotificationService] Unexpected error: $e');
      return {
        'success': false,
        'message': 'Unexpected error occurred',
      };
    }
  }

  /// Get all notifications (for admin panel list)
  static Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
    int offset = 0,
    String? authToken,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
        options: Options(
          headers: authToken != null
              ? {
                  'Authorization': 'Bearer $authToken',
                  'X-Authorization': 'Bearer $authToken',
                }
              : null,
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'notifications': response.data['notifications'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to fetch notifications',
        };
      }
    } on DioException catch (e) {
      debugPrint('[AdminNotificationService] Get error: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      debugPrint('[AdminNotificationService] Get unexpected error: $e');
      return {
        'success': false,
        'message': 'Unexpected error occurred',
      };
    }
  }
}
