import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/schedule/domain/calendar_events.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/open_slot_actions_sheet.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/schedule_create_actions_sheet.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/weekday_multi_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('create actions sheet returns book student', (tester) async {
    ScheduleCreateAction? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await ScheduleCreateActionsSheet.show(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Записать ученика'), findsOneWidget);
    expect(find.text('Регулярные тренировки'), findsOneWidget);
    expect(find.text('Свободное время'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-action-book-student')));
    await tester.pumpAndSettle();
    expect(result, ScheduleCreateAction.bookStudent);
  });

  testWidgets('open slot sheet offers book and delete', (tester) async {
    final event = CalendarEvent(
      id: 'slot:1',
      type: CalendarEventType.availability,
      startsAt: DateTime(2026, 8, 4, 10),
      endsAt: DateTime(2026, 8, 4, 11),
      title: 'Свободное время',
      secondaryLabel: 'очно',
      mode: 'offline',
      slotId: 'slot-1',
    );

    OpenSlotAction? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<OpenSlotAction>(
                  context: context,
                  builder: (_) => OpenSlotActionsSheet(event: event),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('slot-action-book')));
    await tester.pumpAndSettle();
    expect(result, OpenSlotAction.bookStudent);
  });

  test('mode_mismatch has Russian label', () {
    expect(
      recurringConflictReasonLabel('mode_mismatch'),
      'Другой формат слота',
    );
  });
}
