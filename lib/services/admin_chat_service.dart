import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/chat_model.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/utils/chat_encryption.dart';

const _tokenKey = 'farmers_admin_auth_token';

class AdminChatService {
  final AdminServerAuthService _authService;

  AdminChatService(this._authService);

  static const _connectTimeout = Duration(seconds: 30);
  static const _receiveTimeout = Duration(seconds: 30);

  Dio get _dio {
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
      ),
    );
    final token = _authService.authToken;
    if (token != null && token.isNotEmpty) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['X-Authorization'] = 'Bearer $token';
            return handler.next(options);
          },
        ),
      );
    }
    return dio;
  }

  Future<String?> _getToken() async {
    var token = _authService.authToken;
    if (token != null && token.isNotEmpty) {
      return token;
    }
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    return token;
  }

  /// Get list of contacts for a target user, and decrypt the last message of each contact.
  Future<List<AdminChatUser>> getUserChats(String targetUserId) async {
    debugPrint('[AdminChatService] Fetching chats for user: $targetUserId');
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/users/$targetUserId/chats',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Authorization': 'Bearer $token',
          },
        ),
      );
      
      final data = res.data;
      if (data == null || data['success'] != true) return [];
      
      final list = data['contacts'] as List<dynamic>? ?? [];
      
      return list.map((e) {
        final json = e as Map<String, dynamic>;
        final encLastMsg = json['lastMessage']?.toString();
        final contactId = json['id']?.toString() ?? '';
        
        String? decryptedLastMsg;
        if (encLastMsg != null && encLastMsg.isNotEmpty) {
          decryptedLastMsg = ChatEncryption.decrypt(encLastMsg, targetUserId, contactId) ?? '[Decryption failed]';
        }
        
        return AdminChatUser.fromJson({
          ...json,
          'lastMessage': decryptedLastMsg,
        });
      }).toList();
    } on DioException catch (e) {
      debugPrint('[AdminChatService] DioError: ${e.message}');
      throw Exception('Failed to load user chats: ${e.message}');
    } catch (e) {
      debugPrint('[AdminChatService] Unexpected error: $e');
      throw Exception('Error loading user chats: $e');
    }
  }

  /// Get message history between target user and their contact, decrypting all messages.
  Future<List<AdminChatMessage>> getMessages(String userId, String contactId) async {
    debugPrint('[AdminChatService] Fetching messages between $userId and $contactId');
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/admin/users/$userId/messages/$contactId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Authorization': 'Bearer $token',
          },
        ),
      );
      
      final data = res.data;
      if (data == null || data['success'] != true) return [];
      
      final list = data['messages'] as List<dynamic>? ?? [];
      
      return list.map((e) {
        final json = e as Map<String, dynamic>;
        final encMsg = json['encryptedMessage']?.toString() ?? json['encrypted_message']?.toString() ?? '';
        final senderId = json['senderId']?.toString() ?? json['sender_id']?.toString() ?? '';
        final receiverId = json['receiverId']?.toString() ?? json['receiver_id']?.toString() ?? '';
        final id = json['id']?.toString() ?? '';
        final isRead = json['isRead'] == true || json['is_read'] == 1 || json['is_read'] == true;
        final createdAt = json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now()
            : json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
                : DateTime.now();

        String decryptedMsg = '';
        if (encMsg.isNotEmpty) {
          decryptedMsg = ChatEncryption.decrypt(encMsg, userId, contactId) ?? '[Decryption failed]';
        }

        return AdminChatMessage(
          id: id,
          senderId: senderId,
          receiverId: receiverId,
          message: decryptedMsg,
          isRead: isRead,
          createdAt: createdAt,
        );
      }).toList();
    } on DioException catch (e) {
      debugPrint('[AdminChatService] DioError: ${e.message}');
      throw Exception('Failed to load messages: ${e.message}');
    } catch (e) {
      debugPrint('[AdminChatService] Unexpected error: $e');
      throw Exception('Error loading messages: $e');
    }
  }
}
