import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/features/plans/data/plans_format.dart';
import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/plans/data/plans_repository.dart';
import 'package:fitness_app/features/plans/presentation/cubit/plan_editor_cubit.dart';
import 'package:fitness_app/features/plans/presentation/cubit/plan_editor_state.dart';
import 'package:fitness_app/features/plans/presentation/cubit/plans_library_cubit.dart';
import 'package:fitness_app/features/plans/presentation/cubit/plans_library_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlansRepository extends Mock implements PlansRepository {}

TrainingPlanItem plan({
  String id = 'p1',
  String title = 'Верх',
  String kind = 'template',
  String goal = 'hypertrophy',
}) {
  return TrainingPlanItem(
    id: id,
    ownerCoachId: 'c1',
    title: title,
    body: '',
    notes: '',
    kind: kind,
    goal: goal,
    tags: const [PlanTag(id: 't1', name: 'Верх')],
    exercises: const [
      PlanExerciseItem(
        exerciseId: 'e1',
        exerciseName: 'Жим',
        exerciseKind: 'weight_reps',
        restSeconds: 90,
        sets: [
          PlanSetItem(reps: 10, weightKg: 20),
          PlanSetItem(reps: 10, weightKg: 20),
          PlanSetItem(reps: 10, weightKg: 20),
        ],
      ),
    ],
  );
}

void main() {
  group('formatSetsCompact', () {
    test('сворачивает одинаковые подходы в 3×12', () {
      final summary = formatSetsCompact(
        kind: 'weight_reps',
        sets: identicalSets(
          count: 3,
          kind: 'weight_reps',
          reps: 12,
          weightKg: 20,
        ),
        restSeconds: 90,
      );
      expect(summary, '3×12 · 20 кг · отдых 90с');
    });
  });

  group('PlansLibraryCubit', () {
    late _MockPlansRepository repository;

    setUp(() {
      repository = _MockPlansRepository();
      when(() => repository.listTags()).thenAnswer((_) async => const []);
      when(() => repository.listOwnPlans()).thenAnswer((_) async => [plan()]);
      when(
        () => repository.listCatalogPlans(),
      ).thenAnswer((_) async => [plan(id: 'c1', kind: 'catalog_seed')]);
      when(() => repository.listExercises()).thenAnswer(
        (_) async => const [
          ExerciseItem(
            id: 'e1',
            name: 'Присед',
            kind: 'weight_reps',
            source: 'catalog',
          ),
        ],
      );
      when(
        () => repository.clonePlan(any()),
      ).thenAnswer((_) async => plan(id: 'cloned'));
      when(
        () => repository.assignPlansBatch(
          studentId: any(named: 'studentId'),
          planIds: any(named: 'planIds'),
        ),
      ).thenAnswer((_) async => [plan(id: 'copy-1', kind: 'student_copy')]);
    });

    blocTest<PlansLibraryCubit, PlansLibraryState>(
      'грузит «Мои», затем отдельно «База»',
      build: () => PlansLibraryCubit(repository: repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.setMode(PlansLibraryMode.catalog);
      },
      verify: (_) {
        verify(() => repository.listOwnPlans()).called(1);
        verify(() => repository.listCatalogPlans()).called(1);
      },
      expect: () => [
        isA<PlansLibraryState>().having(
          (s) => s.status,
          'status',
          PlansLibraryStatus.loading,
        ),
        isA<PlansLibraryState>().having(
          (s) => s.plans.first.kind,
          'kind',
          'template',
        ),
        isA<PlansLibraryState>().having(
          (s) => s.mode,
          'mode',
          PlansLibraryMode.catalog,
        ),
        isA<PlansLibraryState>().having(
          (s) => s.status,
          'status',
          PlansLibraryStatus.loading,
        ),
        isA<PlansLibraryState>().having(
          (s) => s.plans.first.kind,
          'kind',
          'catalog_seed',
        ),
      ],
    );

    blocTest<PlansLibraryCubit, PlansLibraryState>(
      'грузит упражнения отдельно от шаблонов',
      build: () => PlansLibraryCubit(repository: repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.setMode(PlansLibraryMode.exercises);
      },
      verify: (_) {
        verify(() => repository.listExercises()).called(1);
      },
      expect: () => [
        isA<PlansLibraryState>().having(
          (s) => s.status,
          'status',
          PlansLibraryStatus.loading,
        ),
        isA<PlansLibraryState>().having(
          (s) => s.plans.first.kind,
          'kind',
          'template',
        ),
        isA<PlansLibraryState>().having(
          (s) => s.mode,
          'mode',
          PlansLibraryMode.exercises,
        ),
        isA<PlansLibraryState>().having(
          (s) => s.status,
          'status',
          PlansLibraryStatus.loading,
        ),
        isA<PlansLibraryState>().having(
          (s) => s.exercises.first.name,
          'exercise',
          'Присед',
        ),
      ],
    );

    blocTest<PlansLibraryCubit, PlansLibraryState>(
      'назначает выбранные шаблоны одному ученику',
      build: () => PlansLibraryCubit(repository: repository),
      seed: () => PlansLibraryState(
        status: PlansLibraryStatus.success,
        selecting: true,
        selectedPlanIds: {'p1', 'p2'},
        plans: [
          plan(),
          plan(id: 'p2', title: 'Низ'),
        ],
      ),
      act: (cubit) => cubit.assignSelectedPlans('student-1'),
      verify: (_) {
        verify(
          () => repository.assignPlansBatch(
            studentId: 'student-1',
            planIds: any(named: 'planIds'),
          ),
        ).called(1);
      },
    );

    blocTest<PlansLibraryCubit, PlansLibraryState>(
      'применяет теги из шита поиска',
      build: () => PlansLibraryCubit(repository: repository),
      seed: () => const PlansLibraryState(
        status: PlansLibraryStatus.success,
        selectedTagIds: {'t1'},
      ),
      act: (cubit) => cubit.replaceSelectedTags({'t2', 't3'}),
      expect: () => [
        isA<PlansLibraryState>().having(
          (s) => s.selectedTagIds,
          'tags',
          {'t2', 't3'},
        ),
      ],
    );

    blocTest<PlansLibraryCubit, PlansLibraryState>(
      'клонирует каталожный шаблон',
      build: () => PlansLibraryCubit(repository: repository),
      seed: () => PlansLibraryState(
        status: PlansLibraryStatus.success,
        mode: PlansLibraryMode.catalog,
        plans: [plan(id: 'cat', kind: 'catalog_seed')],
      ),
      act: (cubit) => cubit.clonePlan('cat'),
      verify: (_) {
        verify(() => repository.clonePlan('cat')).called(1);
      },
    );
  });

  group('PlanEditorCubit', () {
    late _MockPlansRepository repository;

    setUp(() {
      repository = _MockPlansRepository();
      when(() => repository.listTags()).thenAnswer((_) async => const []);
      when(() => repository.listExercises()).thenAnswer((_) async => const []);
    });

    blocTest<PlanEditorCubit, PlanEditorState>(
      'не сохраняет шаблон без названия',
      build: () => PlanEditorCubit(repository: repository),
      act: (cubit) => cubit.save(),
      expect: () => [
        isA<PlanEditorState>().having(
          (s) => s.validationMessage,
          'validation',
          'Укажите название',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => repository.createPlan(
            title: any(named: 'title'),
            notes: any(named: 'notes'),
            body: any(named: 'body'),
            goal: any(named: 'goal'),
            tagIds: any(named: 'tagIds'),
            exercises: any(named: 'exercises'),
          ),
        );
      },
    );

    test('добавляет упражнение с дефолтами цели hypertrophy 3×10', () async {
      final cubit = PlanEditorCubit(repository: repository);
      cubit.setGoal('hypertrophy');
      cubit.addExercise(
        const ExerciseItem(
          id: 'e1',
          name: 'Жим',
          kind: 'weight_reps',
          source: 'catalog',
        ),
      );
      expect(cubit.state.exercises, hasLength(1));
      expect(cubit.state.exercises.first.sets, hasLength(3));
      expect(cubit.state.exercises.first.sets.first.reps, 10);
      expect(cubit.state.exercises.first.restSeconds, 90);
      expect(
        formatPlanExerciseRow(cubit.state.exercises.first),
        '3×10 · отдых 90с',
      );
      await cubit.close();
    });
  });
}
