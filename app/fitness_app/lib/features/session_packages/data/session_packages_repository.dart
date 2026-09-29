import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'session_package_models.dart';

class SessionPackagesRepository {
  SessionPackagesRepository({required ApiClient apiClient})
    : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<SessionPackage>> list() async {
    try {
      final response = await _dio.get<dynamic>('/session-packages');
      return _list(response.data).map(SessionPackage.fromJson).toList();
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<SessionPackage> getById(String id) async {
    try {
      final response = await _dio.get<dynamic>('/session-packages/$id');
      return SessionPackage.fromJson(sessionPackageJsonMap(response.data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<SessionPackage> create({
    required String studentId,
    required int totalSessions,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/session-packages',
        data: {
          'studentId': studentId,
          'totalSessions': totalSessions,
          if (expiresAt != null)
            'expiresAt': expiresAt.toUtc().toIso8601String(),
        },
      );
      return SessionPackage.fromJson(sessionPackageJsonMap(response.data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<SessionPackage> extend({
    required String packageId,
    required int addSessions,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/session-packages/$packageId/extend',
        data: {
          'addSessions': addSessions,
          if (expiresAt != null)
            'expiresAt': expiresAt.toUtc().toIso8601String(),
        },
      );
      return SessionPackage.fromJson(sessionPackageJsonMap(response.data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<SessionPackage> archive(String packageId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/session-packages/$packageId/archive',
      );
      return SessionPackage.fromJson(sessionPackageJsonMap(response.data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data is! List) return const [];
    return data.whereType<Map>().map(sessionPackageJsonMap).toList();
  }

  ApiException _map(DioException error) {
    final data = error.response?.data;
    var message = 'Ошибка сети';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (data is Map && data['message'] is List) {
      message = (data['message'] as List).join(', ');
    }
    final lower = message.toLowerCase();
    if (lower.contains('already exists') || lower.contains('extend it')) {
      message = 'У ученика уже есть активный абонемент — продлите его';
    } else if (lower.contains('not linked')) {
      message = 'Нет связи с этим учеником';
    } else if (lower.contains('not found')) {
      message = 'Абонемент не найден';
    } else if (lower.contains('archived')) {
      message = 'Архивный абонемент нельзя продлить';
    } else if (lower.contains('expiresat')) {
      message = 'Срок действия должен быть в будущем';
    }
    return ApiException(message, statusCode: error.response?.statusCode);
  }
}
