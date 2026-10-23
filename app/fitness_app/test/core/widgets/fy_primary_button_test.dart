import 'package:fitness_app/app/theme/app_colors.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/widgets/fy_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    VoidCallback? onPressed,
    bool isLoading = false,
    bool showTrailingArrow = false,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FyPrimaryButton(
            label: 'Войти',
            onPressed: onPressed,
            isLoading: isLoading,
            showTrailingArrow: showTrailingArrow,
          ),
        ),
      ),
    );
  }

  testWidgets('renders branded full-width action and handles tap', (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      buildSubject(onPressed: () => tapCount++, showTrailingArrow: true),
    );

    final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(find.text('Войти'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)).height, 52);
    expect(
      filledButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.primary,
    );

    await tester.tap(find.byType(FilledButton));

    expect(tapCount, 1);
  });

  testWidgets('shows progress and blocks taps while loading', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      buildSubject(
        onPressed: () => tapCount++,
        isLoading: true,
        showTrailingArrow: true,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Войти'), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    final loadingButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(
      loadingButton.style?.backgroundColor?.resolve({WidgetState.disabled}),
      AppColors.primary,
    );

    await tester.tap(find.byType(FilledButton));

    expect(tapCount, 0);
  });

  testWidgets('is disabled when callback is absent', (tester) async {
    await tester.pumpWidget(buildSubject());

    final button = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button.onPressed, isNull);
  });
}
