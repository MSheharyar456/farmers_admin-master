import 'package:dio/dio.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/crash_report_model.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

class AdminCrashReportsApiService {
  AdminCrashReportsApiService(this._authService);

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

  Future<List<CrashReportModel>> getCrashReports({int limit = 200}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/crashes',
      queryParameters: {'limit': limit},
    );
    final data = res.data;
    if (data == null || data['success'] != true) return [];
    final list = data['crashes'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => CrashReportModel.fromMap(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ))
        .toList();
  }

  Future<void> deleteCrashReport(int id) async {
    await _dio.delete('/admin/crashes/$id');
  }
}
