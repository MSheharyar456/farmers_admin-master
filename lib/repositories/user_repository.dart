import 'package:dio/dio.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/user_model.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

/// Fetches and manages app users via the backend admin API.
class UserRepository {
  UserRepository(this._authService);

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
    print('[UserRepository] Creating Dio - token present: ${token != null && token.isNotEmpty}');
    if (token != null && token.isNotEmpty) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['X-Authorization'] = 'Bearer $token';
            print('[UserRepository] Added auth headers to request: ${options.path}');
            return handler.next(options);
          },
        ),
      );
    } else {
      print('[UserRepository] WARNING: No token available!');
    }
    return dio;
  }

  /// GET /admin/users. Returns list of users. Optional limit, offset, search.
  Future<List<UserModel>> getUsers({
    int? limit,
    int? offset,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (limit != null) query['limit'] = limit;
    if (offset != null) query['offset'] = offset;
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = res.data;
    if (data == null || data['success'] != true) return [];
    final list = data['users'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => UserModel.fromServerRow(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }

  /// DELETE /admin/users/:id (soft delete).
  Future<void> deleteUser(String id) async {
    await _dio.delete<Map<String, dynamic>>('/admin/users/$id');
  }

  /// POST /admin/users (create user/admin account).
  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/users',
      data: data,
    );
    final responseData = res.data;
    if (responseData == null || responseData['success'] != true) {
      throw Exception(responseData?['message'] ?? 'Failed to create user');
    }
    final userMap = responseData['user'];
    if (userMap is Map) {
      return UserModel.fromServerRow(Map<String, dynamic>.from(userMap as Map<dynamic, dynamic>));
    }
    throw Exception('User was created but response was invalid');
  }

  /// POST /admin/users/create-user (same create flow if backend response is shaped as raw row)

  /// POST /admin/users/bulk-delete (bulk hard delete).
  Future<Map<String, dynamic>> bulkDeleteUsers(List<String> userIds) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/users/bulk-delete',
      data: {'userIds': userIds},
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Bulk deletion failed');
    }
    return data;
  }

  /// GET /admin/deletion-status (deletion queue status).
  Future<Map<String, dynamic>> getDeletionStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('/admin/deletion-status');
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Failed to get deletion status');
    }
    return data;
  }

  /// POST /admin/deletion/pause (pause deletion queue).
  Future<void> pauseDeletionQueue() async {
    await _dio.post<Map<String, dynamic>>('/admin/deletion/pause');
  }

  /// POST /admin/deletion/resume (resume deletion queue).
  Future<void> resumeDeletionQueue() async {
    await _dio.post<Map<String, dynamic>>('/admin/deletion/resume');
  }

  /// PATCH /admin/users/:id (update user fields including post limits).
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/admin/users/$id',
      data: data,
    );
    final responseData = res.data;
    if (responseData == null || responseData['success'] != true) {
      throw Exception(responseData?['message'] ?? 'Failed to update user');
    }
  }

  /// GET /admin/users/:id - fetch a single user by id.
  Future<Map<String, dynamic>?> getUserById(String id) async {
    try {
      print('[UserRepository] Fetching user by id: $id');
      final res = await _dio.get<Map<String, dynamic>>('/admin/users/$id');
      final data = res.data;
      print('[UserRepository] Response status: ${res.statusCode}');
      print('[UserRepository] Response data keys: ${data?.keys.toList()}');
      if (data == null) return null;
      // Backend may return { success: true, user: {...} } or raw user object
      if (data.containsKey('user')) {
        final user = data['user'];
        if (user is Map) return Map<String, dynamic>.from(user as Map<dynamic, dynamic>);
      }
      // If response is a raw user map
      return Map<String, dynamic>.from(data);
    } catch (e) {
      print('[UserRepository] Error fetching user by id: $e');
      if (e is DioException) {
        print('[UserRepository] DioException statusCode: ${e.response?.statusCode}');
        print('[UserRepository] DioException message: ${e.message}');
        print('[UserRepository] DioException response: ${e.response?.data}');
      }
      return null;
    }
  }

  /// GET /users/:id/posts — fetch user's posts to calculate edit usage.
  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final res = await _dio.get<dynamic>('/users/$userId/posts');
      final raw = res.data;
      if (raw is List) {
        return raw.map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>)).toList();
      } else if (raw is Map && raw['success'] == true) {
        final posts = raw['posts'] ?? raw['data'] ?? [];
        if (posts is List) {
          return posts.map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching user posts: $e');
      return [];
    }
  }
}
