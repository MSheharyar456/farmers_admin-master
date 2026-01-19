import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';


/// Service to handle all authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Hash the passkey using SHA-256
  String _hashPasskey(String passkey) {
    final bytes = utf8.encode(passkey);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Sign up new admin user
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String passkey,
  }) async {
    try {
      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Hash the passkey before storing
      final hashedPasskey = _hashPasskey(passkey.trim());

      // Store hashed passkey in database
      await _dbRef
          .child("adminPasskey")
          .child(userCredential.user!.uid)
          .set({
        "email": email.trim(),
        "passkeyHash": hashedPasskey,
        "createdAt": DateTime.now().toIso8601String(),
      });

      // Sign out immediately after signup
      await _auth.signOut();

      return AuthResult.success(
        message: 'Account created successfully! Please log in.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Login admin user
  Future<AuthResult> login({
    required String email,
    required String password,
    required String passkey,
  }) async {
    try {
      // Sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Verify passkey
      final isPasskeyValid = await _verifyPasskey(
        uid: userCredential.user!.uid,
        passkey: passkey.trim(),
      );

      if (!isPasskeyValid) {
        await _auth.signOut();
        return AuthResult.failure(
          message: 'Invalid passkey. Please try again.',
        );
      }

      return AuthResult.success(
        message: 'Login successful!',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Verify passkey by comparing hashes
  Future<bool> _verifyPasskey({
    required String uid,
    required String passkey,
  }) async {
    try {
      final snapshot = await _dbRef.child("adminPasskey").child(uid).get();

      if (!snapshot.exists) {
        return false;
      }

      final storedHash = snapshot.child("passkeyHash").value as String?;
      if (storedHash == null) {
        return false;
      }

      final inputHash = _hashPasskey(passkey);
      return storedHash == inputHash;
    } catch (e) {
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user-friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Result class for auth operations
class AuthResult {
  final bool isSuccess;
  final String message;

  AuthResult._({required this.isSuccess, required this.message});

  factory AuthResult.success({required String message}) {
    return AuthResult._(isSuccess: true, message: message);
  }

  factory AuthResult.failure({required String message}) {
    return AuthResult._(isSuccess: false, message: message);
  }
}