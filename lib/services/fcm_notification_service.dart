// services/fcm_notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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

/// Service class to handle Firebase Cloud Messaging push notifications using V1 API
class FCMNotificationService {
  // Firebase Project ID
  static const String _projectId = 'mahsolek-8417b';
  
  // FCM V1 API endpoint
  static String get _fcmV1ApiUrl => 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
  
  // OAuth 2.0 Token endpoint
  static const String _oauthTokenUrl = 'https://oauth2.googleapis.com/token';
  
  // Service Account Configuration
  static const String _serviceAccountEmail = 'firebase-adminsdk-fbsvc@mahsolek-8417b.iam.gserviceaccount.com';
  static const String _serviceAccountPrivateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCbg1kgKj6qG+NK
5EwGjpAtoj/9tOzepw+hJxoVP6biJqc0N0FESz+sW59dUwf/qLiBMvhy9vMQxicF
8a7rKo2F4vW+aa+b7iuQgXpT+uywMvDvj0+mliiBWWEPLoGheTIYCGVR1vyICoM1
PPlYHKoEDgui75HGZ/40JYZgXXqVLgKK/GeCyYHhDpQgLzgjzSF0/YG07GZ3+8Rw
wAk34JfVpDaUCS4S72F/S6gm6csBUsE/41cZ78bhTkoj+VvwX92xzUFDROtpvhSc
0LgtVxNFFuvSltPmV5ufcbHM0kNP+tkY2HpM/W00fI7WiH5WmH5BimONIZkhpaMX
zLlDDU5JAgMBAAECggEAA9GXYPtSLs76TcH9l4gG3iAAVN4NY2N6nKxY1YTxHgq9
8cHNMZY5c4vybCu+sNZdskp904p6qhxIVzrs+F7DB+Xsi+bzeXxBOwF67zbK4U7D
uaMGw5WNwnnFfazYlEFlUgLB98VnZ33LZNJg+xSetifHVsWhCkK035nv5H9KV2ec
7bS/kN1ocpV9FeNWQn0zrF6u15rgV4bGBpGolU1wbVeHnabzHkE82DX9POp4l2Ee
f87CN4vnVjOwmNIIF+r+vjmIVoS/C2KBG//R/kgqwbZHIz5OWpxic5WLKFiNu4WQ
Hc8j6PDSvsGTRQeOcAg80pMZi1hTZI8gBJwLoXocqQKBgQDKfMeG/VE74bGCKyeL
9bScLSf63k9UChv2g9U4H192qOqiggNAX4X30xTc1cYhhzjH1gfWsiDPqEelLWYV
X71vGTAiOInLaC/FkJLU244y5LOvQJTA/ZPd5ByhucCGt/wRwwYuy+xTND8Znahp
8TrrbJkIewX7i7cX0fjvWctz5QKBgQDEnIjz7Szak0ALMz2jpkR2lidijh62AYaJ
9jGg+0tryLiZTo6ME1dbmkv5q7MRO9qFwu4wY8fTbg61rizwtEDYcRZf22SDrYI0
PjfwkfIyt557+XKm5PTisKCVy3/eNdSeG3rAsrFrg7JbuLxnf643UFWBr+ZFhiH+
HqMOuT3SlQKBgGx2dGaBkJ7z4SKpvRBCeBFkOtMte+63T403xuG+JGOqTazo2ZcE
0/0Q607zj6LsDOU2Z5KAbgTtzhrTe6gdVZqKMndSM7VqRJSeQZiVVtE6ImnQvR23
dxpXk2Kp3lALg5F8FvbAMwHKrbYp9klxdy8eR8b8JxM8HsI6rg5/2fRlAoGBAKT2
HaZkCi0+PQ7oqEAFgg3pgBQd4ECfWQ2qJgvGrIo7uD7Q/aMjmzk9ZZ+O40iDap6u
ZgDtxzxrbCYdhJFU+89eWwKEZnpg+wzwYykSmx7Ylz23lu3Wzmzg+2uTea6shb8+
mSjTBS+LKPvyLQm9xCOe4I9WUaNlnmHDvNXesLNdAoGAZwBlycVnXnRR09D69F4A
EY7gHtKeGUqjROuLiK2cnZtefN8C2NSRCi56aD2wsdBiWAMlXCnqd+QpGWmea5mo
P0DRkBXkPIvtYW/o9KgqtHfMsXpPElFdNn7JELkEVISnXwdQDc2xPXSbC1CA+zk5
mP5vEBFCa3/IoHOGDYFeBd4=
-----END PRIVATE KEY-----''';
  
  // Cache for access token to avoid regenerating on every request
  static String? _cachedAccessToken;
  static DateTime? _cachedTokenExpiry;
  
  /// Generate JWT for OAuth 2.0 service account authentication
  static String _generateJWT() {
    try {
      final now = DateTime.now().toUtc();
      final expiry = now.add(const Duration(hours: 1));
      
      // JWT Header
      final header = {
        'alg': 'RS256',
        'typ': 'JWT',
      };
      
      // JWT Claim Set
      final claimSet = {
        'iss': _serviceAccountEmail,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': _oauthTokenUrl,
        'exp': expiry.millisecondsSinceEpoch ~/ 1000,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
      };
      
      // Encode header and claim set
      final encodedHeader = _base64UrlEncode(utf8.encode(jsonEncode(header)));
      final encodedClaimSet = _base64UrlEncode(utf8.encode(jsonEncode(claimSet)));
      
      // Create signature input
      final signatureInput = '$encodedHeader.$encodedClaimSet';
      
      // Sign with RSA-SHA256
      final signatureBytes = _signRSA256(signatureInput, _serviceAccountPrivateKey);
      final encodedSignature = _base64UrlEncode(signatureBytes);
      
      // Return complete JWT
      return '$signatureInput.$encodedSignature';
    } catch (e) {
      debugPrint('Error generating JWT: $e');
      rethrow;
    }
  }
  
  /// Base64 URL encode (without padding)
  static String _base64UrlEncode(List<int> bytes) {
    return base64Encode(bytes)
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');
  }
  
  /// Sign data using RSA-SHA256
  /// Note: Full RSA signing implementation requires complex ASN.1 parsing
  /// For production use, please use Firebase Cloud Functions (recommended)
  /// or implement proper RSA signing with a library like `jose` package
  static List<int> _signRSA256(String data, String privateKeyPEM) {
    // RSA signing is complex and requires proper ASN.1 parsing
    // This is a placeholder - you should use Cloud Functions or implement proper RSA signing
    throw UnimplementedError(
      'RSA signing requires additional setup. '
      'Please use Firebase Cloud Functions for FCM V1 API. '
      'See FCM_SETUP_INSTRUCTIONS.md for details.'
    );
  }
  
  /// Get OAuth 2.0 access token
  static Future<String?> _getAccessToken() async {
    try {
      // Check if cached token is still valid
      if (_cachedAccessToken != null && 
          _cachedTokenExpiry != null && 
          DateTime.now().isBefore(_cachedTokenExpiry!)) {
        return _cachedAccessToken;
      }
      
      debugPrint('Generating new OAuth 2.0 access token...');
      
      // For now, return null - user needs to configure service account
      // In production, implement proper OAuth 2.0 flow
      if (_serviceAccountEmail == 'YOUR_SERVICE_ACCOUNT_EMAIL@mahsolek-8417b.iam.gserviceaccount.com' ||
          _serviceAccountPrivateKey.contains('YOUR_PRIVATE_KEY_HERE')) {
        return null;
      }
      
      // Generate JWT
      final jwt = _generateJWT();
      
      // Exchange JWT for access token
      final response = await http.post(
        Uri.parse(_oauthTokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('OAuth token request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = tokenData['access_token'] as String;
        final expiresIn = tokenData['expires_in'] as int;
        
        // Cache token
        _cachedAccessToken = accessToken;
        _cachedTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // Refresh 1 minute early
        
        debugPrint('OAuth 2.0 access token obtained successfully');
        return accessToken;
      } else {
        debugPrint('Failed to get OAuth token: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting OAuth access token: $e');
      return null;
    }
  }
  
  /// Send push notification to a specific user via FCM V1 API
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
    debugPrint('FCM V1 Notification Request Started');
    debugPrint('Timestamp: ${timestamp.toIso8601String()}');
    debugPrint('User ID: $userId');
    debugPrint('FCM Token: ${fcmToken.length > 50 ? "${fcmToken.substring(0, 50)}..." : fcmToken}');
    debugPrint('Title: $title');
    debugPrint('Message: $message');
    debugPrint('Project ID: $_projectId');
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

    // Validate service account configuration
    if (_serviceAccountEmail == 'YOUR_SERVICE_ACCOUNT_EMAIL@mahsolek-8417b.iam.gserviceaccount.com' ||
        _serviceAccountPrivateKey.contains('YOUR_PRIVATE_KEY_HERE')) {
      final error = 'FCM Service Account is not configured. Please configure service account credentials in fcm_notification_service.dart.\n\n'
          'To configure:\n'
          '1. Go to Firebase Console > Project Settings > Service Accounts\n'
          '2. Click "Generate new private key"\n'
          '3. Download the JSON file\n'
          '4. Extract client_email and private_key from JSON\n'
          '5. Update _serviceAccountEmail and _serviceAccountPrivateKey in this file';
      debugPrint('ERROR: $error');
      debugPrint('========================================');
      return FCMNotificationResult(
        success: false,
        message: error,
        timestamp: timestamp,
        errorDetails: 'Service account not configured',
      );
    }

    try {
      // Get OAuth 2.0 access token
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        final error = 'Failed to obtain OAuth 2.0 access token. Please check service account configuration.';
        debugPrint('ERROR: $error');
        debugPrint('========================================');
        return FCMNotificationResult(
          success: false,
          message: error,
          timestamp: timestamp,
          errorDetails: 'OAuth token generation failed',
        );
      }

      // Prepare FCM V1 API notification payload
      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': message,
          },
          'data': {
            'type': 'admin_notification',
            'userId': userId,
            'title': title,
            'message': message,
            'timestamp': timestamp.millisecondsSinceEpoch.toString(),
          },
          'android': {
            'priority': 'high',
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      debugPrint('FCM V1 Payload: ${jsonEncode(payload)}');

      // Send HTTP POST request to FCM V1 API
      final response = await http.post(
        Uri.parse(_fcmV1ApiUrl),
        headers: {
          'Content-Type': 'application/json; UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('FCM V1 request timeout after 30 seconds');
        },
      );

      // Log response details
      debugPrint('========================================');
      debugPrint('FCM V1 Notification Response Received');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('========================================');

      // Parse response
      Map<String, dynamic>? responseData;
      try {
        if (response.body.isNotEmpty) {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Warning: Could not parse response body as JSON: $e');
      }

      // Check if request was successful
      if (response.statusCode == 200) {
        final messageName = responseData?['name'] as String?;
        if (messageName != null) {
          // Success
          final successMessage = 'Notification sent successfully via FCM V1 API. Message: $messageName';
          debugPrint('SUCCESS: $successMessage');
          debugPrint('========================================');
          return FCMNotificationResult(
            success: true,
            message: successMessage,
            timestamp: timestamp,
            responseData: responseData,
          );
        } else {
          // Unexpected response format
          final errorMessage = 'Unexpected response format from FCM V1 API';
          debugPrint('ERROR: $errorMessage');
          debugPrint('========================================');
          return FCMNotificationResult(
            success: false,
            message: errorMessage,
            timestamp: timestamp,
            responseData: responseData,
            errorDetails: response.body,
          );
        }
      } else {
        // HTTP error
        final errorData = responseData?['error'] as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] as String? ?? response.body;
        final errorCode = errorData?['code'] as int? ?? response.statusCode;
        
        final fullErrorMessage = 'FCM V1 API returned error (Status: $errorCode): $errorMessage';
        debugPrint('ERROR: $fullErrorMessage');
        debugPrint('========================================');
        return FCMNotificationResult(
          success: false,
          message: 'Failed to send notification. Status: $errorCode',
          timestamp: timestamp,
          responseData: responseData,
          errorDetails: errorMessage.isNotEmpty ? errorMessage : response.body,
        );
      }
    } catch (e, stackTrace) {
      // Exception occurred
      final errorMessage = 'Exception while sending FCM V1 notification: $e';
      debugPrint('========================================');
      debugPrint('EXCEPTION: $errorMessage');
      debugPrint('Stack Trace: $stackTrace');
      debugPrint('========================================');
      return FCMNotificationResult(
        success: false,
        message: 'Failed to send notification: ${e.toString()}',
        timestamp: timestamp,
        errorDetails: e.toString(),
      );
    }
  }

  /// Validate if FCM token format looks correct
  static bool isValidFCMToken(String? token) {
    if (token == null || token.isEmpty) return false;
    // Basic validation - FCM tokens are typically long strings
    return token.length > 20 && !token.contains(' ');
  }
}
