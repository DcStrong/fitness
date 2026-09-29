import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../workout_program/data/workout_program_models.dart';
import 'availability_models.dart';
import 'recurring_booking_models.dart';
import 'schedule_models.dart';

class ScheduleRepository {
  ScheduleRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<ScheduleSlot> createSlot({
    required DateTime startsAt,
    required DateTime endsAt,
    String mode = 'offline',
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/schedule/slots',
        data: {
          'startsAt': startsAt.toUtc().toIso8601String(),
          'endsAt': endsAt.toUtc().toIso8601String(),
          'mode': mode,
        },
      );
      return ScheduleSlot.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<ScheduleSlot>> listOwnSlots({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/schedule/slots',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );
      final slots = _asList(response.data).map(ScheduleSlot.fromJson).toList();
      if (from == null && to == null) return slots;
      return slots.where((slot) {
        final start = DateTime.parse(slot.startsAt);
        if (from != null && start.isBefore(from.toUtc())) return false;
        if (to != null && !start.isBefore(to.toUtc())) return false;
        return true;
      }).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<ScheduleSlot>> listCoachOpenSlots(String coachId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/schedule/coaches/$coachId/slots',
      );
      return _asList(response.data).map(ScheduleSlot.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<void> deleteSlot(String id) async {
    try {
      await _dio.delete<dynamic>('/schedule/slots/$id');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<CoachScheduleSettings> getAvailabilitySettings() async {
    try {
      final response = await _dio.get<dynamic>(
        '/schedule/availability/settings',
      );
      return CoachScheduleSettings.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<CoachScheduleSettings> upsertAvailabilitySettings(
    CoachScheduleSettings settings,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '/schedule/availability/settings',
        data: settings.toJson(),
      );
      return CoachScheduleSettings.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<AvailabilityTemplate> getAvailabilityTemplate() async {
    try {
      final response = await _dio.get<dynamic>(
        '/schedule/availability/template',
      );
      return AvailabilityTemplate.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<AvailabilityTemplate> upsertAvailabilityTemplate(
    List<AvailabilityWindow> windows,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '/schedule/availability/template',
        data: {'windows': windows.map((w) => w.toJson()).toList()},
      );
      return AvailabilityTemplate.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<AvailabilityExceptionItem>> listAvailabilityExceptions() async {
    try {
      final response = await _dio.get<dynamic>(
        '/schedule/availability/exceptions',
      );
      return _asList(
        response.data,
      ).map(AvailabilityExceptionItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<AvailabilityExceptionItem>> replaceAvailabilityExceptions(
    List<AvailabilityExceptionItem> exceptions,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '/schedule/availability/exceptions',
        data: {'exceptions': exceptions.map((e) => e.toJson()).toList()},
      );
      return _asList(
        response.data,
      ).map(AvailabilityExceptionItem.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<AvailabilityPreviewSlot>> previewAvailability({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/schedule/availability/preview',
        queryParameters: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );
      return _asList(
        response.data,
      ).map(AvailabilityPreviewSlot.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<GenerateAvailabilitySummary> generateAvailability() async {
    try {
      final response = await _dio.post<dynamic>(
        '/schedule/availability/generate',
      );
      return GenerateAvailabilitySummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingSession> book({
    required String scheduleSlotId,
    String? studentId,
    String? priceMinor,
  }) async {
    try {
      final data = <String, dynamic>{'scheduleSlotId': scheduleSlotId};
      if (studentId != null) {
        data['studentId'] = studentId;
      }
      if (priceMinor != null) {
        data['priceMinor'] = priceMinor;
      }
      final response = await _dio.post<dynamic>('/sessions', data: data);
      return TrainingSession.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Coach book-at-time: create + book without a prior open slot.
  Future<TrainingSession> bookAtTime({
    required DateTime startsAt,
    required DateTime endsAt,
    required String studentId,
    String mode = 'offline',
    String? priceMinor,
  }) async {
    try {
      final data = <String, dynamic>{
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        'mode': mode,
        'studentId': studentId,
      };
      if (priceMinor != null) {
        data['priceMinor'] = priceMinor;
      }
      final response = await _dio.post<dynamic>('/sessions', data: data);
      return TrainingSession.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<TrainingSession>> listSessions({
    String? status,
    DateTime? from,
    DateTime? to,
    String? studentId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/sessions',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          if (status != null && status.isNotEmpty) 'status': status,
          if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
        },
      );
      return _asList(response.data).map(TrainingSession.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingSession> getSession(String id) async {
    try {
      final response = await _dio.get<dynamic>('/sessions/$id');
      return TrainingSession.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingSession> patchSessionPlan({
    required String sessionId,
    String? studentPlanId,
    List<String>? workoutPlanIds,
    ({
      String studentPlanId,
      List<({String exerciseId, double weightKg})> items,
    })?
    workoutLoads,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (workoutLoads != null) {
        data['workoutLoads'] = {
          'studentPlanId': workoutLoads.studentPlanId,
          'items': [
            for (final item in workoutLoads.items)
              {'exerciseId': item.exerciseId, 'weightKg': item.weightKg},
          ],
        };
      } else if (workoutPlanIds != null) {
        data['workoutPlanIds'] = workoutPlanIds;
      } else {
        data['studentPlanId'] = studentPlanId;
      }
      final response = await _dio.patch<dynamic>(
        '/sessions/$sessionId',
        data: data,
      );
      return TrainingSession.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingSession> completeSession(
    String id, {
    List<Map<String, dynamic>>? logs,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/sessions/$id/complete',
        data: {'logs': ?logs},
      );
      return TrainingSession.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingSession> cancelSession(String id, {String? note}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/sessions/$id/cancel',
        data: {if (note != null && note.isNotEmpty) 'note': note},
      );
      return TrainingSession.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<TrainingSession> markNoShow(String id, {required bool charge}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/sessions/$id/no-show',
        data: {'charge': charge},
      );
      return TrainingSession.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<SessionHistoryEvent>> listSessionHistory(String id) async {
    try {
      final response = await _dio.get<dynamic>('/sessions/$id/history');
      return _asList(response.data).map(SessionHistoryEvent.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<CreateRecurringBookingResult> createRecurringBooking({
    required String studentId,
    required List<int> weekdays,
    required int startMinute,
    required String mode,
    int? horizonWeeksOverride,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/recurring-bookings',
        data: {
          'studentId': studentId,
          'weekdays': weekdays,
          'startMinute': startMinute,
          'mode': mode,
          'horizonWeeksOverride': ?horizonWeeksOverride,
        },
      );
      return CreateRecurringBookingResult.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<RecurringBooking>> listRecurringBookings({
    String status = 'active',
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/recurring-bookings',
        queryParameters: {'status': status},
      );
      return _asList(response.data).map(RecurringBooking.fromJson).toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<RecurringBooking> getRecurringBooking(String id) async {
    try {
      final response = await _dio.get<dynamic>('/recurring-bookings/$id');
      return RecurringBooking.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<RecurringSyncSummary> syncRecurringBooking(String id) async {
    try {
      final response = await _dio.post<dynamic>('/recurring-bookings/$id/sync');
      return RecurringSyncSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<RecurringBooking> cancelRecurringBooking(String id) async {
    try {
      final response = await _dio.post<dynamic>(
        '/recurring-bookings/$id/cancel',
      );
      return RecurringBooking.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<CreateRecurringBookingResult> restoreRecurringBooking(
    String id,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        '/recurring-bookings/$id/restore',
      );
      return CreateRecurringBookingResult.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<void> deleteRecurringBooking(String id) async {
    try {
      await _dio.delete<dynamic>('/recurring-bookings/$id');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<WorkoutProgram?> getWorkoutProgram(String recurringBookingId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/recurring-bookings/$recurringBookingId/program',
      );
      return WorkoutProgram.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _map(e);
    }
  }

  Future<WorkoutProgram> putWorkoutProgram({
    required String recurringBookingId,
    required int horizonWeeks,
    required List<Map<String, dynamic>> days,
    List<Map<String, dynamic>>? progressionRules,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/recurring-bookings/$recurringBookingId/program',
        data: {
          'horizonWeeks': horizonWeeks,
          'days': days,
          'progressionRules': ?progressionRules,
        },
      );
      return WorkoutProgram.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<RecurringSyncSummary> resolveRecurringOccurrence({
    required String id,
    required String localDate,
    required String type,
    int? newStartMinute,
    String? newLocalDate,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/recurring-bookings/$id/occurrences/$localDate/resolve',
        data: {
          'type': type,
          'newStartMinute': ?newStartMinute,
          'newLocalDate': ?newLocalDate,
        },
      );
      return RecurringSyncSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Неверный ответ сервера');
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  ApiException _map(DioException error) {
    final data = error.response?.data;
    var message = 'Ошибка сети';
    String? existingId;
    if (data is Map) {
      final rawExisting = data['existingId'];
      if (rawExisting is String) {
        existingId = rawExisting;
      }
      final rawMessage = data['message'];
      if (rawMessage is String) {
        message = rawMessage;
      } else if (rawMessage is Map) {
        final nested = rawMessage['message'];
        if (nested is String) {
          message = nested;
        }
        final nestedId = rawMessage['existingId'];
        if (nestedId is String) {
          existingId = nestedId;
        }
      } else if (rawMessage is List) {
        message = rawMessage.join(', ');
      }
    }
    final lower = message.toLowerCase();
    if (lower.contains('must not overlap') ||
        lower.contains('windows on the same weekday')) {
      message = 'Окна в один день не должны пересекаться';
    } else if (lower.contains('overlap')) {
      message = 'Слот пересекается с другим открытым слотом';
    } else if (lower.contains('not open') || lower.contains('already booked')) {
      message = 'Слот уже занят';
    } else if (lower.contains('not linked')) {
      message = 'Нет связи тренер ↔ ученик';
    } else if (lower.contains('cannot transition')) {
      message = 'Нельзя изменить статус этой тренировки';
    } else if (lower.contains('not a participant') ||
        lower.contains('only the session coach')) {
      message = 'Недостаточно прав для этого действия';
    } else if (lower.contains('уже есть') || lower.contains('already exists')) {
      message = 'Такая серия уже есть';
    }
    return ApiException(
      message,
      statusCode: error.response?.statusCode,
      existingId: existingId,
    );
  }
}
