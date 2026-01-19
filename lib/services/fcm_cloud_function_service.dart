// services/fcm_cloud_function_service.dart
// Alternative service using Firebase Cloud Functions (Recommended approach)
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Result class for FCM notification sending via Cloud Functions
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

/// Service class to handle Firebase Cloud Messaging push notifications via Cloud Functions
/// This is the RECOMMENDED approach - it's more secure and simpler than direct API calls
class FCMCloudFunctionService {
  // Cloud Function region - must match the region specified in functions/index.js
  static const String _cloudFunctionRegion = 'us-central1';
  
  // Maximum number of retry attempts for transient errors
  static const int _maxRetries = 2;
  
  // Delay between retries (in milliseconds)
  static const Duration _retryDelay = Duration(seconds: 1);

  /// Send push notification to a specific user via FCM using Cloud Functions
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
    debugPrint('FCM Cloud Function Request Started');
    debugPrint('Timestamp: ${timestamp.toIso8601String()}');
    debugPrint('Region: $_cloudFunctionRegion');
    debugPrint('User ID: $userId');
    debugPrint('FCM Token: ${fcmToken.length > 50 ? "${fcmToken.substring(0, 50)}..." : fcmToken}');
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
          debugPrint('Retry attempt $attempt of $_maxRetries after ${_retryDelay.inSeconds}s delay...');
          await Future.delayed(_retryDelay);
        }

        // Call Cloud Function to send notification with region specification
        final functions = FirebaseFunctions.instanceFor(region: _cloudFunctionRegion);
        final callable = functions.httpsCallable(
          'sendNotification',
          options: HttpsCallableOptions(
            timeout: const Duration(seconds: 30),
          ),
        );
        
        debugPrint('Calling Cloud Function: sendNotification (Region: $_cloudFunctionRegion)');
        
        final result = await callable.call({
          'fcmToken': fcmToken.trim(),
          'title': title.trim(),
          'message': message.trim(),
          'userId': userId,
        });

        // Log response details
        debugPrint('========================================');
        debugPrint('FCM Cloud Function Response Received');
        debugPrint('Response Data: ${result.data}');
        debugPrint('========================================');

        // Parse response
        final responseData = result.data as Map<String, dynamic>?;
        final success = responseData?['success'] ?? false;
        final resultMessage = responseData?['message'] ?? 'Unknown response';
        final messageId = responseData?['messageId'];

        if (success) {
          final successMessage = 'Notification sent successfully via Cloud Function. Message ID: $messageId';
          debugPrint('SUCCESS: $successMessage');
          debugPrint('========================================');
          return FCMNotificationResult(
            success: true,
            message: successMessage,
            timestamp: timestamp,
            responseData: responseData,
          );
        } else {
          final errorMessage = responseData?['error'] ?? resultMessage;
          debugPrint('ERROR: $errorMessage');
          debugPrint('========================================');
          return FCMNotificationResult(
            success: false,
            message: 'Failed to send notification: $errorMessage',
            timestamp: timestamp,
            responseData: responseData,
            errorDetails: errorMessage,
          );
        }
      } on FirebaseFunctionsException catch (e, stackTrace) {
        // Handle Firebase Functions specific errors
        final errorCode = e.code;
        final errorMessage = e.message ?? 'Unknown Firebase Functions error';
        final errorDetails = e.details?.toString() ?? '';

        debugPrint('========================================');
        debugPrint('Firebase Functions Exception');
        debugPrint('Error Code: $errorCode');
        debugPrint('Error Message: $errorMessage');
        debugPrint('Error Details: $errorDetails');
        debugPrint('Attempt: ${attempt + 1} of ${_maxRetries + 1}');
        debugPrint('Stack Trace: $stackTrace');
        debugPrint('========================================');

        // Check if error is retryable (transient errors)
        // Don't retry on 'internal' errors - they usually mean function doesn't exist
        final isRetryable = _isRetryableError(errorCode) && 
                           errorCode.toLowerCase() != 'internal';
        
        if (isRetryable && attempt < _maxRetries) {
          attempt++;
          continue; // Retry
        }
        
        // For 'internal' errors, don't retry - function likely doesn't exist
        if (errorCode.toLowerCase() == 'internal' && errorMessage == 'internal') {
          debugPrint('Detected function not deployed error - stopping retries');
        }

        // Non-retryable error or max retries reached
        final helpfulMessage = _getHelpfulErrorMessage(errorCode, errorMessage);
        
        debugPrint('========================================');
        debugPrint('FINAL ERROR - Not retrying');
        debugPrint('Error Code: $errorCode');
        debugPrint('Helpful Message: $helpfulMessage');
        debugPrint('========================================');
        
        return FCMNotificationResult(
          success: false,
          message: helpfulMessage,
          timestamp: timestamp,
          errorDetails: 'Code: $errorCode, Message: $errorMessage, Details: $errorDetails',
        );
      } on Exception catch (e, stackTrace) {
        // Handle other exceptions (timeout, network, etc.)
        final errorMessage = e.toString();
        debugPrint('========================================');
        debugPrint('Exception while calling Cloud Function');
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
        debugPrint('Unexpected error while calling Cloud Function');
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

  /// Check if Cloud Function is deployed and accessible
  /// Returns true if function is accessible, false otherwise
  static Future<bool> checkFunctionDeployment() async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: _cloudFunctionRegion);
      final testCallable = functions.httpsCallable(
        'sendNotification',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 10),
        ),
      );
      
      // Try calling with minimal data to test if function exists
      await testCallable.call({
        'fcmToken': 'test',
        'title': 'test',
        'message': 'test',
        'userId': 'test',
      });
      return true;
    } catch (e) {
      // If we get invalid-argument, function exists but validation failed (expected)
      // If we get not-found or unavailable, function doesn't exist
      if (e is FirebaseFunctionsException) {
        final code = e.code.toLowerCase();
        if (code == 'invalid-argument') {
          return true; // Function exists, just validation failed (expected)
        }
      }
      debugPrint('Function deployment check failed: $e');
      return false;
    }
  }

  /// Get helpful error message based on error code
  static String _getHelpfulErrorMessage(String errorCode, String errorMessage) {
    if (errorCode == 'internal' && errorMessage == 'internal') {
      return '''Cloud Function is not deployed or not accessible.

SOLUTION: Deploy the Cloud Function first:
1. Open terminal in your project root
2. Run: cd functions && npm install && cd ..
3. Run: firebase deploy --only functions
4. Wait 2-3 minutes for deployment to complete
5. Verify in Firebase Console → Functions

The function "sendNotification" must be deployed to region "us-central1" in project "mahsolek-8417b".

See DEPLOYMENT_GUIDE.md for detailed instructions.''';
    }
    
    if (errorCode == 'not-found' || errorCode == 'unavailable') {
      return '''Cloud Function not found or unavailable.

The function "sendNotification" may not be deployed or may be in a different region.

Please verify:
1. Function is deployed: firebase functions:list
2. Function is in region: us-central1
3. Function name is: sendNotification
4. Project is: mahsolek-8417b''';
    }
    
    return errorMessage;
  }

  /// Check if a Firebase Functions error code is retryable
  static bool _isRetryableError(String errorCode) {
    // Retryable error codes (transient errors)
    // Note: 'internal' is NOT retryable if it means function doesn't exist
    const retryableCodes = [
      'unavailable',        // Service unavailable
      'deadline-exceeded',  // Request timeout
      'resource-exhausted', // Rate limit or quota exceeded
    ];
    
    return retryableCodes.contains(errorCode.toLowerCase());
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
}

