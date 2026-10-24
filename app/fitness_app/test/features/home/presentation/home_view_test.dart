import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/auth/data/auth_models.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:fitness_app/features/home/presentation/home_view.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/booking_requests/data/booking_requests_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockBookingRequestsRepository extends Mock
    implements BookingRequestsRepository {}

void main() {
  const trainer = AuthUser(
    id: 'coach-id',
    email: 'coach@example.com',
    roles: ['trainer'],
    permissions: ['finance:read_own'],
  );
  const student = AuthUser(
    id: 'student-id',
    email: 'student@example.com',
    roles: ['student'],
    permissions: [],
  );
  final now = DateTime(2026, 7, 19, 12);

  testWidgets('trainer sees hero, counters, week and the whole day', (
    tester,
  ) async {
    final repository = _MockScheduleRepository();
    _stubSessions(repository, [
      _session(
        id: 'past',
        status: 'completed',
        startsAt: DateTime(2026, 7, 19, 9),
        endsAt: DateTime(2026, 7, 19, 10),
      ),
      _session(
        id: 'current',
        startsAt: DateTime(2026, 7, 19, 11),
        endsAt: DateTime(2026, 7, 19, 13),
      ),
      _session(
        id: 'future',
        startsAt: DateTime(2026, 7, 19, 15),
        endsAt: DateTime(2026, 7, 19, 16),
      ),
    ]);
    final cubit = await _loadedCubit(repository, now);

    await _pumpHome(tester, cubit: cubit, user: trainer);

    expect(find.text('Воскресенье, 19 июля'), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
    expect(find.byKey(const Key('home-qr-invite')), findsOneWidget);
    expect(find.byKey(const Key('home-next-session')), findsOneWidget);
    expect(
      find.textContaining('Идёт сейчас', findRichText: true),
      findsWidgets,
    );
    expect(find.byKey(const Key('home-stat-chips')), findsOneWidget);
    expect(find.text('На неделе'), findsOneWidget);
    expect(find.byKey(const Key('home-week-bars')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('home-today-session-future')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('home-today-session-past')), findsOneWidget);
    expect(find.text('Проведена'), findsOneWidget);
    expect(find.text('Запланирована'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('home-bento-finance')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('home-bento-shortcuts')), findsOneWidget);
    await cubit.close();
  });

  testWidgets('hero opens the next session', (tester) async {
    final repository = _MockScheduleRepository();
    _stubSessions(repository, [
      _session(
        id: 'future',
        startsAt: DateTime(2026, 7, 19, 15),
        endsAt: DateTime(2026, 7, 19, 16),
        planTitle: 'Жим лёжа',
        studentDisplayName: 'Алина Козлова',
      ),
    ]);
    final cubit = await _loadedCubit(repository, now);
    await _pumpHome(tester, cubit: cubit, user: trainer);

    expect(
      find.textContaining('Через 3 ч', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('АК'), findsOneWidget);
    expect(find.text('Жим лёжа'), findsWidgets);
    expect(find.text('Алина Козлова'), findsWidgets);

    await tester.tap(find.byKey(const Key('home-next-session-open')));
    await tester.pumpAndSettle();
    expect(find.text('Session future'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('empty week offers the schedule instead of a session', (
    tester,
  ) async {
    final repository = _MockScheduleRepository();
    _stubSessions(repository, const []);
    final cubit = await _loadedCubit(repository, now);
    await _pumpHome(tester, cubit: cubit, user: trainer);

    expect(find.text('На этой неделе занятий больше нет'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-next-session-empty-action')));
    await tester.pumpAndSettle();
    expect(find.text('Schedule destination'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('trainer QR action opens existing invitation route', (
    tester,
  ) async {
    final repository = _MockScheduleRepository();
    _stubSessions(repository, const []);
    final cubit = await _loadedCubit(repository, now);

    await _pumpHome(tester, cubit: cubit, user: trainer);
    await tester.tap(find.byKey(const Key('home-qr-invite')));
    await tester.pumpAndSettle();

    expect(find.text('Invite destination'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('student direct access hides trainer-only actions', (
    tester,
  ) async {
    final repository = _MockScheduleRepository();
    _stubSessions(repository, const []);
    final cubit = await _loadedCubit(repository, now);

    await _pumpHome(tester, cubit: cubit, user: student);

    expect(find.byKey(const Key('home-qr-invite')), findsNothing);
    expect(find.byKey(const Key('home-stat-chips')), findsNothing);
    expect(find.byKey(const Key('home-week-bars')), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Тренеры'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Тренировки'), findsOneWidget);
    expect(find.text('Записаться'), findsWidgets);
    expect(find.text('Тренеры'), findsOneWidget);
    expect(find.text('Финансы'), findsNothing);
    await cubit.close();
  });

  testWidgets('trainer pending chip refreshes and student never sees it', (
    tester,
  ) async {
    final schedule = _MockScheduleRepository();
    final requests = _MockBookingRequestsRepository();
    _stubSessions(schedule, const []);
    var count = 2;
    when(() => requests.pendingCount()).thenAnswer((_) async => count);
    final cubit = HomeCubit(
      scheduleRepository: schedule,
      bookingRequestsRepository: requests,
      isTrainer: true,
      now: () => now,
      enableTicker: false,
    );
    await cubit.load();

    await _pumpHome(tester, cubit: cubit, user: trainer);
    expect(find.text('Заявки'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byKey(const Key('home-booking-requests-badge')), findsNothing);

    count = 1;
    await cubit.refresh();
    await tester.pump();
    expect(find.text('Заявки'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    verify(() => requests.pendingCount()).called(2);
    await tester.tap(find.byKey(const Key('home-stat-chip-requests')));
    await tester.pumpAndSettle();
    expect(find.text('Requests destination'), findsOneWidget);

    await _pumpHome(tester, cubit: cubit, user: student);
    expect(find.byKey(const Key('home-stat-chip-requests')), findsNothing);
    await cubit.close();
  });

  testWidgets('loading keeps feature cards visible', (tester) async {
    final repository = _MockScheduleRepository();
    final completer = Completer<List<TrainingSession>>();
    when(
      () => repository.listSessions(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) => completer.future);
    final cubit = HomeCubit(
      scheduleRepository: repository,
      now: () => now,
      enableTicker: false,
    );
    unawaited(cubit.load());

    await _pumpHome(tester, cubit: cubit, user: trainer);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.byKey(const Key('home-bento-students'), skipOffstage: false),
      findsOneWidget,
    );
    completer.complete(const []);
    await tester.pumpAndSettle();
    await cubit.close();
  });

  testWidgets('failure retries and renders the empty day', (tester) async {
    final repository = _MockScheduleRepository();
    var attempts = 0;
    when(
      () => repository.listSessions(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) throw ApiException('Сеть недоступна');
      return const [];
    });
    final cubit = HomeCubit(
      scheduleRepository: repository,
      now: () => now,
      enableTicker: false,
    );
    await cubit.load();

    await _pumpHome(tester, cubit: cubit, user: trainer);
    expect(
      find.text('Не удалось загрузить расписание на сегодня.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('home-schedule-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Сегодня тренировок нет.'), findsOneWidget);
    expect(attempts, 2);
    await cubit.close();
  });

  testWidgets('failed pending count hides the requests card', (tester) async {
    final schedule = _MockScheduleRepository();
    final requests = _MockBookingRequestsRepository();
    _stubSessions(schedule, const []);
    when(() => requests.pendingCount()).thenAnswer((_) async {
      throw ApiException('Сеть недоступна');
    });
    final cubit = HomeCubit(
      scheduleRepository: schedule,
      bookingRequestsRepository: requests,
      isTrainer: true,
      now: () => now,
      enableTicker: false,
    );
    await cubit.load();

    await _pumpHome(tester, cubit: cubit, user: trainer);

    expect(find.byKey(const Key('home-stat-chip-requests')), findsNothing);
    expect(find.text('Заявки'), findsNothing);
    expect(find.text('На неделе'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('pull to refresh reloads the current day', (tester) async {
    final repository = _MockScheduleRepository();
    _stubSessions(repository, const []);
    final cubit = await _loadedCubit(repository, now);

    await _pumpHome(tester, cubit: cubit, user: trainer);
    await tester.drag(
      find.byKey(const Key('home-scroll')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();

    verify(
      () => repository.listSessions(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).called(2);
    await cubit.close();
  });

  testWidgets('narrow screen has no layout overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MockScheduleRepository();
    _stubSessions(repository, [
      _session(
        id: 'future',
        startsAt: DateTime(2026, 7, 19, 15),
        endsAt: DateTime(2026, 7, 19, 16),
      ),
    ]);
    final cubit = await _loadedCubit(repository, now);

    await _pumpHome(tester, cubit: cubit, user: trainer);

    expect(tester.takeException(), isNull);
    await cubit.close();
  });
}

Future<HomeCubit> _loadedCubit(
  ScheduleRepository repository,
  DateTime now,
) async {
  final cubit = HomeCubit(
    scheduleRepository: repository,
    now: () => now,
    enableTicker: false,
  );
  await cubit.load();
  return cubit;
}

void _stubSessions(
  _MockScheduleRepository repository,
  List<TrainingSession> sessions,
) {
  when(
    () => repository.listSessions(
      from: any(named: 'from'),
      to: any(named: 'to'),
    ),
  ).thenAnswer((_) async => sessions);
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required HomeCubit cubit,
  required AuthUser user,
}) async {
  final authCubit = _MockAuthCubit();
  final authState = AuthState(status: AuthStatus.authenticated, user: user);
  whenListen(
    authCubit,
    const Stream<AuthState>.empty(),
    initialState: authState,
  );
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<HomeCubit>.value(value: cubit),
          ],
          child: const HomeView(),
        ),
      ),
      GoRoute(
        path: '/invite',
        builder: (context, state) =>
            const Scaffold(body: Text('Invite destination')),
      ),
      GoRoute(
        path: '/sessions/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Session ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/sessions',
        builder: (context, state) =>
            const Scaffold(body: Text('Sessions destination')),
      ),
      GoRoute(
        path: '/booking-requests/inbox',
        builder: (context, state) =>
            const Scaffold(body: Text('Requests destination')),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) =>
            const Scaffold(body: Text('Schedule destination')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
  await tester.pump();
}

TrainingSession _session({
  required String id,
  required DateTime startsAt,
  required DateTime endsAt,
  String status = 'booked',
  String? planTitle,
  String? studentDisplayName,
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
    studentDisplayName: studentDisplayName,
    finance: const SessionFinance(status: 'not_tracked'),
    planTitle: planTitle,
  );
}
