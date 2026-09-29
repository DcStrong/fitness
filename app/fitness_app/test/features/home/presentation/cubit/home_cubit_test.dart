import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/home/domain/home_schedule.dart';
import 'package:fitness_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:fitness_app/features/home/presentation/cubit/home_state.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/booking_requests/data/booking_requests_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockBookingRequestsRepository extends Mock
    implements BookingRequestsRepository {}

void main() {
  group('HomeWeekRange', () {
    test('covers Monday through Sunday for mid-week anchor', () {
      final range = HomeWeekRange.forLocalWeek(DateTime(2026, 7, 19, 12));

      expect(range.start, DateTime(2026, 7, 13));
      expect(range.end, DateTime(2026, 7, 20));
    });
  });

  group('homeSessionsForLocalDay', () {
    test('returns only sessions on the requested day sorted by start', () {
      final monday = _session(
        id: 'monday',
        startsAt: DateTime(2026, 7, 13, 10),
        endsAt: DateTime(2026, 7, 13, 11),
      );
      final sundayLate = _session(
        id: 'sunday-late',
        startsAt: DateTime(2026, 7, 19, 18),
        endsAt: DateTime(2026, 7, 19, 19),
      );
      final sundayEarly = _session(
        id: 'sunday-early',
        startsAt: DateTime(2026, 7, 19, 9),
        endsAt: DateTime(2026, 7, 19, 10),
      );

      final sunday = homeSessionsForLocalDay([
        monday,
        sundayLate,
        sundayEarly,
      ], DateTime(2026, 7, 19));

      expect(sunday.map((item) => item.id), ['sunday-early', 'sunday-late']);
    });
  });

  group('homeSessionHintForDay', () {
    test('truncates workout label for strip hints', () {
      final session = _session(
        id: 'one',
        startsAt: DateTime(2026, 7, 19, 10),
        endsAt: DateTime(2026, 7, 19, 11),
        planTitle: 'Очень длинное название тренировки',
      );

      expect(
        homeSessionHintForDay([session], DateTime(2026, 7, 19), maxLength: 10),
        'Очень дли…',
      );
    });

    test('returns null when day has no sessions', () {
      expect(homeSessionHintForDay(const [], DateTime(2026, 7, 19)), isNull);
    });
  });

  group('countHomeWeekBookedSessions', () {
    test('counts booked sessions only', () {
      final sessions = [
        _session(
          id: 'booked',
          startsAt: DateTime(2026, 7, 19, 10),
          endsAt: DateTime(2026, 7, 19, 11),
        ),
        _session(
          id: 'done',
          status: 'completed',
          startsAt: DateTime(2026, 7, 18, 10),
          endsAt: DateTime(2026, 7, 18, 11),
        ),
      ];

      expect(countHomeWeekBookedSessions(sessions), 1);
    });
  });

  group('countHomeTodayUpcomingSessions', () {
    test('counts only upcoming and current sessions for today', () {
      final now = DateTime(2026, 7, 19, 12);
      final sessions = [
        _session(
          id: 'past',
          startsAt: DateTime(2026, 7, 19, 9),
          endsAt: DateTime(2026, 7, 19, 10),
        ),
        _session(
          id: 'future',
          startsAt: DateTime(2026, 7, 19, 15),
          endsAt: DateTime(2026, 7, 19, 16),
        ),
      ];

      expect(countHomeTodayUpcomingSessions(sessions, now), 1);
    });
  });

  group('HomeDayRange', () {
    test('uses calendar midnights for a normal day', () {
      final range = HomeDayRange.forLocalDay(DateTime(2026, 7, 19, 18, 30));

      expect(range.start, DateTime(2026, 7, 19));
      expect(range.end, DateTime(2026, 7, 20));
    });

    test('uses the next calendar date at a DST boundary', () {
      final range = HomeDayRange.forLocalDay(DateTime(2026, 3, 29, 12));

      expect(range.start, DateTime(2026, 3, 29));
      expect(range.end, DateTime(2026, 3, 30));
      expect(range.end.hour, 0);
    });
  });

  group('groupHomeSessions', () {
    final now = DateTime(2026, 7, 19, 12);

    test('sorts current and future booked sessions chronologically', () {
      final future = _session(
        id: 'future',
        startsAt: DateTime(2026, 7, 19, 15),
        endsAt: DateTime(2026, 7, 19, 16),
      );
      final current = _session(
        id: 'current',
        startsAt: DateTime(2026, 7, 19, 11),
        endsAt: DateTime(2026, 7, 19, 13),
      );

      final groups = groupHomeSessions([future, current], now);

      expect(groups.currentAndUpcoming.map((item) => item.id), [
        'current',
        'future',
      ]);
      expect(isHomeSessionCurrent(current, now), isTrue);
      expect(groups.history, isEmpty);
    });

    test('puts elapsed booked and terminal future sessions in history', () {
      final elapsed = _session(
        id: 'elapsed',
        startsAt: DateTime(2026, 7, 19, 9),
        endsAt: DateTime(2026, 7, 19, 10),
      );
      final completed = _session(
        id: 'completed',
        status: 'completed',
        startsAt: DateTime(2026, 7, 19, 13),
        endsAt: DateTime(2026, 7, 19, 14),
      );
      final cancelled = _session(
        id: 'cancelled',
        status: 'cancelled',
        startsAt: DateTime(2026, 7, 19, 15),
        endsAt: DateTime(2026, 7, 19, 16),
      );
      final noShow = _session(
        id: 'no-show',
        status: 'no_show',
        startsAt: DateTime(2026, 7, 19, 17),
        endsAt: DateTime(2026, 7, 19, 18),
      );

      final groups = groupHomeSessions([
        noShow,
        cancelled,
        completed,
        elapsed,
      ], now);

      expect(groups.history.map((item) => item.id), [
        'elapsed',
        'completed',
        'cancelled',
        'no-show',
      ]);
      expect(isExpiredBookedSession(elapsed, now), isTrue);
      expect(groups.currentAndUpcoming, isEmpty);
    });

    test('keeps a session crossing midnight in the supplied day result', () {
      final crossing = _session(
        id: 'crossing',
        startsAt: DateTime(2026, 7, 18, 23, 30),
        endsAt: DateTime(2026, 7, 19, 0, 30),
      );

      final groups = groupHomeSessions([
        crossing,
      ], DateTime(2026, 7, 19, 0, 10));

      expect(groups.currentAndUpcoming, [crossing]);
    });
  });

  group('HomeCubit', () {
    late _MockScheduleRepository repository;
    late DateTime currentTime;

    setUp(() {
      repository = _MockScheduleRepository();
      currentTime = DateTime(2026, 7, 19, 12);
    });

    test('loads current local day and emits success', () async {
      final session = _session(
        id: 'one',
        startsAt: DateTime(2026, 7, 19, 13),
        endsAt: DateTime(2026, 7, 19, 14),
      );
      when(
        () => repository.listSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => [session]);
      final cubit = HomeCubit(
        scheduleRepository: repository,
        now: () => currentTime,
        enableTicker: false,
      );

      await cubit.load();

      expect(cubit.state.status, HomeStatus.success);
      expect(cubit.state.sessions, [session]);
      expect(cubit.state.dayStart, DateTime(2026, 7, 19));
      verify(
        () => repository.listSessions(
          from: DateTime(2026, 7, 13),
          to: DateTime(2026, 7, 20),
        ),
      ).called(1);
      await cubit.close();
    });

    test('emits failure and supports retry', () async {
      when(
        () => repository.listSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenThrow(ApiException('Сеть недоступна'));
      final cubit = HomeCubit(
        scheduleRepository: repository,
        now: () => currentTime,
        enableTicker: false,
      );

      await cubit.load();

      expect(cubit.state.status, HomeStatus.failure);
      expect(cubit.state.errorMessage, contains('Сеть недоступна'));

      when(
        () => repository.listSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => const []);
      await cubit.load();

      expect(cubit.state.status, HomeStatus.success);
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });

    test('refresh recalculates boundaries and reloads', () async {
      when(
        () => repository.listSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => const []);
      final cubit = HomeCubit(
        scheduleRepository: repository,
        now: () => currentTime,
        enableTicker: false,
      );

      await cubit.load();
      await cubit.refresh();

      verify(
        () => repository.listSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(2);
      await cubit.close();
    });

    test('tick reloads after local day rollover', () async {
      when(
        () => repository.listSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => const []);
      final cubit = HomeCubit(
        scheduleRepository: repository,
        now: () => currentTime,
        enableTicker: false,
      );
      await cubit.load();

      currentTime = DateTime(2026, 7, 20, 0, 1);
      await cubit.tick();

      expect(cubit.state.dayStart, DateTime(2026, 7, 20));
      verify(
        () => repository.listSessions(
          from: DateTime(2026, 7, 20),
          to: DateTime(2026, 7, 27),
        ),
      ).called(1);
      await cubit.close();
    });

    test('close cancels the ticker', () async {
      final cubit = HomeCubit(
        scheduleRepository: repository,
        now: () => currentTime,
        tickInterval: const Duration(hours: 1),
      );

      expect(cubit.tickerActive, isTrue);
      await cubit.close();
      expect(cubit.tickerActive, isFalse);
    });

    test('pending count failure does not replace schedule success', () async {
      final requests = _MockBookingRequestsRepository();
      when(
        () => repository.listSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => const []);
      when(() => requests.pendingCount()).thenThrow(ApiException('Сеть'));
      final cubit = HomeCubit(
        scheduleRepository: repository,
        bookingRequestsRepository: requests,
        isTrainer: true,
        now: () => currentTime,
        enableTicker: false,
      );

      await cubit.load();

      expect(cubit.state.status, HomeStatus.success);
      expect(cubit.state.pendingCountStatus, PendingCountStatus.failure);
      expect(cubit.state.pendingRequestCount, isNull);
      await cubit.close();
    });

    test(
      'toggleUpcoming collapses and expands upcoming section state',
      () async {
        when(
          () => repository.listSessions(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => const []);
        final cubit = HomeCubit(
          scheduleRepository: repository,
          now: () => currentTime,
          enableTicker: false,
        );
        await cubit.load();
        expect(cubit.state.upcomingExpanded, isTrue);
        cubit.toggleUpcoming();
        expect(cubit.state.upcomingExpanded, isFalse);
        cubit.toggleUpcoming();
        expect(cubit.state.upcomingExpanded, isTrue);
        await cubit.close();
      },
    );
  });
}

TrainingSession _session({
  required String id,
  required DateTime startsAt,
  required DateTime endsAt,
  String status = 'booked',
  String? planTitle,
}) {
  return TrainingSession(
    id: id,
    coachId: 'coach-id',
    studentId: 'student-id',
    startsAt: startsAt.toUtc().toIso8601String(),
    endsAt: endsAt.toUtc().toIso8601String(),
    status: status,
    createdBy: 'coach',
    coachEmail: 'coach@example.com',
    studentEmail: 'student@example.com',
    finance: const SessionFinance(status: 'not_tracked'),
    planTitle: planTitle,
  );
}
