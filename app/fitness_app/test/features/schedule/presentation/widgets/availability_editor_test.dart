import 'package:fitness_app/features/schedule/data/availability_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/schedule/presentation/screens/availability_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late _MockScheduleRepository repository;

  final settings = CoachScheduleSettings.fromJson(const {
    'coachId': 'c1',
    'timezone': 'Europe/Moscow',
    'defaultDurationMinutes': 60,
    'breakMinutes': 15,
    'horizonWeeks': 2,
    'defaultMode': 'offline',
    'updatedAt': '2026-07-21T00:00:00.000Z',
  });

  setUpAll(() {
    registerFallbackValue(CoachScheduleSettings.defaults());
    registerFallbackValue(const <AvailabilityWindow>[]);
    registerFallbackValue(const <AvailabilityExceptionItem>[]);
  });

  setUp(() {
    repository = _MockScheduleRepository();
    when(
      () => repository.getAvailabilitySettings(),
    ).thenAnswer((_) async => settings);
    when(() => repository.getAvailabilityTemplate()).thenAnswer(
      (_) async => const AvailabilityTemplate(
        seriesId: 's1',
        coachId: 'c1',
        windows: [
          AvailabilityWindow(dayOfWeek: 1, startMinute: 540, endMinute: 780),
        ],
      ),
    );
    when(
      () => repository.listAvailabilityExceptions(),
    ).thenAnswer((_) async => const []);
    when(
      () => repository.previewAvailability(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => const []);
  });

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<ScheduleRepository>.value(
        value: repository,
        child: const MaterialApp(
          home: Scaffold(body: AvailabilityEditorPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows day chips and Monday window', (tester) async {
    await pumpEditor(tester);

    expect(find.byKey(const Key('availability-dow-1')), findsOneWidget);
    expect(find.byKey(const Key('availability-dow-7')), findsOneWidget);
    expect(find.text('09:00 – 13:00'), findsOneWidget);
    expect(find.text('Настройки графика'), findsOneWidget);
    expect(find.text('Рабочая неделя'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('availability-copy-weekdays')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Скопировать на каждый день'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Исключения'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Исключения'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Сгенерировать слоты'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Сгенерировать слоты'), findsOneWidget);
  });

  testWidgets('can remove a window from the selected day', (tester) async {
    await pumpEditor(tester);

    await tester.tap(
      find.byKey(const Key('availability-remove-window-540-780')),
    );
    await tester.pumpAndSettle();

    expect(find.text('09:00 – 13:00'), findsNothing);
    expect(
      find.text('Нет окон на этот день. Добавьте рабочие часы.'),
      findsOneWidget,
    );
  });

  testWidgets('retry is shown when initial load fails', (tester) async {
    when(
      () => repository.getAvailabilitySettings(),
    ).thenThrow(Exception('offline'));

    await tester.pumpWidget(
      RepositoryProvider<ScheduleRepository>.value(
        value: repository,
        child: const MaterialApp(
          home: Scaffold(body: AvailabilityEditorPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Повторить'), findsOneWidget);
  });
}
