import 'package:dio/dio.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/dashboard_model.dart';
import 'package:farmers_admin/models/users_feedback_model.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

/// Fetches dashboard stats and feedback via the backend admin API.
class AdminDashboardApiService {
  AdminDashboardApiService(this._authService);

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

  /// GET /admin/dashboard/stats
  Future<DashboardStats> getStats() async {
    final res = await _dio.get<Map<String, dynamic>>('/admin/dashboard/stats');
    final data = res.data;
    if (data == null || data['success'] != true) return DashboardStats.empty();
    final stats = data['stats'] as Map<String, dynamic>?;
    if (stats == null) return DashboardStats.empty();
    return DashboardStats(
      totalUsers: (stats['totalUsers'] as num?)?.toInt() ?? 0,
      pendingRequests: (stats['pendingRequests'] as num?)?.toInt() ?? 0,
      totalPosts: (stats['totalPosts'] as num?)?.toInt() ?? 0,
      approvedPosts: (stats['approvedPosts'] as num?)?.toInt() ?? 0,
      pendingPosts: (stats['pendingPosts'] as num?)?.toInt() ?? 0,
      cancelledPosts: (stats['cancelledPosts'] as num?)?.toInt() ?? 0,
      soldPosts: (stats['soldPosts'] as num?)?.toInt() ?? 0,
      totalFeedback: (stats['totalFeedback'] as num?)?.toInt() ?? 0,
      suggestionCount: (stats['suggestionCount'] as num?)?.toInt() ?? 0,
      complaintCount: (stats['complaintCount'] as num?)?.toInt() ?? 0,
      generalCount: (stats['generalCount'] as num?)?.toInt() ?? 0,
      deletedUsersCount: (stats['deletedUsersCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// GET /admin/feedback?limit=20
  Future<List<FeedbackModel>> getFeedback({int limit = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/feedback',
      queryParameters: {'limit': limit},
    );
    final data = res.data;
    if (data == null || data['success'] != true) return [];
    final list = data['feedback'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) {
      final map = Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
      final id = map['id']?.toString() ?? '';
      return FeedbackModel.fromMap(id, map);
    }).toList();
  }

  /// DELETE /admin/feedback/:id
  Future<void> deleteFeedback(String id) async {
    await _dio.delete<Map<String, dynamic>>('/admin/feedback/$id');
  }
}
