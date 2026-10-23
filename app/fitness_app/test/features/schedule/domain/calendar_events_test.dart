import 'package:fitness_app/features/booking_requests/data/booking_request_models.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/schedule/domain/calendar_events.dart';
import 'package:fitness_app/features/schedule/domain/calendar_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapCalendarEvents', () {
    test('session event keeps the session mode', () {
      final events = mapCalendarEvents(
        sessions: [
          _session(
            id: 'online',
            startsAt: '2026-07-19T12:00:00.000Z',
            endsAt: '2026-07-19T13:00:00.000Z',
            mode: 'online',
          ),
        ],
        slots: const [],
        requests: const [],
      );

      expect(events.single.mode, 'online');
    });

    test('sorts chronologically and labels types', () {
      final events = mapCalendarEvents(
        sessions: [
          _session(
            id: 's1',
            startsAt: '2026-07-19T12:00:00.000Z',
            endsAt: '2026-07-19T13:00:00.000Z',
            studentEmail: 'a@example.com',
          ),
        ],
        slots: [
          _slot(
            id: 'free',
            startsAt: '2026-07-19T08:00:00.000Z',
            endsAt: '2026-07-19T09:00:00.000Z',
          ),
        ],
        requests: [
          _request(
            id: 'r1',
            slotId: 'held',
            startsAt: DateTime.parse('2026-07-19T10:00:00.000Z'),
            endsAt: DateTime.parse('2026-07-19T11:00:00.000Z'),
          ),
        ],
      );

      expect(events.map((e) => e.type).toList(), [
        CalendarEventType.availability,
        CalendarEventType.request,
        CalendarEventType.session,
      ]);
      expect(events[0].typeLabel, 'Свободно');
      expect(events[1].typeLabel, 'Ожидает решения');
      expect(events[2].typeLabel, 'Тренировка');
    });

    test('pending request suppresses held free slot', () {
      final events = mapCalendarEvents(
        sessions: const [],
        slots: [
          _slot(
            id: 'held',
            startsAt: '2026-07-19T10:00:00.000Z',
            endsAt: '2026-07-19T11:00:00.000Z',
            held: true,
          ),
        ],
        requests: [
          _request(
            id: 'r1',
            slotId: 'held',
            startsAt: DateTime.parse('2026-07-19T10:00:00.000Z'),
            endsAt: DateTime.parse('2026-07-19T11:00:00.000Z'),
          ),
        ],
      );

      expect(events, hasLength(1));
      expect(events.single.type, CalendarEventType.request);
    });

    test('booked session shows up to two workout titles', () {
      final events = mapCalendarEvents(
        sessions: [
          _session(
            id: 's1',
            startsAt: '2026-07-19T10:00:00.000Z',
            endsAt: '2026-07-19T11:00:00.000Z',
            workouts: const [
              SessionWorkoutAttached(
                studentPlanId: 'c1',
                title: 'Силовая',
                goal: 'hypertrophy',
                source: 'program',
                overridden: false,
              ),
              SessionWorkoutAttached(
                studentPlanId: 'c2',
                title: 'Ноги',
                goal: 'hypertrophy',
                source: 'program',
                overridden: false,
              ),
              SessionWorkoutAttached(
                studentPlanId: 'c3',
                title: 'Кор',
                goal: 'general',
                source: 'program',
                overridden: false,
              ),
            ],
          ),
        ],
        slots: const [],
        requests: const [],
      );

      expect(events.single.secondaryLabel, 'Силовая, Ноги');
    });

    test('booked slot is represented only by Session', () {
      final events = mapCalendarEvents(
        sessions: [
          _session(
            id: 's1',
            startsAt: '2026-07-19T10:00:00.000Z',
            endsAt: '2026-07-19T11:00:00.000Z',
          ),
        ],
        slots: [
          _slot(
            id: 'booked',
            startsAt: '2026-07-19T10:00:00.000Z',
            endsAt: '2026-07-19T11:00:00.000Z',
            status: 'booked',
          ),
        ],
        requests: const [],
      );

      expect(events, hasLength(1));
      expect(events.single.type, CalendarEventType.session);
    });

    test('terminal sessions stay muted-labelled', () {
      final events = mapCalendarEvents(
        sessions: [
          _session(
            id: 's1',
            startsAt: '2026-07-19T10:00:00.000Z',
            endsAt: '2026-07-19T11:00:00.000Z',
            status: 'completed',
          ),
        ],
        slots: const [],
        requests: const [],
      );

      expect(events.single.isTerminal, isTrue);
      expect(events.single.typeLabel, 'Завершена');
      expect(events.single.secondaryLabel, 'Завершена');
    });

    test('filters by visible range', () {
      final range = rangeForMode(CalendarMode.day, DateTime(2026, 7, 19));
      final events = mapCalendarEvents(
        sessions: [
          _session(
            id: 'inside',
            startsAt: '2026-07-19T12:00:00.000Z',
            endsAt: '2026-07-19T13:00:00.000Z',
          ),
          _session(
            id: 'outside',
            startsAt: '2026-07-21T12:00:00.000Z',
            endsAt: '2026-07-21T13:00:00.000Z',
          ),
        ],
        slots: const [],
        requests: const [],
        range: range,
      );
      expect(events.map((e) => e.sessionId), ['inside']);
    });

    test('session page location is /sessions/:id', () {
      final events = mapCalendarEvents(
        sessions: [
          _session(
            id: 's1',
            startsAt: '2026-07-19T12:00:00.000Z',
            endsAt: '2026-07-19T13:00:00.000Z',
          ),
        ],
        slots: const [],
        requests: const [],
      );
      expect(sessionPageLocation(events.single), '/sessions/s1');
      expect(
        sessionPageLocation(
          CalendarEvent(
            id: 'slot',
            type: CalendarEventType.availability,
            startsAt: DateTime.parse('2026-07-19T08:00:00.000Z'),
            endsAt: DateTime.parse('2026-07-19T09:00:00.000Z'),
            title: 'Свободно',
            secondaryLabel: '',
            mode: 'offline',
          ),
        ),
        isNull,
      );
    });

    test('omits cancelled sessions so open slots can appear', () {
      final events = mapCalendarEvents(
        sessions: [
          _session(
            id: 'cancelled',
            startsAt: '2026-07-19T10:00:00.000Z',
            endsAt: '2026-07-19T11:00:00.000Z',
            status: 'cancelled',
          ),
        ],
        slots: [
          _slot(
            id: 'free-again',
            startsAt: '2026-07-19T10:00:00.000Z',
            endsAt: '2026-07-19T11:00:00.000Z',
          ),
        ],
        requests: const [],
      );

      expect(events.where((e) => e.type == CalendarEventType.session), isEmpty);
      expect(
        events
            .singleWhere((e) => e.type == CalendarEventType.availability)
            .slotId,
        'free-again',
      );
    });
  });
}

TrainingSession _session({
  required String id,
  required String startsAt,
  required String endsAt,
  String status = 'booked',
  String studentEmail = 'student@example.com',
  List<SessionWorkoutAttached> workouts = const [],
  String mode = 'offline',
}) {
  return TrainingSession(
    id: id,
    coachId: 'coach',
    studentId: 'student',
    startsAt: startsAt,
    endsAt: endsAt,
    status: status,
    createdBy: 'coach',
    studentEmail: studentEmail,
    finance: const SessionFinance(status: 'not_tracked'),
    workouts: workouts,
    mode: mode,
  );
}

ScheduleSlot _slot({
  required String id,
  required String startsAt,
  required String endsAt,
  String status = 'open',
  bool held = false,
}) {
  return ScheduleSlot(
    id: id,
    coachId: 'coach',
    startsAt: startsAt,
    endsAt: endsAt,
    mode: 'online',
    status: status,
    held: held,
  );
}

BookingRequest _request({
  required String id,
  required String slotId,
  required DateTime startsAt,
  required DateTime endsAt,
}) {
  return BookingRequest(
    id: id,
    coachId: 'coach',
    studentId: 'student',
    scheduleSlotId: slotId,
    status: BookingRequestStatus.pending,
    quotedPriceMinor: '10000',
    quotedCurrency: 'RUB',
    expiresAt: startsAt.add(const Duration(hours: 6)),
    requestedSlot: BookingRequestSlotSummary(
      id: slotId,
      startsAt: startsAt,
      endsAt: endsAt,
      mode: 'online',
    ),
    counterpart: const BookingRequestCounterpart(
      id: 'student',
      label: 'Ученик',
    ),
    createdAt: startsAt.subtract(const Duration(hours: 1)),
    updatedAt: startsAt.subtract(const Duration(hours: 1)),
  );
}
