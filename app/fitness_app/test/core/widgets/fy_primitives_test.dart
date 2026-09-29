import 'package:fitness_app/core/widgets/fy_bottom_sheet.dart';
import 'package:fitness_app/core/widgets/fy_chip.dart';
import 'package:fitness_app/core/widgets/fy_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FySecondaryButton invokes onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FySecondaryButton(
            label: 'Пропустить',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Пропустить'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('FySecondaryButton disabled does not invoke', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FySecondaryButton(label: 'Пропустить', onPressed: null),
        ),
      ),
    );

    await tester.tap(find.text('Пропустить'));
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('FyChip toggles selection', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return FyChip(
                key: const Key('chip'),
                label: 'Пн',
                selected: selected,
                onSelected: (value) => setState(() => selected = value),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('chip')));
    await tester.pump();
    expect(selected, isTrue);
  });

  testWidgets('showFyBottomSheet presents child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  showFyBottomSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(
                      height: 120,
                      child: Center(child: Text('sheet-body')),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('sheet-body'), findsOneWidget);
  });
}
