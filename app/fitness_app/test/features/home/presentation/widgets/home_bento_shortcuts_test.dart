import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/home/presentation/cubit/home_state.dart';
import 'package:fitness_app/features/home/presentation/widgets/home_bento_shortcuts.dart';
import 'package:fitness_app/features/home/presentation/widgets/home_stat_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders three core trainer tiles in a list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: HomeBentoShortcuts(canReadFinance: false)),
      ),
    );

    expect(find.byKey(const Key('home-bento-schedule')), findsNothing);
    expect(find.byKey(const Key('home-bento-students')), findsOneWidget);
    expect(find.byKey(const Key('home-bento-plans')), findsOneWidget);
    expect(find.byKey(const Key('home-bento-recurring')), findsOneWidget);
    expect(find.byKey(const Key('home-bento-finance')), findsNothing);
    expect(find.text('Клиенты, прогресс и заметки'), findsOneWidget);
    expect(find.text('Запланировать тренировку'), findsOneWidget);
    expect(find.byKey(const Key('home-bento-students-go')), findsOneWidget);
    expect(find.byKey(const Key('home-bento-plans-go')), findsOneWidget);
    expect(find.text('Перейти'), findsNWidgets(3));
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
    expect(find.text('Перейти'), findsNWidgets(3));
  });

  testWidgets('Перейти opens the matching destinations', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: HomeBentoShortcuts(canReadFinance: false)),
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

    await tester.tap(find.byKey(const Key('home-bento-students-go')));
    await tester.pumpAndSettle();
    expect(find.text('Students destination'), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-bento-recurring-go')));
    await tester.pumpAndSettle();
    expect(find.text('Recurring destination'), findsOneWidget);
  });

  testWidgets('week stat stays На неделе without a free-slot count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: HomeStatChips(todayCount: 2, weekCount: 5, state: HomeState()),
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
