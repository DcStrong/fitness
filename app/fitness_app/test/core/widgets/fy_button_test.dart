import 'package:fitness_app/app/theme/app_colors.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/widgets/fy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );

  testWidgets('primary large is stadium pill at 54', (tester) async {
    await tester.pumpWidget(
      wrap(FyButton.primary(label: 'Войти', onPressed: () {})),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(tester.getSize(find.byType(FilledButton)).height, 54);
    expect(button.style?.shape?.resolve(<WidgetState>{}), isA<StadiumBorder>());
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.primary,
    );
  });

  testWidgets('medium card actions are 44 and keep pill shape', (tester) async {
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            FyButton.primary(
              label: 'Принять',
              icon: Icons.check_rounded,
              size: FyButtonSize.medium,
              onPressed: () {},
            ),
            FyButton.secondary(
              label: 'Другое время',
              size: FyButtonSize.medium,
              onPressed: () {},
            ),
            FyButton.danger(
              label: 'Отклонить',
              size: FyButtonSize.medium,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byType(FilledButton)).height, 44);
    expect(tester.getSize(find.byType(OutlinedButton).first).height, 44);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Отклонить'), findsOneWidget);
  });

  testWidgets('loading blocks taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        FyButton.primary(
          label: 'Войти',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
