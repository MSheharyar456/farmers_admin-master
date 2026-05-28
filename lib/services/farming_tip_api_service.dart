import 'package:dio/dio.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/farming_tip_model.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

/// Fetches and updates the single farming tip of the day via the backend API.
class FarmingTipApiService {
  FarmingTipApiService(this._authService);

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

  /// GET /farming-tip-of-day. Returns the single tip (id 'default') or empty tip.
  Future<FarmingTip> getFarmingTip() async {
    final res = await _dio.get<Map<String, dynamic>>('/farming-tip-of-day');
    final data = res.data;
    if (data == null || data['success'] != true) {
      return FarmingTip(tipId: 'default');
    }
    final tipJson = data['farmingTipOfDay'] as Map<String, dynamic>?;
    if (tipJson == null) return FarmingTip(tipId: 'default');
    final updatedAt = (tipJson['updatedAt'] as num?)?.toInt();
    return FarmingTip(
      tipId: 'default',
      farmingTipEnglish: tipJson['farmingTipEnglish']?.toString(),
      farmingTipArabic: tipJson['farmingTipArabic']?.toString(),
      farmingTipGerman: tipJson['farmingTipGerman']?.toString(),
      farmingTipTurkish: tipJson['farmingTipTurkish']?.toString(),
      createdAt: updatedAt,
    );
  }

  /// PUT /farming-tip-of-day. Requires admin auth.
  Future<void> updateFarmingTip({
    required String farmingTipEnglish,
    required String farmingTipArabic,
    required String farmingTipGerman,
    required String farmingTipTurkish,
  }) async {
    await _dio.put<Map<String, dynamic>>(
      '/farming-tip-of-day',
      data: {
        'farmingTipEnglish': farmingTipEnglish,
        'farmingTipArabic': farmingTipArabic,
        'farmingTipGerman': farmingTipGerman,
        'farmingTipTurkish': farmingTipTurkish,
      },
    );
  }
}
