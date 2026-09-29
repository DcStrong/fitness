import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/plans/data/plans_repository.dart';
import 'package:fitness_app/features/plans/presentation/cubit/tags_cubit.dart';
import 'package:fitness_app/features/plans/presentation/cubit/tags_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlans extends Mock implements PlansRepository {}

void main() {
  late _MockPlans plans;

  setUp(() {
    plans = _MockPlans();
    when(() => plans.listTags()).thenAnswer(
      (_) async => const [TagItem(id: 't1', name: 'Алина', creatorId: 'c1')],
    );
  });

  blocTest<TagsCubit, TagsState>(
    'создаёт тег из поисковой строки',
    build: () {
      when(() => plans.createTag('Ноги')).thenAnswer(
        (_) async => const TagItem(id: 't2', name: 'Ноги', creatorId: 'c1'),
      );
      return TagsCubit(plans: plans);
    },
    seed: () => const TagsState(
      status: TagsStatus.ready,
      tags: [TagItem(id: 't1', name: 'Алина', creatorId: 'c1')],
      query: 'Ноги',
    ),
    act: (cubit) => cubit.createFromQuery(),
    expect: () => [
      isA<TagsState>()
          .having((s) => s.tags.map((t) => t.name), 'names', ['Ноги', 'Алина'])
          .having((s) => s.query, 'query', 'Ноги'),
    ],
  );
}
