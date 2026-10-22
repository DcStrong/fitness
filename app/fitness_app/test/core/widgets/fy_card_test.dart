import 'package:fitness_app/app/theme/app_colors.dart';
import 'package:fitness_app/app/theme/app_radii.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/widgets/fy_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the shared soft surface and handles taps', (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: FyCard(
            onTap: () => tapCount++,
            child: const Text('Расписание'),
          ),
        ),
      ),
    );

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(FyCard),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(decoration.color, AppColors.surface);
    expect(decoration.borderRadius, BorderRadius.circular(AppRadii.lg));
    expect(decoration.boxShadow, isNotEmpty);

    await tester.tap(find.text('Расписание'));

    expect(tapCount, 1);
  });
}
