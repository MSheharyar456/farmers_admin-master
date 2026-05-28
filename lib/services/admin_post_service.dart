import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/post_model.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

/// Fetches and updates posts via the backend API using the admin JWT.
class AdminPostService {
  AdminPostService(this._authService);

  final AdminServerAuthService _authService;

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

  /// GET /posts with optional limit, offset, category, approved.
  /// [approved]: 1 = approved only (default for post management), 0 = pending only (for dashboard). Requires admin auth.
  /// [sold]: 1 = sold posts only (for admin sold posts screen). Requires admin auth.
  /// [bypassCache]: Adds timestamp and no-cache headers to get fresh data (e.g. after approval).
  Future<List<Map<String, dynamic>>> getPosts({
    int? limit,
    int? offset,
    String? category,
    int? approved,
    int? sold,
    bool bypassCache = false,
  }) async {
    final query = <String, dynamic>{};
    if (limit != null) query['limit'] = limit;
    if (offset != null) query['offset'] = offset;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (approved != null) query['approved'] = approved.toString();
    if (sold != null) query['sold'] = sold.toString();
    // Cache-busting: add timestamp to query params
    if (bypassCache) {
      query['_'] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    final res = await _dio.get<List<dynamic>>(
      '/posts',
      queryParameters: query.isEmpty ? null : query,
      options: bypassCache
          ? Options(
              headers: {
                'Cache-Control': 'no-cache, no-store, must-revalidate',
                'Pragma': 'no-cache',
                'Expires': '0',
              },
            )
          : null,
    );
    final list = res.data;
    if (list == null) return [];
    return list
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  /// GET /posts/:postId. Returns the post object from response.post, or null.
  Future<Map<String, dynamic>?> getPostById(String postId) async {
    final res = await _dio.get<Map<String, dynamic>>('/posts/$postId');
    final data = res.data;
    if (data == null) return null;
    final post = data['post'];
    if (post == null) return null;
    return Map<String, dynamic>.from(post as Map<dynamic, dynamic>);
  }

  /// PATCH /posts/:postId with partial updates. Requires admin JWT.
  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    // DEBUG: request (uses PUT for compatibility with proxies/servers that block PATCH)
    debugPrint('[AdminPostService.updatePost] DEBUG REQUEST (PUT /posts/admin/:id)');
    debugPrint('  postId: $postId');
    debugPrint('  payload: $updates');
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/posts/admin/$postId',
        data: updates,
      );
      // DEBUG: success response
      debugPrint('[AdminPostService.updatePost] DEBUG RESPONSE (success)');
      debugPrint('  statusCode: ${res.statusCode}');
      debugPrint('  data: ${res.data}');
    } on DioException catch (e) {
      // DEBUG: error response
      debugPrint('[AdminPostService.updatePost] DEBUG RESPONSE (error)');
      debugPrint('  type: ${e.type}');
      debugPrint('  message: ${e.message}');
      debugPrint('  statusCode: ${e.response?.statusCode}');
      debugPrint('  response.data: ${e.response?.data}');
      rethrow;
    }
  }

  /// DELETE /posts/:postId. Requires admin JWT.
  Future<void> deletePost(String postId) async {
    await _dio.delete<Map<String, dynamic>>('/posts/admin/$postId');
  }

  /// Build Post list from server rows with full image URLs.
  List<Post> postsFromRows(List<Map<String, dynamic>> rows) {
    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl : apiBaseUrl;
    return rows
        .map((row) => Post.fromServerRow(row, baseUrl: base))
        .toList();
  }
}
