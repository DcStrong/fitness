import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/features/invitations/data/invitation_models.dart';
import 'package:fitness_app/features/invitations/data/invitations_repository.dart';
import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/plans/data/plans_repository.dart';
import 'package:fitness_app/features/plans/presentation/cubit/tag_hub_cubit.dart';
import 'package:fitness_app/features/plans/presentation/cubit/tag_hub_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlansRepository extends Mock implements PlansRepository {}

class _MockInvitationsRepository extends Mock
    implements InvitationsRepository {}

void main() {
  late _MockPlansRepository plans;
  late _MockInvitationsRepository invitations;

  setUp(() {
    plans = _MockPlansRepository();
    invitations = _MockInvitationsRepository();
    when(() => plans.getTagHub('tag-1')).thenAnswer(
      (_) async => const TagHub(
        tag: TagItem(id: 'tag-1', name: 'ноги', creatorId: 'c1'),
        users: [TagAssignee(userId: 's1', assignedAt: '2026-08-18')],
        plans: [TagHubPlan(id: 'p1', title: 'Низ')],
        exercises: [
          TagHubExercise(
            id: 'e1',
            name: 'Присед',
            kind: 'weight_reps',
            source: 'catalog',
          ),
        ],
      ),
    );
    when(() => invitations.listRelationships()).thenAnswer(
      (_) async => const [
        RelationshipItem(
          id: 'r1',
          coachId: 'c1',
          studentId: 's1',
          roleForViewer: 'coach',
          studentDisplayName: 'Иван',
        ),
      ],
    );
    when(() => plans.listOwnPlans()).thenAnswer((_) async => const []);
    when(() => plans.listExercises()).thenAnswer((_) async => const []);
  });

  blocTest<TagHubCubit, TagHubState>(
    'грузит учеников, тренировки и упражнения тега',
    build: () =>
        TagHubCubit(plans: plans, invitations: invitations, tagId: 'tag-1'),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<TagHubState>().having(
        (s) => s.status,
        'status',
        TagHubStatus.loading,
      ),
      isA<TagHubState>()
          .having((s) => s.status, 'status', TagHubStatus.success)
          .having((s) => s.hub?.plans, 'plans', hasLength(1))
          .having((s) => s.hub?.exercises, 'exercises', hasLength(1))
          .having((s) => s.hub?.users, 'users', hasLength(1)),
    ],
  );

  blocTest<TagHubCubit, TagHubState>(
    'назначает тег ученику и перечитывает хаб',
    build: () {
      when(() => plans.assignTag(tagId: 'tag-1', userId: 's2')).thenAnswer(
        (_) async => const TagAssignee(userId: 's2', assignedAt: '2026-08-18'),
      );
      return TagHubCubit(
        plans: plans,
        invitations: invitations,
        tagId: 'tag-1',
      );
    },
    seed: () => const TagHubState(status: TagHubStatus.success),
    act: (cubit) => cubit.assignStudents(['s2']),
    verify: (_) {
      verify(() => plans.assignTag(tagId: 'tag-1', userId: 's2')).called(1);
      verify(() => plans.getTagHub('tag-1')).called(1);
    },
  );
}
