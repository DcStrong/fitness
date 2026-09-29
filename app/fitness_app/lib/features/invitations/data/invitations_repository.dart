import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'invitation_models.dart';

class InvitationsRepository {
  InvitationsRepository({
    required ApiClient apiClient,
    SharedPreferences? preferences,
  }) : _dio = apiClient.dio,
       _preferencesOverride = preferences;

  static const _pendingTokenKey = 'pending_invite_token';

  final Dio _dio;
  final SharedPreferences? _preferencesOverride;
  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??=
        _preferencesOverride ?? await SharedPreferences.getInstance();
  }

  Future<void> savePendingToken(String token) async {
    await (await _prefs()).setString(_pendingTokenKey, token);
  }

  Future<String?> readPendingToken() async {
    return (await _prefs()).getString(_pendingTokenKey);
  }

  Future<void> clearPendingToken() async {
    await (await _prefs()).remove(_pendingTokenKey);
  }

  Future<InvitationCreated> create() async {
    try {
      final response = await _dio.post<dynamic>('/invitations');
      return InvitationCreated.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<AcceptInvitationResult> accept(String token) async {
    try {
      final response = await _dio.post<dynamic>(
        '/invitations/accept',
        data: {'token': token},
      );
      await clearPendingToken();
      return AcceptInvitationResult.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<List<RelationshipItem>> listRelationships() async {
    try {
      final response = await _dio.get<dynamic>('/relationships/me');
      final data = response.data;
      if (data is! List) {
        return const [];
      }
      return data
          .whereType<Map>()
          .map((e) => RelationshipItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw ApiException('Неверный ответ сервера');
  }

  ApiException _mapDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String message = 'Ошибка сети';

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final raw = map['message'];
      if (raw is String && raw.isNotEmpty) {
        message = raw;
      } else if (raw is List && raw.isNotEmpty) {
        message = raw.map((e) => e.toString()).join(', ');
      }
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Нет связи с сервером';
    }

    // Friendly RU overrides for common invitation errors
    final lower = message.toLowerCase();
    if (lower.contains('expired')) {
      message = 'Приглашение истекло';
    } else if (lower.contains('revoked')) {
      message = 'Приглашение отозвано';
    } else if (lower.contains('already accepted')) {
      message = 'Приглашение уже принято';
    } else if (lower.contains('invalid invitation')) {
      message = 'Недействительное приглашение';
    } else if (lower.contains('own invitation')) {
      message = 'Нельзя принять своё приглашение';
    } else if (status == 403) {
      message = 'Недостаточно прав';
    }

    return ApiException(message, statusCode: status);
  }
}
