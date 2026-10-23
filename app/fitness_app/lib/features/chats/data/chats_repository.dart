import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'chat_models.dart';

class ChatsRepository {
  ChatsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<ChatConversation>> list({String? query}) => _request(
    () => _dio.get<dynamic>(
      '/chats',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    ),
    (data) => (data as List? ?? const [])
        .whereType<Map>()
        .map((e) => ChatConversation.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  /// Get-or-create the conversation with a linked coach or student.
  Future<ChatConversation> open(String counterpartId) => _request(
    () => _dio.post<dynamic>('/chats', data: {'counterpartId': counterpartId}),
    (data) => ChatConversation.fromJson(_map(data)),
  );

  Future<ChatConversation> get(String conversationId) => _request(
    () => _dio.get<dynamic>('/chats/$conversationId'),
    (data) => ChatConversation.fromJson(_map(data)),
  );

  Future<int> unreadCount() => _request(
    () => _dio.get<dynamic>('/chats/unread-count'),
    (data) => (_map(data)['total'] as num?)?.toInt() ?? 0,
  );

  Future<ChatMessagesPage> messages(
    String conversationId, {
    String? before,
    String? after,
    int? limit,
  }) => _request(
    () => _dio.get<dynamic>(
      '/chats/$conversationId/messages',
      queryParameters: {'before': ?before, 'after': ?after, 'limit': ?limit},
    ),
    (data) => ChatMessagesPage.fromJson(_map(data)),
  );

  Future<ChatMessage> send(
    String conversationId, {
    required String clientId,
    required String body,
  }) => _request(
    () => _dio.post<dynamic>(
      '/chats/$conversationId/messages',
      data: {'clientId': clientId, 'body': body},
    ),
    (data) => ChatMessage.fromJson(_map(data)),
  );

  Future<void> markRead(String conversationId, String upToMessageId) =>
      _request(
        () => _dio.post<dynamic>(
          '/chats/$conversationId/read',
          data: {'upToMessageId': upToMessageId},
        ),
        (_) {},
      );

  Future<T> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data) parse,
  ) async {
    try {
      return parse((await call()).data);
    } on DioException catch (error) {
      throw _mapError(error);
    } on FormatException {
      throw ApiException('Неверный ответ сервера');
    } on TypeError {
      throw ApiException('Неверный ответ сервера');
    }
  }

  ApiException _mapError(DioException error) {
    final status = error.response?.statusCode;
    final message = switch (status) {
      403 => 'Писать можно только своему тренеру или ученику',
      404 => 'Переписка не найдена',
      400 => 'Сообщение не может быть пустым',
      null => 'Нет соединения с сервером',
      _ => 'Не удалось выполнить запрос',
    };
    return ApiException(message, statusCode: status);
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected JSON object');
  }
}
