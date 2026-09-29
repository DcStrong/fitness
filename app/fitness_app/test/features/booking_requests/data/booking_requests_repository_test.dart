import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_app/core/network/api_client.dart';
import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/core/network/token_storage.dart';
import 'package:fitness_app/features/booking_requests/data/booking_request_models.dart';
import 'package:fitness_app/features/booking_requests/data/booking_requests_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create posts scheduleSlotId and parses typed status', () async {
    final adapter = _Adapter(200, _requestJson());
    final repository = _repository(adapter);

    final result = await repository.create('slot-1');

    expect(adapter.last?.path, '/booking-requests');
    expect(adapter.last?.data, {'scheduleSlotId': 'slot-1'});
    expect(result.status, BookingRequestStatus.pending);
  });

  test('inbox serializes typed status and pagination', () async {
    final adapter = _Adapter(200, {
      'items': <dynamic>[],
      'meta': {'page': 2, 'limit': 10, 'total': 0, 'totalPages': 0},
    });
    final repository = _repository(adapter);

    await repository.inbox(
      page: 2,
      limit: 10,
      status: BookingRequestStatus.rejected,
    );

    expect(adapter.last?.queryParameters, {
      'page': 2,
      'limit': 10,
      'status': 'rejected',
    });
  });

  test('maps duplicate pending conflict to Russian copy', () async {
    final adapter = _Adapter(409, {
      'message': 'Student already has a pending request to this coach',
    });

    await expectLater(
      _repository(adapter).create('slot-1'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'У вас уже есть заявка этому тренеру',
        ),
      ),
    );
  });

  test('maps held slot and closed deadline conflicts', () async {
    await expectLater(
      _repository(
        _Adapter(409, {'message': 'Schedule slot is held'}),
      ).create('slot-1'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Это время уже занято другой заявкой',
        ),
      ),
    );
    await expectLater(
      _repository(
        _Adapter(409, {'message': 'Decision window deadline has passed'}),
      ).create('slot-1'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Время для отправки или решения заявки истекло',
        ),
      ),
    );
    await expectLater(
      _repository(
        _Adapter(409, {
          'message': 'Booking request decision window has already closed',
        }),
      ).create('slot-1'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Записаться можно не позже чем за 2 часа до начала тренировки',
        ),
      ),
    );
    await expectLater(
      _repository(
        _Adapter(409, {'message': 'Slot is not requestable'}),
      ).create('slot-1'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Записаться можно не позже чем за 2 часа до начала тренировки',
        ),
      ),
    );
  });
}

BookingRequestsRepository _repository(_Adapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  final client = ApiClient(
    tokenStorage: TokenStorage(),
    onSessionExpired: () {},
    baseUrl: 'https://fitness-yoda.test',
    dio: dio,
  );
  client.dio.interceptors.clear();
  return BookingRequestsRepository(apiClient: client);
}

Map<String, dynamic> _requestJson() => {
  'id': 'request-1',
  'coachId': 'coach-1',
  'studentId': 'student-1',
  'scheduleSlotId': 'slot-1',
  'status': 'pending',
  'quotedPriceMinor': '250000',
  'quotedCurrency': 'RUB',
  'expiresAt': '2026-07-20T08:00:00.000Z',
  'resolvedBy': null,
  'resolvedAt': null,
  'rejectionReason': null,
  'rejectionComment': null,
  'resolution': null,
  'resolvedScheduleSlotId': null,
  'sessionId': null,
  'requestedSlot': {
    'id': 'slot-1',
    'startsAt': '2026-07-20T10:00:00.000Z',
    'endsAt': '2026-07-20T11:00:00.000Z',
    'mode': 'offline',
  },
  'resolvedSlot': null,
  'counterpart': {'id': 'coach-1', 'label': 'Тренер'},
  'createdAt': '2026-07-19T20:00:00.000Z',
  'updatedAt': '2026-07-19T20:00:00.000Z',
};

class _Adapter implements HttpClientAdapter {
  _Adapter(this.statusCode, this.body);
  final int statusCode;
  final Object body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
