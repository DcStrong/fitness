import 'package:fitness_app/features/social/presentation/widgets/specialty_chips.dart';
import 'package:fitness_app/features/social/presentation/widgets/specialty_tags_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<String>> pump(
    WidgetTester tester, [
    List<String>? initial,
  ]) async {
    var tags = <String>[...?initial];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpecialtyTagsField(
              tags: tags,
              onChanged: (value) => tags = value,
            ),
          ),
        ),
      ),
    );
    return tags;
  }

  testWidgets('adds tags by comma and shows counter', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Йога, Силовые,');
    await tester.pump();
    expect(find.byType(InputChip), findsNWidgets(2));
    expect(find.textContaining('2/$maxSpecialtyTags'), findsOneWidget);
  });

  testWidgets('limits tag length and tag count', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'а' * 40);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, maxSpecialtyLength);

    for (var i = 0; i < maxSpecialtyTags; i++) {
      await tester.enterText(find.byType(TextField), 'тег$i,');
      await tester.pump();
    }
    expect(find.byType(InputChip), findsNWidgets(maxSpecialtyTags));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('rejects duplicates', (tester) async {
    await pump(tester, ['Йога']);
    await tester.enterText(find.byType(TextField), 'йога,');
    await tester.pump();
    expect(find.byType(InputChip), findsOneWidget);
    expect(find.text('Такая специализация уже добавлена'), findsOneWidget);
  });

  testWidgets('SpecialtyChips renders full text without truncation', (
    tester,
  ) async {
    const long = 'Функциональный тренинг для восстановления';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: SpecialtyChips(specialties: [long, 'Йога']),
          ),
        ),
      ),
    );
    expect(find.text(long), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(2));
  });
}
