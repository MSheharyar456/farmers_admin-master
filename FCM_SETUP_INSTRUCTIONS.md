# FCM V1 API Setup Instructions

Since the Legacy FCM API is disabled in your Firebase Console, you need to use the FCM V1 API which requires OAuth 2.0 authentication.

## Option 1: Use Firebase Cloud Functions (Recommended)

The easiest and most secure way to send FCM notifications is to use Firebase Cloud Functions. This way, you don't need to handle OAuth 2.0 or service account credentials in your Flutter app.

### Setup Cloud Functions:

1. Install Firebase CLI (if not installed):
   ```bash
   npm install -g firebase-tools
   ```

2. Initialize Cloud Functions in your project:
   ```bash
   cd functions
   npm install
   ```

3. Create a Cloud Function to send notifications (`functions/index.js`):
   ```javascript
   const functions = require('firebase-functions');
   const admin = require('firebase-admin');
   
   admin.initializeApp();
   
   exports.sendNotification = functions.https.onCall(async (data, context) => {
     const { fcmToken, title, message, userId } = data;
     
     const message = {
       notification: {
         title: title,
         body: message,
       },
       data: {
         type: 'admin_notification',
         userId: userId,
       },
       token: fcmToken,
     };
     
     try {
       const response = await admin.messaging().send(message);
       return { success: true, messageId: response };
     } catch (error) {
       return { success: false, error: error.message };
     }
   });
   ```

4. Deploy the function:
   ```bash
   firebase deploy --only functions
   ```

5. Update your Flutter code to call the Cloud Function instead of direct FCM API calls.

## Option 2: Configure Service Account in Flutter App

If you want to send notifications directly from the Flutter app:

1. **Get Service Account Credentials:**
   - Go to Firebase Console: https://console.firebase.google.com/
   - Select your project (`mahsolek-8417b`)
   - Go to Project Settings > Service Accounts
   - Click "Generate new private key"
   - Download the JSON file

2. **Extract Credentials:**
   - Open the downloaded JSON file
   - Copy the `client_email` value
   - Copy the `private_key` value (keep the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines)

3. **Update `fcm_notification_service.dart`:**
   - Open `lib/services/fcm_notification_service.dart`
   - Find `_serviceAccountEmail` and replace with your `client_email`
   - Find `_serviceAccountPrivateKey` and replace with your `private_key`

4. **Install RSA Signing Package:**
   - The current implementation requires proper RSA signing
   - You may need to install `pointycastle` package (already added to pubspec.yaml)
   - Or use `googleapis` and `googleapis_auth` packages for proper OAuth 2.0

## Option 3: Use Firebase Admin SDK (Server-Side)

If you have a backend server (Node.js, Python, etc.), use Firebase Admin SDK which handles OAuth automatically.

## Recommended Solution

**Use Firebase Cloud Functions (Option 1)** - This is the most secure and recommended approach because:
- No credentials stored in client app
- Automatic OAuth handling
- Better security
- Easier to maintain

## Current Status

The FCM service has been updated for V1 API structure, but RSA signing implementation is incomplete. For production use, implement one of the options above.



