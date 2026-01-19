# ⚠️ CRITICAL: Set IAM Permissions - This WILL Fix Your Issue

## ✅ What I Found
- Function IS deployed ✅
- Function code is correct ✅
- Function is NOT being called (no invocation logs) ❌
- **IAM permissions are NOT set** ❌

## 🔧 THE FIX (Do This Now - 2 Minutes)

### Step 1: Open Google Cloud Console
1. Go to: **https://console.cloud.google.com/**
2. Make sure you're logged in with: **mshehar5@gmail.com**
3. Select project: **mahsolek-8417b** (top dropdown)

### Step 2: Navigate to Cloud Functions
1. In the left menu, click **"Cloud Functions"** (or search for it)
2. You should see **sendNotification** function
3. Click on **sendNotification** function name

### Step 3: Set Permissions
1. Click on the **"PERMISSIONS"** tab (at the top)
2. Click **"GRANT ACCESS"** button (or "ADD PRINCIPAL")
3. In **"New principals"** field, type exactly: `allUsers`
4. In **"Select a role"** dropdown, select: **"Cloud Functions Invoker"**
5. Click **"SAVE"**

### Step 4: Wait and Test
1. Wait **1-2 minutes** for changes to propagate
2. **Restart your Flutter app** (stop and start again)
3. Try sending a notification

## 🎯 Why This Fixes It

Your function logs show:
- Function is deployed ✅
- But NO function invocations (function is never called) ❌

This means the web app **cannot access the function** because IAM permissions block it. Setting `allUsers` as `Cloud Functions Invoker` allows your web app to call the function.

## ✅ Verify It's Fixed

After setting permissions, check logs:

```bash
firebase functions:log --only sendNotification
```

Then try sending a notification. You should now see logs like:
```
sendNotification function called
Timestamp: ...
Has Data: true
```

## 📸 Visual Guide

If you can't find it:
1. Google Cloud Console → Cloud Functions → sendNotification
2. Click **PERMISSIONS** tab
3. Click **GRANT ACCESS**
4. Add: `allUsers` with role `Cloud Functions Invoker`
5. Save

## ⚠️ Important Notes

- You **CANNOT** set this via CLI (you don't have permission)
- You **MUST** use Google Cloud Console
- The function code is correct - this is ONLY a permissions issue
- After setting permissions, wait 1-2 minutes before testing

## 🚨 Still Not Working?

If you've set permissions and it's still not working:

1. **Double-check permissions:**
   - Go to Cloud Functions → sendNotification → Permissions
   - You should see `allUsers` with role `Cloud Functions Invoker`

2. **Check function logs again:**
   ```bash
   firebase functions:log --only sendNotification
   ```
   Try sending notification and watch for new logs

3. **Clear browser cache and restart app**

The function is deployed and ready. You just need to set the IAM permissions in Google Cloud Console.



