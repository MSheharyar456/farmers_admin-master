// services/fcm_service.dart
// FCM service proxying requests through the VPS backend
// This prevents CORS issues in Flutter Web

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:farmers_admin/config/api_config.dart';

/// Result class for FCM notification sending
class FCMNotificationResult {
  final bool success;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? responseData;
  final String? errorDetails;

  FCMNotificationResult({
    required this.success,
    required this.message,
    required this.timestamp,
    this.responseData,
    this.errorDetails,
  });

  @override
  String toString() {
    return 'FCMNotificationResult{success: $success, message: $message, timestamp: $timestamp, errorDetails: $errorDetails}';
  }
}

/// FCM service that proxies requests through the Node.js backend
class FCMService {
  /// Send push notification to a specific user via VPS backend
  ///
  /// [fcmToken] - The FCM token of the target user
  /// [title] - Notification title
  /// [message] - Notification message body
  /// [userId] - User ID for logging purposes
  /// [adminToken] - Admin auth token to authenticate with the backend
  ///
  /// Returns [FCMNotificationResult] with success status and details
  static Future<FCMNotificationResult> sendPushNotification({
    required String fcmToken,
    required String title,
    required String message,
    required String userId,
    required String adminToken,
  }) async {
    final timestamp = DateTime.now();

    // Validate FCM token
    if (fcmToken.isEmpty || fcmToken.trim().isEmpty) {
      final error = 'FCM Token is empty or invalid';
      debugPrint('ERROR: $error');
      return FCMNotificationResult(
        success: false,
        message: error,
        timestamp: timestamp,
        errorDetails: 'FCM token validation failed: token is empty',
      );
    }

    try {
      final endpoint = '$apiBaseUrl/admin/test-fcm';
      debugPrint('Sending request to backend FCM endpoint: $endpoint');

      final requestBody = {
        'fcmToken': fcmToken.trim(),
        'title': title.trim(),
        'message': message.trim(),
        'userId': userId,
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      debugPrint('Backend response status: ${response.statusCode}');
      debugPrint('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        return FCMNotificationResult(
          success: true,
          message: 'Notification sent successfully via backend.',
          timestamp: timestamp,
          responseData: responseData,
        );
      } else {
        // Backend returned an error
        String errorDetails = 'HTTP ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['errorDetails'] != null) {
            errorDetails = errorData['errorDetails'];
          } else if (errorData['message'] != null) {
            errorDetails = errorData['message'];
          }
        } catch (_) {}

        return FCMNotificationResult(
          success: false,
          message: 'Failed to send notification via backend.',
          timestamp: timestamp,
          errorDetails: errorDetails,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in FCMService: $e');
      debugPrint('Stack Trace: $stackTrace');
      
      return FCMNotificationResult(
        success: false,
        message: 'Network or server error occurred.',
        timestamp: timestamp,
        errorDetails: e.toString(),
      );
    }
  }
}
