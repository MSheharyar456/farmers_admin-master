import 'package:dio/dio.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/models/commission_model.dart';

/// Service for admin to fetch commission transfers from backend API
class CommissionService {
  static const _connectTimeout = Duration(seconds: 30);
  static const _receiveTimeout = Duration(seconds: 30);

  final AdminServerAuthService _authService;

  CommissionService({AdminServerAuthService? authService})
      : _authService = authService ?? AdminServerAuthService();

  Dio get _dio {
    final d = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl, // Use from api_config.dart
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
      ),
    );
    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authService.authToken;
          if (token != null) {
            final value = 'Bearer $token';
            options.headers['Authorization'] = value;
            options.headers['X-Authorization'] = value;
          }
          return handler.next(options);
        },
      ),
    );
    return d;
  }

  /// Fetch all commission transfers (admin endpoint)
  Future<List<CommissionModel>> getAllCommissions({
    String? status,
    int limit = 500,
    int offset = 0,
  }) async {
    try {
      String url = '/admin/commissions?limit=$limit&offset=$offset';
      if (status != null && status.isNotEmpty) {
        url += '&status=$status';
      }

      final res = await _dio.get<Map<String, dynamic>>(url);
      final data = res.data;

      if (data == null || data['success'] != true) {
        return [];
      }

      final commissions = data['commissions'];
      if (commissions is! List) {
        return [];
      }

      return commissions
          .map((e) => e is Map<String, dynamic>
              ? CommissionModel.fromApiJson(e)
              : null)
          .where((c) => c != null)
          .cast<CommissionModel>()
          .toList();
    } on DioException catch (e) {
      print('CommissionService.getAllCommissions error: ${e.message}');
      return [];
    } catch (e) {
      print('CommissionService.getAllCommissions error: $e');
      return [];
    }
  }

  /// Delete a commission transfer
  Future<bool> deleteCommission(String id) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>('/admin/commissions/$id');
      final data = res.data;
      return data != null && data['success'] == true;
    } on DioException catch (e) {
      print('CommissionService.deleteCommission error: ${e.message}');
      return false;
    } catch (e) {
      print('CommissionService.deleteCommission error: $e');
      return false;
    }
  }

  /// Update commission status (approve/reject)
  Future<bool> updateCommissionStatus(
    String id, {
    required String status,
    String? adminNotes,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
      };
      final res = await _dio.patch<Map<String, dynamic>>(
        '/admin/commissions/$id',
        data: body,
      );
      final data = res.data;
      return data != null && data['success'] == true;
    } on DioException catch (e) {
      print('CommissionService.updateCommissionStatus error: ${e.message}');
      return false;
    } catch (e) {
      print('CommissionService.updateCommissionStatus error: $e');
      return false;
    }
  }
}
