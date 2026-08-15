import 'package:dio/dio.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

class AdminWorkingStatusApiService {
  AdminWorkingStatusApiService(this._authService);
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

  Future<List<Map<String, dynamic>>> getWorkingStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('/admin/working-status');
    final data = res.data;
    if (data == null || data['success'] != true) return [];
    final list = data['workingStatus'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  Future<String> createWorkingStatus(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/working-status',
        data: body,
      );
      final data = res.data;
      if (data == null || data['success'] != true) {
        throw Exception('Failed to create working status');
      }
      return data['id'] as String? ?? '';
    } on DioException catch (e) {
      throw Exception(_readServerMessage(e, 'You do not have permission to add working status.'));
    }
  }

  Future<void> updateWorkingStatus(String id, Map<String, dynamic> body) async {
    try {
      await _dio.put<Map<String, dynamic>>('/admin/working-status/$id', data: body);
    } on DioException catch (e) {
      throw Exception(_readServerMessage(e, 'You do not have permission to update this working status.'));
    }
  }

  Future<void> deleteWorkingStatus(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/admin/working-status/$id');
    } on DioException catch (e) {
      throw Exception(_readServerMessage(e, 'You do not have permission to delete this working status.'));
    }
  }

  String _readServerMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    } else if (data is Map) {
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final code = e.response?.statusCode;
    if (code == 401 || code == 403) return fallback;
    return fallback;
  }
}
