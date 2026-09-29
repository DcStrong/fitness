import 'dart:async';

import 'package:dio/dio.dart';

import 'token_storage.dart';

typedef OnSessionExpired = void Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required this.onSessionExpired,
  }) : _dio = dio,
       _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final OnSessionExpired onSessionExpired;

  Completer<void>? _refreshCompleter;
  bool _sessionExpiredNotified = false;

  static const _skipAuthPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/logout',
    '/health',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final path = options.path;
      final skip = _skipAuthPaths.any(path.contains);
      if (!skip) {
        final access = await _tokenStorage.readAccessToken();
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
      }
      if (!handler.isCompleted) {
        handler.next(options);
      }
    } catch (error, stack) {
      if (!handler.isCompleted) {
        handler.reject(
          DioException(
            requestOptions: options,
            error: error,
            stackTrace: stack,
            type: DioExceptionType.unknown,
          ),
        );
      }
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final path = err.requestOptions.path;
    final isAuthPath = _skipAuthPaths.any(path.contains);

    if (response?.statusCode != 401 || isAuthPath) {
      if (!handler.isCompleted) {
        handler.next(err);
      }
      return;
    }

    try {
      await _refreshTokens();
      final access = await _tokenStorage.readAccessToken();
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $access';
      final clone = await _dio.fetch<dynamic>(opts);
      if (!handler.isCompleted) {
        handler.resolve(clone);
      }
    } catch (_) {
      await _tokenStorage.clear();
      if (!handler.isCompleted) {
        try {
          handler.reject(err);
        } on StateError {
          // Concurrent logout/cancel may complete the handler first.
        }
      }
      _notifySessionExpiredOnce();
    }
  }

  void _notifySessionExpiredOnce() {
    if (_sessionExpiredNotified) {
      return;
    }
    _sessionExpiredNotified = true;
    onSessionExpired();
  }

  Future<void> _refreshTokens() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<void>();
    _refreshCompleter = completer;
    // New refresh attempt may succeed after a prior expiry.
    _sessionExpiredNotified = false;

    try {
      final refresh = await _tokenStorage.readRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        throw StateError('No refresh token');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
        options: Options(
          headers: {'Authorization': null},
          contentType: Headers.jsonContentType,
        ),
      );

      final data = response.data;
      if (data == null) {
        throw StateError('Empty refresh response');
      }

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw StateError('Missing tokens in refresh response');
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      completer.complete();
    } catch (error, stack) {
      completer.completeError(error, stack);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
