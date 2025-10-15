// functions/index.js
// Replace ALL content in this file with this code

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Function to create user with specific status
exports.createUserWithStatus = functions.https.onCall(async (data, context) => {
  // Check if the request is made by an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to perform this action.'
    );
  }

  // OPTIONAL: Check if user is admin (uncomment after setting up admin claims)
  // if (!context.auth.token.admin) {
  //   throw new functions.https.HttpsError(
  //     'permission-denied',
  //     'Only admins can create users.'
  //   );
  // }

  const { email, password, displayName, disabled } = data;

  // Validate input
  if (!email || !password) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email and password are required.'
    );
  }

  try {
    // Create user in Firebase Authentication with disabled status
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: displayName || '',
      disabled: disabled || false  // This actually disables/enables the account
    });

    console.log('Successfully created user:', userRecord.uid);

    return {
      success: true,
      message: 'User created successfully.',
      userId: userRecord.uid,
      email: userRecord.email,
      disabled: userRecord.disabled
    };
  } catch (error) {
    console.error('Error creating user:', error);

    // Handle specific Firebase Auth errors
    if (error.code === 'auth/email-already-exists') {
      throw new functions.https.HttpsError(
        'already-exists',
        'This email is already registered.'
      );
    } else if (error.code === 'auth/invalid-email') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email address.'
      );
    } else if (error.code === 'auth/weak-password') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Password is too weak. Use at least 6 characters.'
      );
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to create user: ' + error.message
    );
  }
});

// Function to update user status (enable/disable)
exports.updateUserStatus = functions.https.onCall(async (data, context) => {
  // Check if the request is made by an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to perform this action.'
    );
  }

  // OPTIONAL: Check if user is admin (uncomment after setting up admin claims)
  // if (!context.auth.token.admin) {
  //   throw new functions.https.HttpsError(
  //     'permission-denied',
  //     'Only admins can update user status.'
  //   );
  // }

  const { userId, disabled } = data;

  // Validate input
  if (!userId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'User ID is required.'
    );
  }

  if (typeof disabled !== 'boolean') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Disabled must be a boolean value.'
    );
  }

  try {
    // Update user's disabled status in Firebase Authentication
    await admin.auth().updateUser(userId, {
      disabled: disabled
    });

    // Also update the status in Realtime Database for reference
    await admin.database().ref(`UsersAuthData/${userId}`).update({
      isAccountEnabled: !disabled,
      lastStatusUpdate: Date.now(),
      updatedBy: context.auth.uid
    });

    console.log(`User ${userId} status updated to: ${disabled ? 'disabled' : 'enabled'}`);

    return {
      success: true,
      message: `User account ${disabled ? 'disabled' : 'enabled'} successfully.`,
      userId: userId,
      disabled: disabled
    };
  } catch (error) {
    console.error('Error updating user status:', error);

    if (error.code === 'auth/user-not-found') {
      throw new functions.https.HttpsError(
        'not-found',
        'User not found.'
      );
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to update user status: ' + error.message
    );
  }
});

// OPTIONAL: Function to set admin claims
// Call this function once to make a user an admin
exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  // For security, you should add your own verification here
  // For now, only the first time setup or use Firebase Console

  const { userId } = data;

  if (!userId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'User ID is required.'
    );
  }

  try {
    await admin.auth().setCustomUserClaims(userId, { admin: true });

    return {
      success: true,
      message: `Admin privileges granted to user ${userId}`
    };
  } catch (error) {
    console.error('Error setting admin claim:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to set admin claim: ' + error.message
    );
  }
});