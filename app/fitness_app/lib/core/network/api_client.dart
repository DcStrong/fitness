import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required OnSessionExpired onSessionExpired,
    String? baseUrl,
    Dio? dio,
  }) : dio = dio ?? Dio() {
    this.dio.options = BaseOptions(
      baseUrl: baseUrl ?? kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Avoid stale GETs on Flutter web (Chrome may cache /sessions,/schedule).
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );
    this.dio.interceptors.add(
      AuthInterceptor(
        dio: this.dio,
        tokenStorage: tokenStorage,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  final Dio dio;
}
