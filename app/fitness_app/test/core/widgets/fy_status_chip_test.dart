import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/widgets/fy_avatar.dart';
import 'package:fitness_app/core/widgets/fy_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('status chip always shows an icon and a word', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              FyStatusChip(status: FyStatus.waiting),
              FyStatusChip(status: FyStatus.noShow, label: 'Пропуск'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Ждёт ответа'), findsOneWidget);
    expect(find.text('Пропуск'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  test('initials prefer the name and fall back to the email', () {
    expect(personInitials(displayName: 'Мария Соколова'), 'МС');
    expect(personInitials(displayName: 'Ольга'), 'О');
    expect(personInitials(email: 'anna.demo@mail.ru'), 'AN');
    expect(personInitials(), '?');
  });
}
