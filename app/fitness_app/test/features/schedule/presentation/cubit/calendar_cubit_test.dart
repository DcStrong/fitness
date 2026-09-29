import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/booking_requests/data/booking_request_models.dart';
import 'package:fitness_app/features/booking_requests/data/booking_requests_repository.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/schedule/data/availability_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/schedule/domain/calendar_events.dart';
import 'package:fitness_app/features/schedule/domain/calendar_range.dart';
import 'package:fitness_app/features/schedule/presentation/cubit/calendar_cubit.dart';
import 'package:fitness_app/features/schedule/presentation/cubit/calendar_view_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ScheduleRepository extends Mock implements ScheduleRepository {}

class _BookingRequestsRepository extends Mock
    implements BookingRequestsRepository {}

void main() {
  late _ScheduleRepository schedule;
  late _BookingRequestsRepository booking;
  final now = DateTime(2026, 7, 19, 10);

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 7, 19));
    registerFallbackValue(BookingRequestStatus.pending);
  });

  setUp(() {
    schedule = _ScheduleRepository();
    booking = _BookingRequestsRepository();
    when(
      () => schedule.listSessions(
        from: any(named: 'from'),
        to: any(named: 'to'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => schedule.listOwnSlots(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => booking.inbox(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => const BookingRequestPage(
        items: [],
        page: 1,
        limit: 50,
        total: 0,
        totalPages: 0,
      ),
    );
    when(() => booking.pendingCount()).thenAnswer((_) async => 0);
    when(() => schedule.getAvailabilityTemplate()).thenAnswer(
      (_) async => const AvailabilityTemplate(
        seriesId: 's1',
        coachId: 'c1',
        windows: [],
      ),
    );
  });

  CalendarBloc build() => CalendarBloc(
    scheduleRepository: schedule,
    bookingRequestsRepository: booking,
    now: now,
  );

  test('starts in day mode on today', () {
    final bloc = build();
    expect(bloc.state.mode, CalendarMode.day);
    expect(bloc.state.selectedDate, DateTime(2026, 7, 19));
    bloc.close();
  });

  blocTest<CalendarBloc, CalendarState>(
    'CalendarViewStarted populates events from required sources',
    build: build,
    setUp: () {
      when(
        () => schedule.listSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => [
          TrainingSession(
            id: 's1',
            coachId: 'c',
            studentId: 'st',
            startsAt: '2026-07-19T12:00:00.000Z',
            endsAt: '2026-07-19T13:00:00.000Z',
            status: 'booked',
            createdBy: 'c',
            studentEmail: 'st@example.com',
            finance: const SessionFinance(status: 'not_tracked'),
          ),
        ],
      );
    },
    act: (bloc) => bloc.add(const CalendarViewStarted()),
    expect: () => [
      isA<CalendarState>().having(
        (s) => s.status,
        'status',
        CalendarLoadStatus.loading,
      ),
      isA<CalendarState>()
          .having((s) => s.status, 'status', CalendarLoadStatus.ready)
          .having((s) => s.events.length, 'events', 1)
          .having(
            (s) => s.events.single.type,
            'type',
            CalendarEventType.session,
          ),
    ],
  );

  blocTest<CalendarBloc, CalendarState>(
    'request source failure degrades without hiding schedule',
    build: build,
    setUp: () {
      when(
        () => booking.inbox(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          status: any(named: 'status'),
        ),
      ).thenThrow(ApiException('network'));
      when(
        () => schedule.listOwnSlots(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => [
          const ScheduleSlot(
            id: 'slot',
            coachId: 'c',
            startsAt: '2026-07-19T08:00:00.000Z',
            endsAt: '2026-07-19T09:00:00.000Z',
            mode: 'online',
            status: 'open',
          ),
        ],
      );
    },
    act: (bloc) => bloc.add(const CalendarViewStarted()),
    expect: () => [
      isA<CalendarState>(),
      isA<CalendarState>()
          .having((s) => s.status, 'status', CalendarLoadStatus.ready)
          .having((s) => s.requestsDegraded, 'degraded', isTrue)
          .having((s) => s.events, 'events', isNotEmpty),
    ],
  );

  blocTest<CalendarBloc, CalendarState>(
    'required source failure without content becomes failure',
    build: build,
    setUp: () {
      when(
        () => schedule.listSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
          status: any(named: 'status'),
        ),
      ).thenThrow(ApiException('down'));
    },
    act: (bloc) => bloc.add(const CalendarViewStarted()),
    expect: () => [
      isA<CalendarState>(),
      isA<CalendarState>().having(
        (s) => s.status,
        'status',
        CalendarLoadStatus.failure,
      ),
    ],
  );

  blocTest<CalendarBloc, CalendarState>(
    'mode switch, period navigation and today',
    build: build,
    act: (bloc) async {
      bloc.add(const CalendarViewStarted());
      await bloc.stream.firstWhere((s) => s.status == CalendarLoadStatus.ready);
      bloc.add(const CalendarViewModeSelected(CalendarMode.week));
      await bloc.stream.firstWhere((s) => s.mode == CalendarMode.week);
      bloc.add(const CalendarViewNextPressed());
      await Future<void>.delayed(Duration.zero);
      bloc.add(CalendarViewTodayPressed(now: now));
      await Future<void>.delayed(Duration.zero);
      bloc.add(CalendarViewDateSelected(DateTime(2026, 7, 21)));
    },
    verify: (bloc) {
      expect(bloc.state.mode, CalendarMode.week);
      expect(bloc.state.selectedDate, DateTime(2026, 7, 21));
      expect(bloc.state.anchorDate, DateTime(2026, 7, 19));
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'CalendarViewRefreshed keeps ready status while reloading',
    build: build,
    act: (bloc) async {
      bloc.add(const CalendarViewStarted());
      await bloc.stream.firstWhere((s) => s.status == CalendarLoadStatus.ready);
      bloc.add(const CalendarViewRefreshed());
      await bloc.stream.firstWhere((s) => !s.isRefreshing);
    },
    verify: (bloc) {
      expect(bloc.state.status, CalendarLoadStatus.ready);
      expect(bloc.state.isRefreshing, isFalse);
    },
  );
}
