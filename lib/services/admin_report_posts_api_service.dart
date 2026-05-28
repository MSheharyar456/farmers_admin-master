import 'package:dio/dio.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:flutter/foundation.dart';

class AdminReportPostsApiService {
  AdminReportPostsApiService(this._authService);
  final AdminServerAuthService _authService;

  static const _connectTimeout = Duration(seconds: 30);
  static const _receiveTimeout = Duration(seconds: 30);

  Dio get _dio {
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
    ));
    final token = _authService.authToken;
    if (token != null && token.isNotEmpty) {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (o, h) {
          o.headers['Authorization'] = 'Bearer $token';
          o.headers['X-Authorization'] = 'Bearer $token';
          return h.next(o);
        },
      ));
    }
    return dio;
  }

  Future<List<Map<String, dynamic>>> getReportPosts({int limit = 100}) async {
    debugPrint('[API] Fetching report posts from backend...');
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/report-posts',
      queryParameters: {'limit': limit},
    );
    final data = res.data;
    debugPrint('[API] Response data: $data');
    if (data == null || data['success'] != true) {
      debugPrint('[API] No data or success=false');
      return [];
    }
    final list = data['reportPosts'] as List<dynamic>?;
    debugPrint('[API] reportPosts list length: ${list?.length}');
    if (list == null) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>)).toList();
  }

  Future<void> deleteReportPost(String id) async {
    await _dio.delete<Map<String, dynamic>>('/admin/report-posts/$id');
  }
}
