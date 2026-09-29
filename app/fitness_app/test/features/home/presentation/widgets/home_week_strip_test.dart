import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/home/presentation/widgets/home_week_strip.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final anchor = DateTime(2026, 7, 19, 12);

  testWidgets('shows workout hints on days with sessions', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomeWeekStrip(
            sessions: [
              _session(
                id: 'future',
                startsAt: DateTime(2026, 7, 19, 15),
                endsAt: DateTime(2026, 7, 19, 16),
                planTitle: 'Жим лёжа',
              ),
            ],
            anchor: anchor,
            now: anchor,
          ),
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

    expect(find.text('Жим лёжа'), findsOneWidget);
    expect(find.byKey(const Key('home-week-strip')), findsOneWidget);
  });

  testWidgets('day tap navigates to schedule', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              HomeWeekStrip(sessions: const [], anchor: anchor, now: anchor),
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

    await tester.tap(find.byKey(const Key('home-week-day-2026-07-19')));
    await tester.pumpAndSettle();

    expect(find.text('Schedule destination'), findsOneWidget);
  });
}

TrainingSession _session({
  required String id,
  required DateTime startsAt,
  required DateTime endsAt,
  String? planTitle,
}) {
  return TrainingSession(
    id: id,
    coachId: 'coach-id',
    studentId: 'student-id',
    startsAt: startsAt.toUtc().toIso8601String(),
    endsAt: endsAt.toUtc().toIso8601String(),
    status: 'booked',
    createdBy: 'coach',
    coachEmail: 'coach@example.com',
    studentEmail: 'student@example.com',
    finance: const SessionFinance(status: 'not_tracked'),
    planTitle: planTitle,
  );
}
