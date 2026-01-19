# FCM Service Setup Guide

## ⚠️ IMPORTANT: Configure Your Firebase Server Key

Before you can send notifications, you **MUST** configure your Firebase Server Key in the FCM service.

### Step 1: Get Your Firebase Server Key

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **mahsolek-8417b** (or your project name)
3. Click the **⚙️ Settings** icon → **Project settings**
4. Go to the **Cloud Messaging** tab
5. Scroll down to **Cloud Messaging API (Legacy)**
6. Copy the **Server key** (it starts with `AAAA...`)

### Step 2: Update the FCM Service

1. Open the file: `lib/services/fcm_service.dart`
2. Find line 23 where it says:
   ```dart
   static const String _serverKey = 'YOUR_FIREBASE_SERVER_KEY_HERE';
   ```
3. Replace `'YOUR_FIREBASE_SERVER_KEY_HERE'` with your actual server key:
   ```dart
   static const String _serverKey = 'AAAAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
   ```
4. Save the file

### Step 3: Test the Notifications

1. Run your Flutter app
2. Go to **Notify Users** → **Add Notification**
3. Select a user who has an FCM token
4. Enter a title and message
5. Click **Save Notification**
6. Check if the notification is received on the user's device

## What Changed?

### ✅ Benefits of the New Approach

- **No Cloud Functions needed** - No deployment required
- **Simpler setup** - Just add your server key
- **Direct HTTP API** - Faster and more straightforward
- **No OAuth complexity** - Server key authentication is simple

### 📝 How It Works

1. When you send a notification, the app makes a direct HTTP POST request to Firebase Cloud Messaging
2. The request includes:
   - Your Firebase Server Key (for authentication)
   - The user's FCM token (device identifier)
   - The notification title and message
3. Firebase delivers the notification to the user's device

### 🔒 Security Note

The Firebase Server Key is stored in your Flutter code. This is acceptable for **admin applications** with controlled access. For production apps accessible to end users, Cloud Functions would be more secure, but for your admin panel, this approach is perfectly fine.

## Troubleshooting

### Error: "Firebase Server Key not configured"
- Make sure you've replaced `'YOUR_FIREBASE_SERVER_KEY_HERE'` with your actual server key
- The server key should start with `AAAA`

### Error: "Invalid FCM token"
- The user doesn't have a valid FCM token
- Make sure the user has logged into the mobile app and granted notification permissions

### Notification not received
- Check the user's device notification settings
- Verify the FCM token is valid and not expired
- Check the Flutter console for error messages

## Need Help?

If you encounter any issues:
1. Check the Flutter console for debug logs (they start with `========================================`)
2. Verify your Firebase Server Key is correct
3. Make sure the user has a valid FCM token
