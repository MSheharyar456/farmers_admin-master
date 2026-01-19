// services/fcm_service.dart
// FCM service using HTTP v1 API with OAuth 2.0 authentication
// Web-compatible version - embeds service account credentials
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

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

/// FCM service using HTTP v1 API with OAuth 2.0 authentication
/// Web-compatible - embeds service account credentials
class FCMService {
  // ⚠️ Service account credentials embedded for web compatibility
  // This contains your Firebase service account private key
  static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "mahsolek-8417b",
  "private_key_id": "a77da876ec4e0e848820c1dcf58fefe48fd7d573",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCbg1kgKj6qG+NK\\n5EwGjpAtoj/9tOzepw+hJxoVP6biJqc0N0FESz+sW59dUwf/qLiBMvhy9vMQxicF\\n8a7rKo2F4vW+aa+b7iuQgXpT+uywMvDvj0+mliiBWWEPLoGheTIYCGVR1vyICoM1\\nPPlYHKoEDgui75HGZ/40JYZgXXqVLgKK/GeCyYHhDpQgLzgjzSF0/YG07GZ3+8Rw\\nwAk34JfVpDaUCS4S72F/S6gm6csBUsE/41cZ78bhTkoj+VvwX92xzUFDROtpvhSc\\n0LgtVxNFFuvSltPmV5ufcbHM0kNP+tkY2HpM/W00fI7WiH5WmH5BimONIZkhpaMX\\nzLlDDU5JAgMBAAECggEAA9GXYPtSLs76TcH9l4gG3iAAVN4NY2N6nKxY1YTxHgq9\\n8cHNMZY5c4vybCu+sNZdskp904p6qhxIVzrs+F7DB+Xsi+bzeXxBOwF67zbK4U7D\\nuaMGw5WNwnnFfazYlEFlUgLB98VnZ33LZNJg+xSetifHVsWhCkK035nv5H9KV2ec\\n7bS/kN1ocpV9FeNWQn0zrF6u15rgV4bGBpGolU1wbVeHnabzHkE82DX9POp4l2Ee\\nf87CN4vnVjOwmNIIF+r+vjmIVoS/C2KBG//R/kgqwbZHIz5OWpxic5WLKFiNu4WQ\\nHc8j6PDSvsGTRQeOcAg80pMZi1hTZI8gBJwLoXocqQKBgQDKfMeG/VE74bGCKyeL\\n9bScLSf63k9UChv2g9U4H192qOqiggNAX4X30xTc1cYhhzjH1gfWsiDPqEelLWYV\\nX71vGTAiOInLaC/FkJLU244y5LOvQJTA/ZPd5ByhucCGt/wRwwYuy+xTND8Znahp\\n8TrrbJkIewX7i7cX0fjvWctz5QKBgQDEnIjz7Szak0ALMz2jpkR2lidijh62AYaJ\\n9jGg+0tryLiZTo6ME1dbmkv5q7MRO9qFwu4wY8fTbg61rizwtEDYcRZf22SDrYI0\\nPjfwkfIyt557+XKm5PTisKCVy3/eNdSeG3rAsrFrg7JbuLxnf643UFWBr+ZFhiH+\\nHqMOuT3SlQKBgGx2dGaBkJ7z4SKpvRBCeBFkOtMte+63T403xuG+JGOqTazo2ZcE\\n0/0Q607zj6LsDOU2Z5KAbgTtzhrTe6gdVZqKMndSM7VqRJSeQZiVVtE6ImnQvR23\\ndxpXk2Kp3lALg5F8FvbAMwHKrbYp9klxdy8eR8b8JxM8HsI6rg5/2fRlAoGBAKT2\\nHaZkCi0+PQ7oqEAFgg3pgBQd4ECfWQ2qJgvGrIo7uD7Q/aMjmzk9ZZ+O40iDap6u\\nZgDtxzxrbCYdhJFU+89eWwKEZnpg+wzwYykSmx7Ylz23lu3Wzmzg+2uTea6shb8+\\nmSjTBS+LKPvyLQm9xCOe4I9WUaNlnmHDvNXesLNdAoGAZwBlycVnXnRR09D69F4A\\nEY7gHtKeGUqjROuLiK2cnZtefN8C2NSRCi56aD2wsdBiWAMlXCnqd+QpGWmea5mo\\nP0DRkBXkPIvtYW/o9KgqtHfMsXpPElFdNn7JELkEVISnXwdQDc2xPXSbC1CA+zk5\\nmP5vEBFCa3/IoHOGDYFeBd4=\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-fbsvc@mahsolek-8417b.iam.gserviceaccount.com",
  "client_id": "106385997480941082069",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40mahsolek-8417b.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

  // FCM v1 API scope
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  // Cache for access token to avoid regenerating for every request
  static auth.AccessToken? _cachedToken;
  static DateTime? _tokenExpiry;

  // Maximum number of retry attempts for transient errors
  static const int _maxRetries = 2;

  // Delay between retries (in milliseconds)
  static const Duration _retryDelay = Duration(seconds: 1);

  /// Get OAuth 2.0 access token from service account
  /// Caches token and reuses until expiration
  static Future<String> _getAccessToken() async {
    try {
      // Check if we have a valid cached token
      if (_cachedToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!)) {
        debugPrint('Using cached OAuth 2.0 access token');
        return _cachedToken!.data;
      }

      debugPrint('========================================');
      debugPrint('Generating new OAuth 2.0 access token');
      debugPrint('========================================');

      // Parse service account credentials from embedded JSON
      final serviceAccountData =
          jsonDecode(_serviceAccountJson) as Map<String, dynamic>;

      // Validate that the service account has been configured
      if (serviceAccountData['private_key'] == 'PASTE_YOUR_PRIVATE_KEY_HERE') {
        throw Exception(
          'Service account credentials not configured. Please update _serviceAccountJson in fcm_service.dart',
        );
      }

      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        serviceAccountData,
      );

      // Obtain access credentials
      final client = http.Client();
      try {
        final accessCredentials = await auth
            .obtainAccessCredentialsViaServiceAccount(
              accountCredentials,
              _scopes,
              client,
            );

        // Cache the token
        _cachedToken = accessCredentials.accessToken;
        _tokenExpiry = _cachedToken!.expiry;

        debugPrint('✅ OAuth 2.0 token generated successfully');
        debugPrint('Token expires at: ${_tokenExpiry!.toIso8601String()}');
        debugPrint('========================================');

        return _cachedToken!.data;
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('ERROR: Failed to generate OAuth 2.0 access token');
      debugPrint('Error: $e');
      debugPrint('Stack Trace: $stackTrace');
      debugPrint('========================================');
      rethrow;
    }
  }

  /// Get Firebase project ID from service account
  static String _getProjectId() {
    try {
      final serviceAccountData =
          jsonDecode(_serviceAccountJson) as Map<String, dynamic>;

      final projectId = serviceAccountData['project_id'] as String?;
      if (projectId == null || projectId.isEmpty) {
        throw Exception('project_id not found in service account JSON');
      }

      return projectId;
    } catch (e) {
      debugPrint('ERROR: Failed to get project ID from service account: $e');
      rethrow;
    }
  }

  /// Send push notification to a specific user via FCM using HTTP v1 API
  ///
  /// [fcmToken] - The FCM token of the target user
  /// [title] - Notification title
  /// [message] - Notification message body
  /// [userId] - User ID for logging purposes
  ///
  /// Returns [FCMNotificationResult] with success status and details
  static Future<FCMNotificationResult> sendPushNotification({
    required String fcmToken,
    required String title,
    required String message,
    required String userId,
  }) async {
    final timestamp = DateTime.now();

    // Log request details
    debugPrint('========================================');
    debugPrint('FCM HTTP v1 API Request Started');
    debugPrint('Timestamp: ${timestamp.toIso8601String()}');
    debugPrint('User ID: $userId');
    debugPrint(
      'FCM Token: ${fcmToken.length > 50 ? "${fcmToken.substring(0, 50)}..." : fcmToken}',
    );
    debugPrint('Title: $title');
    debugPrint('Message: $message');
    debugPrint('========================================');

    // Validate FCM token
    if (fcmToken.isEmpty || fcmToken.trim().isEmpty) {
      final error = 'FCM Token is empty or invalid';
      debugPrint('ERROR: $error');
      debugPrint('========================================');
      return FCMNotificationResult(
        success: false,
        message: error,
        timestamp: timestamp,
        errorDetails: 'FCM token validation failed: token is empty',
      );
    }

    // Retry logic for transient errors
    int attempt = 0;
    while (attempt <= _maxRetries) {
      try {
        if (attempt > 0) {
          debugPrint(
            'Retry attempt $attempt of $_maxRetries after ${_retryDelay.inSeconds}s delay...',
          );
          await Future.delayed(_retryDelay);
        }

        // Get OAuth 2.0 access token
        final accessToken = await _getAccessToken();

        // Get project ID
        final projectId = _getProjectId();

        // Build FCM v1 API endpoint
        final fcmEndpoint =
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

        // Prepare request body (v1 API format)
        final requestBody = {
          'message': {
            'token': fcmToken.trim(),
            'notification': {'title': title.trim(), 'body': message.trim()},
            'data': {
              'type': 'admin_notification',
              'userId': userId,
              'title': title.trim(),
              'message': message.trim(),
              'timestamp': timestamp.millisecondsSinceEpoch.toString(),
            },
            'android': {
              'priority': 'high',
              'notification': {
                'sound': 'default',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default', 'badge': 1},
              },
            },
          },
        };

        debugPrint('Sending HTTP POST to FCM v1 API...');
        debugPrint('Endpoint: $fcmEndpoint');

        // Send HTTP POST request to FCM v1 API
        final response = await http
            .post(
              Uri.parse(fcmEndpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Request timeout after 30 seconds');
              },
            );

        // Log response details
        debugPrint('========================================');
        debugPrint('FCM v1 API Response Received');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('========================================');

        // Parse response
        if (response.statusCode == 200) {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          final messageName = responseData['name'] as String?;

          final successMessage =
              'Notification sent successfully. Message: $messageName';
          debugPrint('SUCCESS: $successMessage');
          debugPrint('========================================');
          return FCMNotificationResult(
            success: true,
            message: successMessage,
            timestamp: timestamp,
            responseData: responseData,
          );
        } else {
          // HTTP error
          final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
          debugPrint('ERROR: $errorMessage');
          debugPrint('========================================');

          // Try to parse error details from response
          String? errorDetails;
          try {
            final errorData = jsonDecode(response.body) as Map<String, dynamic>;
            errorDetails = errorData['error']?['message'] ?? errorMessage;
          } catch (_) {
            errorDetails = errorMessage;
          }

          // Check if error is retryable
          if (_isRetryableStatusCode(response.statusCode) &&
              attempt < _maxRetries) {
            attempt++;
            continue; // Retry
          }

          return FCMNotificationResult(
            success: false,
            message: 'Failed to send notification: $errorDetails',
            timestamp: timestamp,
            errorDetails: errorDetails,
          );
        }
      } on Exception catch (e, stackTrace) {
        // Handle exceptions (timeout, network, etc.)
        final errorMessage = e.toString();
        debugPrint('========================================');
        debugPrint('Exception while calling FCM v1 API');
        debugPrint('Error: $errorMessage');
        debugPrint('Attempt: ${attempt + 1} of ${_maxRetries + 1}');
        debugPrint('Stack Trace: $stackTrace');
        debugPrint('========================================');

        // Check if error is retryable
        final isRetryable = _isRetryableException(e);

        if (isRetryable && attempt < _maxRetries) {
          attempt++;
          continue; // Retry
        }

        // Non-retryable error or max retries reached
        return FCMNotificationResult(
          success: false,
          message: 'Failed to send notification: $errorMessage',
          timestamp: timestamp,
          errorDetails: errorMessage,
        );
      } catch (e, stackTrace) {
        // Handle any other unexpected errors
        final errorMessage = e.toString();
        debugPrint('========================================');
        debugPrint('Unexpected error while calling FCM v1 API');
        debugPrint('Error: $errorMessage');
        debugPrint('Attempt: ${attempt + 1} of ${_maxRetries + 1}');
        debugPrint('Stack Trace: $stackTrace');
        debugPrint('========================================');

        if (attempt < _maxRetries) {
          attempt++;
          continue; // Retry
        }

        return FCMNotificationResult(
          success: false,
          message: 'Failed to send notification: $errorMessage',
          timestamp: timestamp,
          errorDetails: errorMessage,
        );
      }
    }

    // Should never reach here, but just in case
    return FCMNotificationResult(
      success: false,
      message: 'Failed to send notification: Max retries exceeded',
      timestamp: timestamp,
      errorDetails: 'Max retries ($_maxRetries) exceeded',
    );
  }

  /// Check if HTTP status code is retryable
  static bool _isRetryableStatusCode(int statusCode) {
    // Retryable HTTP status codes
    const retryableStatusCodes = [
      500, // Internal Server Error
      502, // Bad Gateway
      503, // Service Unavailable
      504, // Gateway Timeout
    ];

    return retryableStatusCodes.contains(statusCode);
  }

  /// Check if an exception is retryable
  static bool _isRetryableException(Exception e) {
    final errorString = e.toString().toLowerCase();

    // Retry on timeout, network, or connection errors
    return errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket');
  }

  /// Validate if FCM token format looks correct
  static bool isValidFCMToken(String? token) {
    if (token == null || token.isEmpty) return false;
    // Basic validation - FCM tokens are typically long strings
    return token.length > 20 && !token.contains(' ');
  }

  /// Clear cached access token (useful for testing or forcing refresh)
  static void clearTokenCache() {
    _cachedToken = null;
    _tokenExpiry = null;
    debugPrint('OAuth 2.0 token cache cleared');
  }
}
