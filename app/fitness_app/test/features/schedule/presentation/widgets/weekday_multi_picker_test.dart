import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/weekday_multi_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WeekdayMultiPicker toggles chips', (tester) async {
    var selected = <int>{1, 3};
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: WeekdayMultiPicker(
            selectedWeekdays: selected,
            onChanged: (next) => selected = next,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('recurring-dow-1')), findsOneWidget);
    expect(find.byKey(const Key('recurring-dow-5')), findsOneWidget);

    await tester.tap(find.byKey(const Key('recurring-dow-5')));
    await tester.pump();
    expect(selected.contains(5), isTrue);

    await tester.tap(find.byKey(const Key('recurring-dow-1')));
    await tester.pump();
    expect(selected.contains(1), isFalse);
  });

  test('format helpers', () {
    expect(formatWeekdays([5, 1, 3]), 'Пн, Ср, Пт');
    expect(formatStartMinute(18 * 60 + 5), '18:05');
    expect(recurringConflictReasonLabel('missing_slot'), 'Нет слота');
  });
}
