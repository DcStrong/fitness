import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _dio = apiClient.dio,
       _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AuthSession> register({
    required String email,
    required String password,
    required String role,
    required String displayName,
  }) async {
    final session = await _postAuth(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'role': role,
        'displayName': displayName,
      },
    );
    await _persist(session);
    return session;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _postAuth(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    await _persist(session);
    return session;
  }

  Future<AuthUser> me() async {
    try {
      final response = await _dio.get<dynamic>('/users/me');
      return AuthUser.fromJson(_asJsonMap(response.data));
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _mapDio(error);
    } catch (error) {
      throw ApiException('Не удалось разобрать профиль: $error');
    }
  }

  Future<void> logout() async {
    final refresh = await _tokenStorage.readRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _dio.post<dynamic>(
          '/auth/logout',
          data: {'refreshToken': refresh},
        );
      }
    } on DioException {
      // Local logout still proceeds.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<bool> hasAccessToken() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthSession> _postAuth(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return AuthSession.fromJson(_asJsonMap(response.data));
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _mapDio(error);
    } catch (error) {
      throw ApiException('Не удалось разобрать ответ сервера: $error');
    }
  }

  Future<void> _persist(AuthSession session) async {
    try {
      await _tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    } catch (error) {
      throw ApiException('Не удалось сохранить токены: $error');
    }
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw ApiException('Пустой или неверный ответ сервера');
  }

  ApiException _mapDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? message;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final raw = map['message'];
      if (raw is String && raw.isNotEmpty) {
        message = raw;
      } else if (raw is List && raw.isNotEmpty) {
        message = raw.map((e) => e.toString()).join(', ');
      } else if (map['error'] is String) {
        message = map['error'] as String;
      }
    }

    message ??= switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Нет связи с сервером. Проверьте API_BASE_URL.',
      _ when status == 401 => 'Неверный email или пароль',
      _ when status == 409 => 'Email уже зарегистрирован',
      _ =>
        error.message?.isNotEmpty == true
            ? error.message!
            : 'Ошибка сети (${error.type.name}${status != null ? ', HTTP $status' : ''})',
    };

    return ApiException(message, statusCode: status);
  }
}
