import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/plans/data/plans_repository.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/session_packages/data/session_packages_repository.dart';
import 'package:fitness_app/features/session_workout/presentation/cubit/session_workout_cubit.dart';
import 'package:fitness_app/features/session_workout/presentation/cubit/session_workout_state.dart';
import 'package:fitness_app/features/session_workout/presentation/widgets/confirm_sets_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockPlansRepository extends Mock implements PlansRepository {}

class _MockPackagesRepository extends Mock
    implements SessionPackagesRepository {}

TrainingSession session({
  String id = 's1',
  String status = 'booked',
  String? studentPlanId,
  TrainingPlanItem? plan,
  List<SessionWorkoutAttached> workouts = const [],
}) {
  return TrainingSession(
    id: id,
    coachId: 'coach-1',
    studentId: 'student-1',
    startsAt: '2026-08-18T10:00:00.000Z',
    endsAt: '2026-08-18T11:00:00.000Z',
    status: status,
    createdBy: 'coach',
    studentDisplayName: 'Иван',
    finance: const SessionFinance(status: 'not_tracked'),
    studentPlanId: studentPlanId,
    plan: plan,
    workouts: workouts,
  );
}

TrainingPlanItem copyPlan() {
  return const TrainingPlanItem(
    id: 'copy-1',
    ownerCoachId: 'coach-1',
    title: 'Верх',
    body: '',
    notes: '',
    kind: 'student_copy',
    goal: 'hypertrophy',
    assignedStudentId: 'student-1',
    tags: [PlanTag(id: 't1', name: 'Верх')],
    exercises: [
      PlanExerciseItem(
        exerciseId: 'e1',
        exerciseName: 'Жим',
        exerciseKind: 'weight_reps',
        sets: [PlanSetItem(reps: 10, weightKg: 40)],
      ),
    ],
  );
}

void main() {
  late _MockScheduleRepository schedule;
  late _MockPlansRepository plans;
  late _MockPackagesRepository packages;

  setUp(() {
    schedule = _MockScheduleRepository();
    plans = _MockPlansRepository();
    packages = _MockPackagesRepository();
    when(() => packages.list()).thenAnswer((_) async => const []);
  });

  SessionWorkoutCubit cubit() {
    return SessionWorkoutCubit(
      sessionId: 's1',
      viewerId: 'coach-1',
      permissions: const [
        'sessions:complete',
        'sessions:cancel',
        'sessions:mark_no_show',
        'sessions:read_history',
        'sessions:book_for_student',
        'packages:read_own',
        'plans:create',
        'plans:update_own',
      ],
      schedule: schedule,
      plans: plans,
      packages: packages,
    );
  }

  blocTest<SessionWorkoutCubit, SessionWorkoutState>(
    'грузит занятие без плана',
    build: cubit,
    setUp: () {
      when(() => schedule.getSession('s1')).thenAnswer((_) async => session());
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<SessionWorkoutState>().having(
        (s) => s.status,
        'status',
        SessionWorkoutStatus.loading,
      ),
      isA<SessionWorkoutState>()
          .having((s) => s.status, 'status', SessionWorkoutStatus.ready)
          .having((s) => s.hasPlan, 'hasPlan', false),
    ],
  );

  blocTest<SessionWorkoutCubit, SessionWorkoutState>(
    'добавляет вторую тренировку к занятию',
    build: cubit,
    seed: () => SessionWorkoutState(
      status: SessionWorkoutStatus.ready,
      session: session(
        studentPlanId: 'copy-1',
        plan: copyPlan(),
        workouts: const [
          SessionWorkoutAttached(
            studentPlanId: 'copy-1',
            title: 'Верх',
            goal: 'hypertrophy',
            source: 'manual',
            overridden: false,
          ),
        ],
      ),
    ),
    setUp: () {
      when(
        () => schedule.patchSessionPlan(
          sessionId: 's1',
          workoutPlanIds: ['copy-1', 'copy-2'],
        ),
      ).thenAnswer(
        (_) async => session(studentPlanId: 'copy-1', plan: copyPlan()),
      );
      when(() => schedule.getSession('s1')).thenAnswer(
        (_) async => session(studentPlanId: 'copy-1', plan: copyPlan()),
      );
    },
    act: (c) => c.addCopy('copy-2'),
    verify: (_) {
      verify(
        () => schedule.patchSessionPlan(
          sessionId: 's1',
          workoutPlanIds: ['copy-1', 'copy-2'],
        ),
      ).called(1);
    },
  );

  blocTest<SessionWorkoutCubit, SessionWorkoutState>(
    'привязывает назначенную копию',
    build: cubit,
    seed: () => SessionWorkoutState(
      status: SessionWorkoutStatus.ready,
      session: session(),
    ),
    setUp: () {
      final attached = session(studentPlanId: 'copy-1', plan: copyPlan());
      when(
        () =>
            schedule.patchSessionPlan(sessionId: 's1', studentPlanId: 'copy-1'),
      ).thenAnswer((_) async => attached);
      when(() => schedule.getSession('s1')).thenAnswer((_) async => attached);
    },
    act: (c) => c.attachCopy('copy-1'),
    verify: (_) {
      verify(
        () =>
            schedule.patchSessionPlan(sessionId: 's1', studentPlanId: 'copy-1'),
      ).called(1);
    },
    expect: () => [
      isA<SessionWorkoutState>().having(
        (s) => s.status,
        'status',
        SessionWorkoutStatus.mutating,
      ),
      isA<SessionWorkoutState>()
          .having((s) => s.status, 'status', SessionWorkoutStatus.ready)
          .having((s) => s.hasPlan, 'hasPlan', true)
          .having((s) => s.plan?.title, 'title', 'Верх'),
    ],
  );

  blocTest<SessionWorkoutCubit, SessionWorkoutState>(
    'назначает шаблон и привязывает копию',
    build: cubit,
    seed: () => SessionWorkoutState(
      status: SessionWorkoutStatus.ready,
      session: session(),
    ),
    setUp: () {
      when(
        () => plans.assignPlan(planId: 'tpl-1', studentIds: ['student-1']),
      ).thenAnswer((_) async => [copyPlan()]);
      final attached = session(studentPlanId: 'copy-1', plan: copyPlan());
      when(
        () =>
            schedule.patchSessionPlan(sessionId: 's1', studentPlanId: 'copy-1'),
      ).thenAnswer((_) async => attached);
    },
    act: (c) => c.attachTemplate('tpl-1'),
    verify: (_) {
      verify(
        () => plans.assignPlan(planId: 'tpl-1', studentIds: ['student-1']),
      ).called(1);
      verify(
        () =>
            schedule.patchSessionPlan(sessionId: 's1', studentPlanId: 'copy-1'),
      ).called(1);
    },
    expect: () => [
      isA<SessionWorkoutState>().having(
        (s) => s.status,
        'status',
        SessionWorkoutStatus.mutating,
      ),
      isA<SessionWorkoutState>()
          .having((s) => s.hasPlan, 'hasPlan', true)
          .having((s) => s.infoMessage, 'info', 'Тренировка привязана'),
    ],
  );

  blocTest<SessionWorkoutCubit, SessionWorkoutState>(
    'отвязывает программу от занятия',
    build: cubit,
    seed: () => SessionWorkoutState(
      status: SessionWorkoutStatus.ready,
      session: session(studentPlanId: 'copy-1', plan: copyPlan()),
    ),
    setUp: () {
      final detached = session();
      when(
        () => schedule.patchSessionPlan(sessionId: 's1', studentPlanId: null),
      ).thenAnswer((_) async => detached);
      when(() => schedule.getSession('s1')).thenAnswer((_) async => detached);
    },
    act: (c) => c.detachPlan(),
    verify: (_) {
      verify(
        () => schedule.patchSessionPlan(sessionId: 's1', studentPlanId: null),
      ).called(1);
    },
    expect: () => [
      isA<SessionWorkoutState>().having(
        (s) => s.status,
        'status',
        SessionWorkoutStatus.mutating,
      ),
      isA<SessionWorkoutState>()
          .having((s) => s.hasPlan, 'hasPlan', false)
          .having((s) => s.infoMessage, 'info', 'Программа убрана'),
    ],
  );

  blocTest<SessionWorkoutCubit, SessionWorkoutState>(
    'создаёт ad-hoc копию и привязывает к занятию',
    build: cubit,
    seed: () => SessionWorkoutState(
      status: SessionWorkoutStatus.ready,
      session: session(),
    ),
    setUp: () {
      when(
        () => plans.createPlan(
          title: any(named: 'title'),
          assignedStudentId: 'student-1',
        ),
      ).thenAnswer((_) async => copyPlan());
      final attached = session(studentPlanId: 'copy-1', plan: copyPlan());
      when(
        () =>
            schedule.patchSessionPlan(sessionId: 's1', studentPlanId: 'copy-1'),
      ).thenAnswer((_) async => attached);
    },
    act: (c) => c.ensureAdHocCopy(),
    verify: (_) {
      verify(
        () => plans.createPlan(
          title: 'Занятие · Иван',
          assignedStudentId: 'student-1',
        ),
      ).called(1);
      verify(
        () =>
            schedule.patchSessionPlan(sessionId: 's1', studentPlanId: 'copy-1'),
      ).called(1);
    },
    expect: () => [
      isA<SessionWorkoutState>().having(
        (s) => s.status,
        'status',
        SessionWorkoutStatus.mutating,
      ),
      isA<SessionWorkoutState>().having((s) => s.hasPlan, 'hasPlan', true),
    ],
  );

  blocTest<SessionWorkoutCubit, SessionWorkoutState>(
    'завершает занятие с страницы',
    build: cubit,
    seed: () => SessionWorkoutState(
      status: SessionWorkoutStatus.ready,
      session: session(),
    ),
    setUp: () {
      when(
        () => schedule.completeSession('s1'),
      ).thenAnswer((_) async => session(status: 'completed'));
      when(
        () => schedule.getSession('s1'),
      ).thenAnswer((_) async => session(status: 'completed'));
    },
    act: (c) => c.complete(),
    verify: (_) {
      verify(() => schedule.completeSession('s1')).called(1);
    },
    expect: () => [
      isA<SessionWorkoutState>().having(
        (s) => s.status,
        'status',
        SessionWorkoutStatus.mutating,
      ),
      isA<SessionWorkoutState>().having(
        (s) => s.session?.status,
        'status',
        'completed',
      ),
    ],
  );

  blocTest<SessionWorkoutCubit, SessionWorkoutState>(
    'отправляет скорректированные логи',
    build: cubit,
    seed: () => SessionWorkoutState(
      status: SessionWorkoutStatus.ready,
      session: session(studentPlanId: 'copy-1', plan: copyPlan()),
    ),
    setUp: () {
      when(
        () => schedule.completeSession(
          's1',
          logs: [
            {
              'exerciseId': 'e1',
              'sets': [
                {'reps': 10, 'weightKg': 45.0},
              ],
            },
          ],
        ),
      ).thenAnswer((_) async => session(status: 'completed'));
      when(
        () => schedule.getSession('s1'),
      ).thenAnswer((_) async => session(status: 'completed'));
    },
    act: (c) => c.complete(
      logs: [
        {
          'exerciseId': 'e1',
          'sets': [
            {'reps': 10, 'weightKg': 45.0},
          ],
        },
      ],
    ),
    verify: (_) {
      verify(
        () => schedule.completeSession(
          's1',
          logs: [
            {
              'exerciseId': 'e1',
              'sets': [
                {'reps': 10, 'weightKg': 45.0},
              ],
            },
          ],
        ),
      ).called(1);
    },
  );

  test('sessionLogsFromExercises сериализует подходы', () {
    expect(sessionLogsFromExercises(copyPlan().exercises), [
      {
        'exerciseId': 'e1',
        'sets': [
          {'reps': 10, 'weightKg': 40.0},
        ],
      },
    ]);
  });

  test('PlanSetItem.copyWith умеет сбрасывать вес', () {
    expect(
      const PlanSetItem(
        reps: 10,
        weightKg: 40,
      ).copyWith(weightKg: null).weightKg,
      isNull,
    );
  });
}
