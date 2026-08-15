import 'package:dio/dio.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:image_picker/image_picker.dart';

/// Slider image item from API.
class SliderItem {
  final String itemId;
  final int order;
  final String url;
  final ImageVariants? imageUrls;
  final bool? webpSupported;

  SliderItem({
    required this.itemId,
    required this.order,
    required this.url,
    this.imageUrls,
    this.webpSupported,
  });

  factory SliderItem.fromJson(Map<String, dynamic> json) {
    return SliderItem(
      itemId: json['itemId'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
      imageUrls: json['imageUrls'] != null ? ImageVariants.fromJson(json['imageUrls'] as Map<String, dynamic>) : null,
      webpSupported: json['webpSupported'] as bool?,
    );
  }
}

/// Image variants for optimized slider images
class ImageVariants {
  final String thumbnail;
  final String medium;
  final String large;
  final String original;

  ImageVariants({
    required this.thumbnail,
    required this.medium,
    required this.large,
    required this.original,
  });

  factory ImageVariants.fromJson(Map<String, dynamic> json) {
    return ImageVariants(
      thumbnail: json['thumbnail'] as String? ?? '',
      medium: json['medium'] as String? ?? '',
      large: json['large'] as String? ?? '',
      original: json['original'] as String? ?? '',
    );
  }
}

/// Fetches and updates slider images via the backend API using the admin JWT.
class SliderApiService {
  SliderApiService(this._authService);

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

  /// GET /slider-images. Returns list sorted by order.
  Future<List<SliderItem>> getSliderImages() async {
    final res = await _dio.get<Map<String, dynamic>>('/slider-images');
    final data = res.data;
    if (data == null || data['success'] != true) return [];
    final list = data['sliderImages'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => SliderItem.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }

  /// POST /slider-images with url (and optional order).
  Future<SliderItem?> addSliderImage({required String url, int? order}) async {
    final body = <String, dynamic>{'url': url};
    if (order != null) body['order'] = order;
    final res = await _dio.post<Map<String, dynamic>>('/slider-images', data: body);
    final data = res.data;
    if (data == null || data['success'] != true) return null;
    return SliderItem(
      itemId: data['itemId'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      url: data['url'] as String? ?? url,
    );
  }

  /// PUT /slider-images/:id. Pass url and/or order to update.
  Future<void> updateSliderImage(String id, {String? url, int? order}) async {
    final body = <String, dynamic>{};
    if (url != null && url.isNotEmpty) body['url'] = url;
    if (order != null) body['order'] = order;
    if (body.isEmpty) return;
    await _dio.put<Map<String, dynamic>>('/slider-images/$id', data: body);
  }

  /// DELETE /slider-images/:id.
  Future<void> deleteSliderImage(String id) async {
    await _dio.delete<Map<String, dynamic>>('/slider-images/$id');
  }

  /// POST /admin/slider-images/upload — multipart file upload. Returns new SliderItem or null.
  Future<SliderItem?> uploadSliderImage(XFile file, {int? order}) async {
    final bytes = await file.readAsBytes();
    final fileName = file.name.isNotEmpty ? file.name : 'slider.jpg';
    final multipartFile = MultipartFile.fromBytes(
      bytes,
      filename: fileName,
    );
    final formData = FormData.fromMap({
      'image': multipartFile,
      if (order != null) 'order': order,
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/slider-images/upload',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: <String, dynamic>{},
      ),
    );
    final data = res.data;
    if (data == null || data['success'] != true) return null;
    return SliderItem(
      itemId: data['itemId'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      url: data['url'] as String? ?? '',
    );
  }

}
