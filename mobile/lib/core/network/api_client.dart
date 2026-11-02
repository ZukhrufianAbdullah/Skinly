// lib/core/network/api_client.dart
// Dio HTTP client dengan interceptor JWT token dan error handling seragam
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/auth_storage.dart';

/// Konfigurasi base URL API.
/// Gunakan --dart-define=API_BASE_URL=http://... untuk override.
const String _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000', // default emulator Android
);

class ApiClient {
  ApiClient._();

  static Dio? _instance;
  static AuthStorage? _authStorage;
  static VoidCallback? onUnauthorized;

  /// Base URL yang otomatis menyesuaikan jika berjalan di web browser
  static String get baseUrl {
    var url = _defaultBaseUrl;
    if (kIsWeb && url.contains('10.0.2.2')) {
      url = url.replaceAll('10.0.2.2', 'localhost');
    }
    return url;
  }

  static void initialize(AuthStorage authStorage, {VoidCallback? onTokenExpired}) {
    _authStorage = authStorage;
    onUnauthorized = onTokenExpired;
    _instance = _createDio();
  }

  static Dio get dio {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ));

    // Interceptor untuk menambahkan Authorization: Bearer <token>
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        var token = _authStorage?.cachedToken;
        if ((token == null || token.isEmpty) && _authStorage != null) {
          token = await _authStorage!.initToken();
        }
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] ${options.method} ${options.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('[API] Response ${response.statusCode}: ${response.requestOptions.path}');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint('[API] Error ${error.response?.statusCode}: ${error.message}');
        }

        // Tangani 401 Unauthorized (abaikan jika berasal dari endpoint login/register)
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.path;
          if (!path.contains('/auth/login') && !path.contains('/auth/register')) {
            await _authStorage?.clearToken();
            onUnauthorized?.call();
          }
        }

        handler.next(error);
      },
    ));

    return dio;
  }

  /// Ekstrak pesan error ramah dari response API atau DioException
  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final errorObj = data['error'];
        if (errorObj is Map) {
          return errorObj['message'] as String? ?? 'Terjadi kesalahan tidak diketahui.';
        }
        final detailObj = data['detail'];
        if (detailObj is Map && detailObj['error'] is Map) {
          return detailObj['error']['message'] as String? ?? 'Terjadi kesalahan tidak diketahui.';
        }
        if (detailObj is String) {
          return detailObj;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Koneksi timeout. Pastikan server backend sudah menyala.';
        case DioExceptionType.connectionError:
          return 'Tidak dapat terhubung ke server. Pastikan backend berjalan dan perangkat terhubung jaringan yang sama.';
        default:
          return error.message ?? 'Terjadi kesalahan jaringan.';
      }
    }
    return error.toString();
  }
}
