import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/plans/data/plans_repository.dart';
import 'package:fitness_app/features/plans/presentation/screens/tags_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlansRepository extends Mock implements PlansRepository {}

void main() {
  late _MockPlansRepository plans;

  setUp(() {
    plans = _MockPlansRepository();
    when(() => plans.listTags()).thenAnswer(
      (_) async => const [TagItem(id: 't1', name: 'Алина', creatorId: 'c1')],
    );
  });

  testWidgets('поиск показывает создание нового тега', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<PlansRepository>.value(
        value: plans,
        child: MaterialApp(theme: AppTheme.light(), home: const TagsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Алина'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('tags-search')), 'Ноги');
    await tester.pump();

    expect(find.text('Создать «Ноги» и привязать'), findsOneWidget);
    expect(find.text('Алина'), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });
}
