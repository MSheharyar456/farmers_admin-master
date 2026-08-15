import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// AES-256-CBC end-to-end encryption for chat messages.
/// The encryption key is deterministically derived from both user IDs,
/// so both parties produce the same key without any key exchange.
/// The server only stores the base64 ciphertext and never sees plain text.
class ChatEncryption {
  /// Normalize user IDs so UUID strings match across AppUser / JWT / DB.
  static String normalizeId(String id) => id.trim();

  /// Derive a 32-byte AES key from two user IDs (sorted so order doesn't matter).
  static enc.Key deriveKey(String userId1, String userId2) {
    final a = normalizeId(userId1);
    final b = normalizeId(userId2);
    if (a.isEmpty || b.isEmpty) {
      throw ArgumentError('deriveKey requires non-empty user ids');
    }
    final ids = [a, b]..sort();
    final combined = ids.join(':');
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  /// Encrypt [plainText] for a conversation between [myId] and [otherId].
  /// Returns a base64-encoded string containing IV + ciphertext.
  static String encrypt(String plainText, String myId, String otherId) {
    final key = deriveKey(normalizeId(myId), normalizeId(otherId));
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Prepend IV (base64) + ':' + ciphertext (base64)
    final ivB64 = base64.encode(iv.bytes);
    final ctB64 = encrypted.base64;
    return '$ivB64:$ctB64';
  }

  /// Decrypt a payload produced by [encrypt].
  /// Returns the original plain text, or null if decryption fails.
  static String? decrypt(String payload, String myId, String otherId) {
    try {
      final parts = payload.split(':');
      if (parts.length < 2) return payload; // Not encrypted (legacy)
      // IV could contain '=' padding — rejoin everything after the first ':'
      final ivB64 = parts[0];
      final ctB64 = parts.sublist(1).join(':');
      final ivBytes = base64.decode(ivB64);
      final key = deriveKey(normalizeId(myId), normalizeId(otherId));
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt64(ctB64, iv: iv);
      return decrypted;
    } catch (_) {
      return null; // Decryption failed — key mismatch or corrupt data
    }
  }
}
