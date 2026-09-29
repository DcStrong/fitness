import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/core/widgets/fy_info_banner.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/schedule/presentation/schedule_calendar_sync.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/free_time_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  final initialDate = DateTime(2026, 7, 19);
  const invalidIntervalMessage = 'Окончание должно быть позже начала';

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 7, 19, 10));
  });

  testWidgets('invalid interval shows error and skips createSlot', (
    tester,
  ) async {
    final repository = _ScheduleRepository();

    await _pumpSheet(
      tester,
      repository: repository,
      initialDate: initialDate,
      initialStartTime: const TimeOfDay(hour: 14, minute: 0),
      initialEndTime: const TimeOfDay(hour: 12, minute: 0),
    );

    await tester.tap(find.byKey(const Key('free-time-submit')));
    await tester.pump();

    expect(find.text(invalidIntervalMessage), findsOneWidget);
    verifyNever(
      () => repository.createSlot(
        startsAt: any(named: 'startsAt'),
        endsAt: any(named: 'endsAt'),
        mode: any(named: 'mode'),
      ),
    );
  });

  testWidgets('successful submit calls createSlot and pops with date', (
    tester,
  ) async {
    final repository = _ScheduleRepository();
    final startsAt = DateTime(2026, 7, 19, 10, 0);
    final endsAt = DateTime(2026, 7, 19, 11, 0);
    when(
      () => repository.createSlot(
        startsAt: startsAt,
        endsAt: endsAt,
        mode: 'offline',
      ),
    ).thenAnswer(
      (_) async => ScheduleSlot(
        id: 'slot-1',
        coachId: 'coach',
        startsAt: startsAt.toUtc().toIso8601String(),
        endsAt: endsAt.toUtc().toIso8601String(),
        mode: 'offline',
        status: 'open',
        price: const MoneyAmount(amountMinor: '0', currency: 'RUB'),
      ),
    );

    DateTime? result;
    await _pumpHost(
      tester,
      repository: repository,
      onOpen: (context) async {
        result = await FreeTimeSheet.show(
          context,
          initialDate: initialDate,
          initialStartTime: const TimeOfDay(hour: 10, minute: 0),
          initialEndTime: const TimeOfDay(hour: 11, minute: 0),
        );
      },
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('free-time-submit')));
    await tester.pumpAndSettle();

    verify(
      () => repository.createSlot(
        startsAt: startsAt,
        endsAt: endsAt,
        mode: 'offline',
      ),
    ).called(1);
    expect(result, startsAt);
    expect(find.byType(FreeTimeSheet), findsNothing);
  });

  testWidgets('api error keeps sheet open with Russian message', (
    tester,
  ) async {
    final repository = _ScheduleRepository();
    const message = 'Слот пересекается с другим';
    when(
      () => repository.createSlot(
        startsAt: any(named: 'startsAt'),
        endsAt: any(named: 'endsAt'),
        mode: any(named: 'mode'),
      ),
    ).thenThrow(ApiException(message));

    await _pumpHost(
      tester,
      repository: repository,
      onOpen: (context) => FreeTimeSheet.show(
        context,
        initialDate: initialDate,
        initialStartTime: const TimeOfDay(hour: 10, minute: 0),
        initialEndTime: const TimeOfDay(hour: 11, minute: 0),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('free-time-submit')));
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
    expect(find.byType(FyInfoBanner), findsOneWidget);
    expect(find.byType(FreeTimeSheet), findsOneWidget);
    expect(find.text('Добавить'), findsOneWidget);
  });
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required ScheduleRepository repository,
  required DateTime initialDate,
  TimeOfDay? initialStartTime,
  TimeOfDay? initialEndTime,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ScheduleRepository>.value(value: repository),
          RepositoryProvider<ScheduleCalendarSync>.value(
            value: ScheduleCalendarSync(),
          ),
        ],
        child: Scaffold(
          body: FreeTimeSheet(
            initialDate: initialDate,
            initialStartTime: initialStartTime,
            initialEndTime: initialEndTime,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required ScheduleRepository repository,
  required Future<void> Function(BuildContext context) onOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ScheduleRepository>.value(value: repository),
          RepositoryProvider<ScheduleCalendarSync>.value(
            value: ScheduleCalendarSync(),
          ),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => onOpen(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}
