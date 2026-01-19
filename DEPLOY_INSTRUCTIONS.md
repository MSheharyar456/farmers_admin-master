# Deploy Firebase Cloud Function for FCM Notifications

## Step-by-Step Deployment Instructions

### Prerequisites
1. Install Node.js (version 18 or higher)
2. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```
3. Login to Firebase:
   ```bash
   firebase login
   ```

### Deployment Steps

1. **Navigate to functions directory:**
   ```bash
   cd functions
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```
   This will install `firebase-admin` and `firebase-functions` packages.

3. **Deploy the function:**
   ```bash
   cd ..
   firebase deploy --only functions
   ```

   Or deploy only the `sendNotification` function:
   ```bash
   firebase deploy --only functions:sendNotification
   ```

4. **Wait for deployment to complete** - This may take a few minutes.

5. **Verify deployment:**
   - Go to Firebase Console: https://console.firebase.google.com/
   - Select your project: `mahsolek-8417b`
   - Navigate to: Functions
   - You should see `sendNotification` function listed

### Testing After Deployment

After deployment, test sending a notification from your admin app. The function should work and send notifications to users.

### Troubleshooting

If you get errors during deployment:

1. **Make sure you're logged in:**
   ```bash
   firebase login
   ```

2. **Check Firebase project:**
   ```bash
   firebase projects:list
   ```
   Make sure `mahsolek-8417b` is in the list.

3. **Set the active project:**
   ```bash
   firebase use mahsolek-8417b
   ```

4. **Check functions directory:**
   - Make sure `functions/index.js` exists
   - Make sure `functions/package.json` exists

5. **Enable Cloud Functions API:**
   - Go to: https://console.cloud.google.com/apis/library/cloudfunctions.googleapis.com
   - Select project: `mahsolek-8417b`
   - Click "Enable"

6. **Enable Cloud Build API:**
   - Go to: https://console.cloud.google.com/apis/library/cloudbuild.googleapis.com
   - Select project: `mahsolek-8417b`
   - Click "Enable"

### Required Firebase Plans

Cloud Functions requires the **Blaze Plan** (pay-as-you-go):
- Go to Firebase Console > Project Settings > Usage and Billing
- Upgrade to Blaze plan if needed
- Note: There's a generous free tier, so you likely won't be charged for normal usage

### After Successful Deployment

Once the function is deployed, your Flutter app will automatically use it when you send notifications. The function handles:
- ✅ OAuth 2.0 authentication automatically
- ✅ FCM V1 API calls
- ✅ Error handling
- ✅ Response formatting

Your notifications should now work correctly!



