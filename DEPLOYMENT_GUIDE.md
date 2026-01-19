# Cloud Function Deployment Guide

## Problem
If you're getting `[internal] internal` errors when calling the Cloud Function, it usually means:
1. **The function is not deployed** (most common)
2. The function is deployed but crashing at runtime
3. There's a configuration mismatch

## Solution: Deploy the Cloud Function

### Step 1: Install Dependencies
```bash
cd functions
npm install
cd ..
```

### Step 2: Deploy the Function
```bash
firebase deploy --only functions
```

This will deploy both:
- `sendNotification` - Main function for sending FCM notifications
- `testFunction` - Test function to verify deployment

### Step 3: Verify Deployment

#### Option A: Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `mahsolek-8417b`
3. Navigate to **Functions** in the left menu
4. You should see:
   - `sendNotification` (us-central1)
   - `testFunction` (us-central1)

#### Option B: Firebase CLI
```bash
firebase functions:list
```

### Step 4: Test the Function

#### Test with testFunction (Recommended first)
You can test if functions are working by calling the test function from your Flutter app:

```dart
final testCallable = FirebaseFunctions.instanceFor(region: 'us-central1')
    .httpsCallable('testFunction');
final result = await testCallable.call();
print('Test result: ${result.data}');
```

#### Check Function Logs
```bash
# View all function logs
firebase functions:log

# View logs for specific function
firebase functions:log --only sendNotification

# Follow logs in real-time
firebase functions:log --only sendNotification --follow
```

### Step 5: Common Issues and Solutions

#### Issue: "Function not found"
**Solution**: The function is not deployed. Run `firebase deploy --only functions`

#### Issue: "Permission denied"
**Solution**: 
1. Make sure you're logged in: `firebase login`
2. Make sure you're using the correct project: `firebase use mahsolek-8417b`

#### Issue: "Internal error" after deployment
**Solution**:
1. Check function logs: `firebase functions:log --only sendNotification`
2. Look for error messages in the logs
3. Common causes:
   - Firebase Admin SDK not initialized properly
   - Missing permissions for FCM
   - Invalid FCM token

#### Issue: Function deployed but still getting errors
**Solution**:
1. Wait 1-2 minutes after deployment (functions need time to propagate)
2. Clear your browser cache if testing on web
3. Restart your Flutter app
4. Check that you're using the correct region (`us-central1`)

### Step 6: Verify Function is Working

After deployment, try sending a notification from your Flutter app. The logs should now show:
- Detailed function invocation logs
- Input validation logs
- FCM sending logs
- Success/error messages with details

## Quick Deployment Checklist

- [ ] Navigate to project root directory
- [ ] Run `cd functions && npm install && cd ..`
- [ ] Run `firebase deploy --only functions`
- [ ] Wait for deployment to complete (2-5 minutes)
- [ ] Verify in Firebase Console that functions are listed
- [ ] Check function logs for any errors
- [ ] Test with testFunction first
- [ ] Test with sendNotification

## Important Notes

1. **Region**: The function is deployed to `us-central1`. Make sure your Flutter app uses the same region.

2. **Project**: The function is deployed to project `mahsolek-8417b`. Make sure your Firebase configuration matches.

3. **Deployment Time**: First deployment can take 5-10 minutes. Subsequent deployments are faster (1-3 minutes).

4. **Logs**: Always check function logs if you encounter errors. They contain detailed information about what went wrong.

## Need Help?

If you're still getting errors after deployment:
1. Check the function logs: `firebase functions:log --only sendNotification`
2. Look for specific error messages
3. Verify the function appears in Firebase Console
4. Make sure you're using the correct project and region



