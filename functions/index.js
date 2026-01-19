const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin with error handling
try {
  admin.initializeApp();
  console.log('Firebase Admin initialized successfully');
} catch (error) {
  console.error('Error initializing Firebase Admin:', error);
  // If already initialized, that's okay
  if (error.code !== 'app/already-initialized') {
    throw error;
  }
}

/**
 * Cloud Function to send FCM push notifications
 * This function handles OAuth 2.0 authentication automatically
 * 
 * Call from Flutter app:
 * final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('sendNotification');
 * final result = await callable.call({
 *   'fcmToken': 'user_fcm_token',
 *   'title': 'Notification Title',
 *   'message': 'Notification Message',
 *   'userId': 'user_id',
 * });
 */
exports.sendNotification = functions.region('us-central1').https.onCall({
  // Explicitly allow unauthenticated invocations for web access
  // This is required for web apps to call the function
}, async (data, context) => {
  // Wrap everything in try-catch to catch any initialization errors
  const startTime = Date.now();
  
  try {
    // Log function invocation with full details
    console.log('========================================');
    console.log('sendNotification function called');
    console.log('Timestamp:', new Date().toISOString());
    console.log('Has Data:', !!data);
    console.log('Has Context:', !!context);
    console.log('Context Auth:', context?.auth ? 'Authenticated' : 'Unauthenticated');
    console.log('Data Type:', typeof data);
    if (data) {
      console.log('Raw Data Keys:', Object.keys(data));
      // Don't log full data to avoid sensitive info in logs
    }
    console.log('========================================');
  } catch (logError) {
    console.error('Error in initial logging:', logError);
  }

  try {
    // Validate input data exists
    if (!data || typeof data !== 'object') {
      console.error('Invalid data received:', data);
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Request data is missing or invalid'
      );
    }

    const { fcmToken, title, message, userId } = data;

    // Validate required fields
    if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
      console.error('Missing or invalid fcmToken');
      throw new functions.https.HttpsError(
        'invalid-argument',
        'fcmToken is required and must be a non-empty string'
      );
    }

    if (!title || typeof title !== 'string' || title.trim().length === 0) {
      console.error('Missing or invalid title');
      throw new functions.https.HttpsError(
        'invalid-argument',
        'title is required and must be a non-empty string'
      );
    }

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      console.error('Missing or invalid message');
      throw new functions.https.HttpsError(
        'invalid-argument',
        'message is required and must be a non-empty string'
      );
    }

    // Log validated input (without sensitive token data)
    console.log('Validated input:', {
      userId: userId || 'not provided',
      title: title.substring(0, 50),
      message: message.substring(0, 50),
      fcmTokenLength: fcmToken.length,
    });

    // Prepare FCM message
    const messagePayload = {
      notification: {
        title: title.trim(),
        body: message.trim(),
      },
      data: {
        type: 'admin_notification',
        userId: userId || '',
        title: title.trim(),
        message: message.trim(),
        timestamp: Date.now().toString(),
      },
      token: fcmToken.trim(),
      android: {
        priority: 'high',
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Send notification using Firebase Admin SDK (automatically handles OAuth 2.0)
    console.log('Sending FCM notification...');
    const response = await admin.messaging().send(messagePayload);

    console.log('Successfully sent notification:', {
      messageId: response,
      timestamp: new Date().toISOString(),
    });

    const duration = Date.now() - startTime;
    console.log('Function completed successfully in', duration, 'ms');
    
    return {
      success: true,
      message: 'Notification sent successfully',
      messageId: response,
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    
    // Log full error details
    console.error('========================================');
    console.error('Error in sendNotification function');
    console.error('Duration:', duration, 'ms');
    console.error('Error Message:', error.message);
    console.error('Error Code:', error.code);
    console.error('Error Name:', error.name);
    console.error('Error Stack:', error.stack);
    console.error('Timestamp:', new Date().toISOString());
    console.error('========================================');

    // If it's already an HttpsError, rethrow it with duration info
    if (error instanceof functions.https.HttpsError) {
      console.error('HttpsError rethrown:', {
        code: error.code,
        message: error.message,
        details: error.details,
      });
      throw error;
    }

    // Handle FCM-specific errors
    if (error.code === 'messaging/invalid-registration-token' || 
        error.code === 'messaging/registration-token-not-registered') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid FCM token: ${error.message}`
      );
    }

    // Handle other FCM errors
    if (error.code && error.code.startsWith('messaging/')) {
      throw new functions.https.HttpsError(
        'internal',
        `FCM error: ${error.message || 'Unknown FCM error'}`
      );
    }

    // Generic error handling - ensure we always throw an HttpsError
    const errorMessage = error.message || 'Unknown error occurred';
    const errorCode = error.code || 'unknown';
    
    throw new functions.https.HttpsError(
      'internal',
      `Failed to send notification: ${errorMessage} (Code: ${errorCode})`
    );
  }
});

