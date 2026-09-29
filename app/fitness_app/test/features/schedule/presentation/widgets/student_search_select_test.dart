import 'package:fitness_app/core/widgets/fy_search_select_field.dart';
import 'package:fitness_app/features/invitations/data/invitation_models.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/student_search_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('studentLabel prefers displayName over email', () {
    const item = RelationshipItem(
      id: 'r1',
      coachId: 'c1',
      studentId: 's1',
      roleForViewer: 'coach',
      studentEmail: 'olga.demo@mail.ru',
      studentDisplayName: 'Ольга Демо',
    );
    expect(item.studentLabel, 'Ольга Демо');
  });

  test('studentSearchSelectOptions expose email as subtitle when named', () {
    final options = studentSearchSelectOptions([
      const RelationshipItem(
        id: 'r1',
        coachId: 'c1',
        studentId: 's1',
        roleForViewer: 'coach',
        studentEmail: 'olga.demo@mail.ru',
        studentDisplayName: 'Ольга Демо',
      ),
    ]);
    expect(options.single.label, 'Ольга Демо');
    expect(options.single.subtitle, 'olga.demo@mail.ru');
  });

  testWidgets('FySearchSelectField filters by query', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FySearchSelectField<String>(
            fieldKey: const Key('student-select'),
            label: 'Ученик',
            value: null,
            options: const [
              FySearchSelectOption(
                value: '1',
                label: 'Ольга Демо',
                subtitle: 'olga.demo@mail.ru',
                searchText: 'olga.demo@mail.ru',
              ),
              FySearchSelectOption(
                value: '2',
                label: 'Иван Петров',
                subtitle: 'ivan@mail.ru',
                searchText: 'ivan@mail.ru',
              ),
            ],
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('student-select')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('fy-search-select-query')),
      'иван',
    );
    await tester.pumpAndSettle();

    expect(find.text('Иван Петров'), findsOneWidget);
    expect(find.text('Ольга Демо'), findsNothing);

    await tester.tap(find.text('Иван Петров'));
    await tester.pumpAndSettle();
    expect(selected, '2');
  });
}
