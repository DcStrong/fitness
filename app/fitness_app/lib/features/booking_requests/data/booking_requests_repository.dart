import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'booking_request_models.dart';

class BookingRequestsRepository {
  BookingRequestsRepository({required ApiClient apiClient})
    : _dio = apiClient.dio;

  final Dio _dio;

  Future<BookingRequest> create(String scheduleSlotId) => _request(
    () => _dio.post<dynamic>(
      '/booking-requests',
      data: {'scheduleSlotId': scheduleSlotId},
    ),
    (data) => BookingRequest.fromJson(_map(data)),
  );

  Future<BookingRequestPage> listMine({
    int page = 1,
    int limit = 20,
    BookingRequestStatus? status,
  }) => _page('/booking-requests/mine', page, limit, status);

  Future<BookingRequest> withdraw(String id) => _request(
    () => _dio.post<dynamic>('/booking-requests/$id/withdraw'),
    (data) => BookingRequest.fromJson(_map(data)),
  );

  Future<BookingRequestPage> inbox({
    int page = 1,
    int limit = 20,
    BookingRequestStatus? status,
  }) => _page('/booking-requests/inbox', page, limit, status);

  Future<int> pendingCount() => _request(
    () => _dio.get<dynamic>('/booking-requests/pending-count'),
    (data) => (_map(data)['count'] as num?)?.toInt() ?? 0,
  );

  Future<BookingRequest> accept(String id) => _decision(id, 'accept');

  Future<BookingRequest> reject(
    String id, {
    required BookingRequestRejectionReason reason,
    String? comment,
  }) => _request(
    () => _dio.post<dynamic>(
      '/booking-requests/$id/reject',
      data: {
        'reason': reason.wireValue,
        if (comment?.trim().isNotEmpty == true) 'comment': comment!.trim(),
      },
    ),
    (data) => BookingRequest.fromJson(_map(data)),
  );

  Future<BookingRequest> alternate(String id, DateTime startsAt) => _request(
    () => _dio.post<dynamic>(
      '/booking-requests/$id/alternate',
      data: {'startsAt': startsAt.toUtc().toIso8601String()},
    ),
    (data) => BookingRequest.fromJson(_map(data)),
  );

  Future<BookingRequest> _decision(String id, String action) => _request(
    () => _dio.post<dynamic>('/booking-requests/$id/$action'),
    (data) => BookingRequest.fromJson(_map(data)),
  );

  Future<BookingRequestPage> _page(
    String path,
    int page,
    int limit,
    BookingRequestStatus? status,
  ) => _request(
    () => _dio.get<dynamic>(
      path,
      queryParameters: {
        'page': page,
        'limit': limit.clamp(1, 50),
        if (status != null) 'status': status.name,
      },
    ),
    (data) => BookingRequestPage.fromJson(_map(data)),
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
    }
  }

  ApiException _mapError(DioException error) {
    final data = error.response?.data;
    final raw = data is Map && data['message'] is List
        ? (data['message'] as List).whereType<String>().join(' ')
        : data is Map && data['message'] is String
        ? data['message'] as String
        : 'Ошибка сети';
    final lower = raw.toLowerCase();
    final message = switch (lower) {
      final text when text.contains('already has a pending') =>
        'У вас уже есть заявка этому тренеру',
      final text
          when text.contains('held') ||
              text.contains('already requested') ||
              text.contains('not open') =>
        'Это время уже занято другой заявкой',
      final text
          when text.contains('decision window has already closed') ||
              text.contains('not requestable') =>
        'Записаться можно не позже чем за 2 часа до начала тренировки',
      final text
          when text.contains('deadline') ||
              text.contains('decision window') ||
              text.contains('expired') =>
        'Время для отправки или решения заявки истекло',
      final text when text.contains('overlap') || text.contains('conflict') =>
        'Выбранное время пересекается с другой тренировкой',
      final text when text.contains('not linked') =>
        'Связь тренера и ученика больше не активна',
      final text
          when text.contains('cannot transition') ||
              text.contains('not pending') =>
        'Заявка уже обработана',
      _ => raw,
    };
    return ApiException(message, statusCode: error.response?.statusCode);
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException();
  }
}
