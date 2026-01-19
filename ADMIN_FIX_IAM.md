# 🔧 ADMIN FIX: Set IAM Permissions for sendNotification Function

## Current Status
- ✅ Function is deployed and active
- ✅ Function code is correct
- ❌ **IAM policy is EMPTY** (no one can call it)
- ❌ Web app cannot access function

## The Fix (For Admin/Owner)

### Option 1: Using Google Cloud Console (Easiest)

1. **Go to Google Cloud Console:**
   - URL: https://console.cloud.google.com/
   - Select project: **mahsolek-8417b**

2. **Navigate to Cloud Functions:**
   - In left menu, click **"Cloud Functions"**
   - Click on function: **sendNotification**

3. **Set Permissions:**
   - Click **"PERMISSIONS"** tab (at the top)
   - Click **"GRANT ACCESS"** button
   - In **"New principals"** field, type: `allUsers`
   - In **"Select a role"** dropdown, select: **"Cloud Functions Invoker"**
   - Click **"SAVE"**

### Option 2: Using gcloud CLI (For Admin)

Run this exact command:

```bash
gcloud functions add-iam-policy-binding sendNotification \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/cloudfunctions.invoker" \
  --project=mahsolek-8417b
```

### Option 3: Using Firebase Console

1. Go to: https://console.firebase.google.com/
2. Select project: **mahsolek-8417b**
3. Click **Functions** in left menu
4. Click on **sendNotification**
5. Look for **Permissions** or **Access** tab
6. Add: `allUsers` with role `Cloud Functions Invoker`

## Verify It's Fixed

After setting permissions, check:

```bash
gcloud functions get-iam-policy sendNotification --region=us-central1 --project=mahsolek-8417b
```

You should see:
```yaml
bindings:
- members:
  - allUsers
  role: roles/cloudfunctions.invoker
```

## Function Details

- **Function Name:** sendNotification
- **Region:** us-central1
- **Project:** mahsolek-8417b
- **Generation:** 1st Gen
- **Status:** ACTIVE
- **URL:** https://us-central1-mahsolek-8417b.cloudfunctions.net/sendNotification
- **Current IAM Policy:** EMPTY (needs `allUsers` with `Cloud Functions Invoker` role)

## Why This Is Needed

The function has `securityLevel: SECURE_ALWAYS`, which means it requires explicit IAM permissions to be invoked. Currently, the IAM policy is empty, so no one (including the web app) can call it.

Adding `allUsers` as `Cloud Functions Invoker` allows:
- ✅ Web apps to call the function
- ✅ Unauthenticated requests
- ✅ The Flutter app to send notifications

## After Fixing

1. Wait 1-2 minutes for changes to propagate
2. Test by sending a notification from the Flutter app
3. Check function logs to verify it's being called:
   ```bash
   firebase functions:log --only sendNotification
   ```

## Security Note

Making the function publicly accessible (`allUsers`) is safe because:
- The function validates all input
- It only sends notifications (doesn't expose sensitive data)
- It requires valid FCM tokens
- It's a callable function (not a public HTTP endpoint)

If you want to restrict access later, you can remove `allUsers` and add specific service accounts or authenticated users.



