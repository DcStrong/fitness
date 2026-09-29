import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/home/presentation/cubit/home_state.dart';
import 'package:fitness_app/features/home/presentation/widgets/home_bento_shortcuts.dart';
import 'package:fitness_app/features/home/presentation/widgets/home_stat_chips.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders four core trainer tiles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: HomeBentoShortcuts(canReadFinance: false)),
      ),
    );

    expect(find.byKey(const Key('home-bento-schedule')), findsOneWidget);
    expect(find.byKey(const Key('home-bento-students')), findsOneWidget);
    expect(find.byKey(const Key('home-bento-plans')), findsOneWidget);
    expect(find.byKey(const Key('home-bento-recurring')), findsOneWidget);
    expect(find.byKey(const Key('home-bento-finance')), findsNothing);
    expect(find.byKey(const Key('home-week-sparkline')), findsOneWidget);
    expect(find.text('Клиенты, прогресс и заметки'), findsOneWidget);
    expect(find.text('Запланировать тренировку'), findsOneWidget);
    expect(find.byKey(const Key('home-bento-students-go')), findsOneWidget);
    expect(find.byKey(const Key('home-bento-plans-go')), findsOneWidget);
    expect(find.text('Перейти'), findsNWidgets(4));
  });

  testWidgets('shows finance tile when permitted', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: HomeBentoShortcuts(canReadFinance: true)),
      ),
    );

    expect(find.byKey(const Key('home-bento-finance')), findsOneWidget);
    expect(find.text('Финансы'), findsOneWidget);
    expect(find.text('Перейти'), findsNWidgets(4));
  });

  testWidgets(
    'schedule sparkline uses booked counts and Перейти opens schedule',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: HomeBentoShortcuts(
                canReadFinance: false,
                anchor: DateTime(2026, 7, 19),
                sessions: [
                  _session(DateTime(2026, 7, 13, 9), DateTime(2026, 7, 13, 10)),
                  _session(
                    DateTime(2026, 7, 13, 11),
                    DateTime(2026, 7, 13, 12),
                  ),
                  _session(
                    DateTime(2026, 7, 15, 11),
                    DateTime(2026, 7, 15, 12),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/schedule',
            builder: (context, state) =>
                const Scaffold(body: Text('Schedule destination')),
          ),
          GoRoute(
            path: '/schedule/recurring',
            builder: (context, state) =>
                const Scaffold(body: Text('Recurring destination')),
          ),
          GoRoute(
            path: '/session-packages',
            builder: (context, state) =>
                const Scaffold(body: Text('Students destination')),
          ),
          GoRoute(
            path: '/plans',
            builder: (context, state) =>
                const Scaffold(body: Text('Plans destination')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('пн: 2'), findsOneWidget);
      expect(find.bySemanticsLabel('ср: 1'), findsOneWidget);
      expect(find.bySemanticsLabel('вс: 0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home-bento-schedule-go')));
      await tester.pumpAndSettle();
      expect(find.text('Schedule destination'), findsOneWidget);

      router.go('/home');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-bento-recurring-go')));
      await tester.pumpAndSettle();
      expect(find.text('Recurring destination'), findsOneWidget);
    },
  );

  testWidgets('week stat stays На неделе without a free-slot count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: HomeStatChips(
            isTrainer: true,
            todayCount: 2,
            weekCount: 5,
            state: HomeState(),
          ),
        ),
      ),
    );

    expect(find.text('На неделе'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Свободно'), findsNothing);
    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.byKey(const Key('home-stat-chip-requests')), findsNothing);
  });

  testWidgets('week stat shows Свободно when the count is already loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: HomeStatChips(
            isTrainer: true,
            todayCount: 2,
            weekCount: 5,
            state: HomeState(
              pendingCountStatus: PendingCountStatus.success,
              pendingRequestCount: 0,
              freeSlotCount: 4,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Свободно'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('На неделе'), findsNothing);
    expect(find.text('Заявки'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}

TrainingSession _session(DateTime startsAt, DateTime endsAt) {
  return TrainingSession(
    id: '${startsAt.millisecondsSinceEpoch}',
    coachId: 'coach-id',
    studentId: 'student-id',
    startsAt: startsAt.toUtc().toIso8601String(),
    endsAt: endsAt.toUtc().toIso8601String(),
    status: 'booked',
    createdBy: 'coach',
    finance: const SessionFinance(status: 'not_tracked'),
  );
}
