import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/widgets/fy_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light(), home: child);

  testWidgets('FyTopBar shows title and subtitle without actions bell', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(
          appBar: FyTopBar(title: 'Расписание', subtitle: 'Сегодня'),
          body: SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Расписание'), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    expect(find.byIcon(Icons.notifications), findsNothing);
  });

  testWidgets('FyTopBar supports leading back', (tester) async {
    var popped = false;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          appBar: FyTopBar(
            title: 'Назад',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popped = true,
            ),
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(popped, isTrue);
  });
}
