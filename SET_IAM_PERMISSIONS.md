# CRITICAL: Set IAM Permissions - This Will Fix Your Issue

## The Problem
Your function is deployed but web app can't access it because it doesn't allow unauthenticated invocations.

## THE FIX (Do This Now - Takes 2 Minutes)

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select project: **mahsolek-8417b**

### Step 2: Navigate to Functions
1. Click **Functions** in the left sidebar
2. You should see **sendNotification** function

### Step 3: Set Permissions
1. Click on **sendNotification** function name
2. Click on the **Permissions** tab (at the top)
3. Look for **"Add principal"** button and click it
4. In the **New principals** field, type: `allUsers`
5. In the **Select a role** dropdown, select: **Cloud Functions Invoker**
6. Click **Save**

### Step 4: Wait and Test
1. Wait 1-2 minutes for changes to propagate
2. Restart your Flutter app
3. Try sending a notification again

## Alternative: Using gcloud (If you have admin access)

If you have gcloud CLI installed and admin permissions:

```bash
gcloud functions add-iam-policy-binding sendNotification \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/cloudfunctions.invoker" \
  --project=mahsolek-8417b
```

## Verify It's Fixed

After setting permissions, check function logs:

```bash
firebase functions:log --only sendNotification --limit 5
```

You should now see logs when you call the function from your app.

## Why This Fixes It

Web apps need the function to allow **unauthenticated invocations**. By default, Cloud Functions require authentication. Setting `allUsers` as `Cloud Functions Invoker` allows your web app to call the function without requiring user authentication.

## Still Not Working?

If you've set permissions and it's still not working:

1. **Check function logs:**
   ```bash
   firebase functions:log --only sendNotification --follow
   ```
   Then try sending a notification and watch the logs.

2. **Verify in Console:**
   - Go to Functions → sendNotification → Permissions
   - You should see `allUsers` with role `Cloud Functions Invoker`

3. **Check browser console (F12):**
   - Look for CORS errors or network errors
   - Check if the request is being made

4. **Redeploy function:**
   ```bash
   firebase deploy --only functions:sendNotification
   ```

The function code is correct. The ONLY issue is IAM permissions. Set them in Firebase Console and it will work.



