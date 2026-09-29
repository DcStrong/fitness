import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_app/core/network/api_client.dart';
import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/core/network/token_storage.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduleRepository.listSessions', () {
    test('serializes from, to, and status query parameters', () async {
      final adapter = _RecordingAdapter(
        statusCode: 200,
        body: const <dynamic>[],
      );
      final repository = _repository(adapter);
      final from = DateTime.parse('2026-07-19T00:00:00+03:00');
      final to = DateTime.parse('2026-07-20T00:00:00+03:00');

      await repository.listSessions(from: from, to: to, status: 'booked');

      expect(adapter.lastRequest?.path, '/sessions');
      expect(
        adapter.lastRequest?.queryParameters,
        containsPair('from', from.toUtc().toIso8601String()),
      );
      expect(
        adapter.lastRequest?.queryParameters,
        containsPair('to', to.toUtc().toIso8601String()),
      );
      expect(
        adapter.lastRequest?.queryParameters,
        containsPair('status', 'booked'),
      );
    });

    test('keeps existing calls free of empty query parameters', () async {
      final adapter = _RecordingAdapter(
        statusCode: 200,
        body: const <dynamic>[],
      );
      final repository = _repository(adapter);

      await repository.listSessions();

      expect(adapter.lastRequest?.queryParameters, isEmpty);
    });

    test('maps API errors to the existing Russian message', () async {
      final adapter = _RecordingAdapter(
        statusCode: 409,
        body: const <String, dynamic>{'message': 'Slot already booked'},
      );
      final repository = _repository(adapter);

      await expectLater(
        repository.listSessions(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Слот уже занят',
          ),
        ),
      );
    });
  });

  group('ScheduleRepository.listOwnSlots', () {
    test('serializes optional from and to as UTC ISO query params', () async {
      final adapter = _RecordingAdapter(
        statusCode: 200,
        body: const <dynamic>[],
      );
      final repository = _repository(adapter);
      final from = DateTime.parse('2026-07-19T00:00:00+03:00');
      final to = DateTime.parse('2026-07-26T00:00:00+03:00');

      await repository.listOwnSlots(from: from, to: to);

      expect(adapter.lastRequest?.path, '/schedule/slots');
      expect(
        adapter.lastRequest?.queryParameters,
        containsPair('from', from.toUtc().toIso8601String()),
      );
      expect(
        adapter.lastRequest?.queryParameters,
        containsPair('to', to.toUtc().toIso8601String()),
      );
    });

    test('keeps parameterless callers free of query parameters', () async {
      final adapter = _RecordingAdapter(
        statusCode: 200,
        body: const <dynamic>[],
      );
      final repository = _repository(adapter);

      await repository.listOwnSlots();

      expect(adapter.lastRequest?.queryParameters, isEmpty);
    });

    test('client-filters slots outside the requested local range', () async {
      final adapter = _RecordingAdapter(
        statusCode: 200,
        body: const <dynamic>[
          {
            'id': 'inside',
            'coachId': 'coach',
            'startsAt': '2026-07-20T10:00:00.000Z',
            'endsAt': '2026-07-20T11:00:00.000Z',
            'mode': 'online',
            'status': 'open',
          },
          {
            'id': 'outside',
            'coachId': 'coach',
            'startsAt': '2026-07-27T10:00:00.000Z',
            'endsAt': '2026-07-27T11:00:00.000Z',
            'mode': 'online',
            'status': 'open',
          },
        ],
      );
      final repository = _repository(adapter);
      final from = DateTime.utc(2026, 7, 19);
      final to = DateTime.utc(2026, 7, 26);

      final slots = await repository.listOwnSlots(from: from, to: to);

      expect(slots.map((slot) => slot.id), ['inside']);
    });
  });

  group('ScheduleRepository.availability', () {
    test('loads settings from /schedule/availability/settings', () async {
      final adapter = _RecordingAdapter(
        statusCode: 200,
        body: const <String, dynamic>{
          'coachId': 'coach-1',
          'timezone': 'Europe/Moscow',
          'defaultDurationMinutes': 60,
          'breakMinutes': 15,
          'horizonWeeks': 8,
          'onlineDurationMinutes': null,
          'offlineDurationMinutes': null,
          'defaultMode': 'offline',
          'updatedAt': '2026-07-21T00:00:00.000Z',
        },
      );
      final repository = _repository(adapter);

      final settings = await repository.getAvailabilitySettings();

      expect(adapter.lastRequest?.path, '/schedule/availability/settings');
      expect(settings.breakMinutes, 15);
      expect(settings.timezone, 'Europe/Moscow');
    });

    test('posts generate and parses summary', () async {
      final adapter = _RecordingAdapter(
        statusCode: 201,
        body: const <String, dynamic>{
          'created': 3,
          'skippedExisting': 1,
          'skippedConflict': 0,
          'removedOrphanOpen': 0,
        },
      );
      final repository = _repository(adapter);

      final summary = await repository.generateAvailability();

      expect(adapter.lastRequest?.path, '/schedule/availability/generate');
      expect(adapter.lastRequest?.method, 'POST');
      expect(summary.created, 3);
      expect(summary.skippedExisting, 1);
    });

    test('maps template validation errors', () async {
      final adapter = _RecordingAdapter(
        statusCode: 400,
        body: const <String, dynamic>{
          'message': 'Windows on the same weekday must not overlap',
        },
      );
      final repository = _repository(adapter);

      await expectLater(
        repository.upsertAvailabilityTemplate(const []),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Окна в один день не должны пересекаться',
          ),
        ),
      );
    });
  });

  group('ScheduleRepository.bookAtTime', () {
    test('posts XOR time-range body to /sessions', () async {
      final starts = DateTime.parse('2026-08-10T10:00:00+03:00');
      final ends = DateTime.parse('2026-08-10T11:00:00+03:00');
      final adapter = _RecordingAdapter(
        statusCode: 201,
        body: <String, dynamic>{
          'id': 'sess-1',
          'coachId': 'c1',
          'studentId': 's1',
          'status': 'booked',
          'createdBy': 'coach',
          'startsAt': starts.toUtc().toIso8601String(),
          'endsAt': ends.toUtc().toIso8601String(),
          'studentEmail': 's@test.com',
          'finance': {'status': 'not_tracked'},
        },
      );
      final repository = _repository(adapter);

      await repository.bookAtTime(
        startsAt: starts,
        endsAt: ends,
        studentId: 's1',
        mode: 'online',
      );

      expect(adapter.lastRequest?.path, '/sessions');
      expect(adapter.lastRequest?.method, 'POST');
      final data = adapter.lastRequest?.data as Map<String, dynamic>;
      expect(data['studentId'], 's1');
      expect(data['mode'], 'online');
      expect(data['startsAt'], starts.toUtc().toIso8601String());
      expect(data['endsAt'], ends.toUtc().toIso8601String());
      expect(data.containsKey('scheduleSlotId'), isFalse);
    });
  });
}

ScheduleRepository _repository(_RecordingAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  final apiClient = ApiClient(
    tokenStorage: TokenStorage(),
    onSessionExpired: () {},
    baseUrl: 'https://fitness-yoda.test',
    dio: dio,
  );
  apiClient.dio.interceptors.clear();
  return ScheduleRepository(apiClient: apiClient);
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Object body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
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
