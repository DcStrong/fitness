import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/features/invitations/data/invitation_models.dart';
import 'package:fitness_app/features/invitations/data/invitations_repository.dart';
import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/plans/data/plans_repository.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/session_packages/data/session_package_models.dart';
import 'package:fitness_app/features/session_packages/data/session_packages_repository.dart';
import 'package:fitness_app/features/student_hub/data/progress_models.dart';
import 'package:fitness_app/features/student_hub/data/progress_repository.dart';
import 'package:fitness_app/features/student_hub/presentation/cubit/student_hub_cubit.dart';
import 'package:fitness_app/features/student_hub/presentation/cubit/student_hub_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSchedule extends Mock implements ScheduleRepository {}

class _MockPlans extends Mock implements PlansRepository {}

class _MockPackages extends Mock implements SessionPackagesRepository {}

class _MockProgress extends Mock implements ProgressRepository {}

class _MockInvitations extends Mock implements InvitationsRepository {}

TrainingSession booked() {
  return const TrainingSession(
    id: 's1',
    coachId: 'coach-1',
    studentId: 'student-1',
    startsAt: '2026-08-20T10:00:00.000Z',
    endsAt: '2026-08-20T11:00:00.000Z',
    status: 'booked',
    createdBy: 'coach',
    finance: SessionFinance(status: 'not_tracked'),
    planTitle: 'Жим',
  );
}

TrainingPlanItem assigned() {
  return const TrainingPlanItem(
    id: 'copy-1',
    ownerCoachId: 'coach-1',
    title: 'Жим',
    body: '',
    notes: '',
    kind: 'student_copy',
    goal: 'hypertrophy',
    assignedStudentId: 'student-1',
    tags: [],
    exercises: [
      PlanExerciseItem(
        exerciseId: 'e1',
        exerciseName: 'Жим лёжа',
        exerciseKind: 'weight_reps',
      ),
    ],
  );
}

void main() {
  late _MockSchedule schedule;
  late _MockPlans plans;
  late _MockPackages packages;
  late _MockProgress progress;
  late _MockInvitations invitations;

  setUp(() {
    schedule = _MockSchedule();
    plans = _MockPlans();
    packages = _MockPackages();
    progress = _MockProgress();
    invitations = _MockInvitations();
    when(
      () => schedule.listSessions(
        status: any(named: 'status'),
        from: any(named: 'from'),
        studentId: any(named: 'studentId'),
      ),
    ).thenAnswer((_) async => [booked()]);
    when(
      () => plans.listAssignedPlans(studentId: any(named: 'studentId')),
    ).thenAnswer((_) async => [assigned()]);
    when(() => packages.list()).thenAnswer((_) async => const []);
    when(
      () => schedule.listRecurringBookings(),
    ).thenAnswer((_) async => const []);
    when(() => invitations.listRelationships()).thenAnswer((_) async => []);
    when(
      () => progress.listExercises(studentId: any(named: 'studentId')),
    ).thenAnswer(
      (_) async => const [
        ProgressExerciseSummary(
          exerciseId: 'e1',
          name: 'Жим лёжа',
          sessionCount: 2,
        ),
      ],
    );
    when(
      () => progress.getSeries(
        studentId: any(named: 'studentId'),
        exerciseId: any(named: 'exerciseId'),
      ),
    ).thenAnswer(
      (_) async => const ProgressSeries(
        exerciseId: 'e1',
        goal: 'hypertrophy',
        points: [
          ProgressPoint(
            sessionId: 's1',
            completedAt: '2026-08-01T10:00:00.000Z',
            weightKg: 40,
            volume: 400,
          ),
          ProgressPoint(
            sessionId: 's2',
            completedAt: '2026-08-08T10:00:00.000Z',
            weightKg: 50,
            volume: 400,
          ),
        ],
      ),
    );
  });

  StudentHubCubit hub() {
    return StudentHubCubit(
      studentId: 'student-1',
      viewerId: 'coach-1',
      isTrainer: true,
      schedule: schedule,
      plans: plans,
      packages: packages,
      progress: progress,
      invitations: invitations,
    );
  }

  blocTest<StudentHubCubit, StudentHubState>(
    'собирает ближайшие, копии, пакет и прогресс',
    build: hub,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<StudentHubState>().having(
        (s) => s.status,
        'status',
        StudentHubStatus.loading,
      ),
      isA<StudentHubState>()
          .having((s) => s.status, 'status', StudentHubStatus.ready)
          .having((s) => s.upcoming, 'upcoming', hasLength(1))
          .having((s) => s.assigned, 'assigned', hasLength(1))
          .having((s) => s.series?.points, 'points', hasLength(2))
          .having((s) => s.series?.delta, 'delta', 10),
    ],
  );

  blocTest<StudentHubCubit, StudentHubState>(
    'пустой прогресс остаётся пустым',
    build: hub,
    setUp: () {
      when(
        () => progress.listExercises(studentId: any(named: 'studentId')),
      ).thenAnswer((_) async => const []);
      when(
        () => progress.getSeries(
          studentId: any(named: 'studentId'),
          exerciseId: any(named: 'exerciseId'),
        ),
      ).thenAnswer(
        (_) async => const ProgressSeries(exerciseId: 'e1', points: []),
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<StudentHubState>().having(
        (s) => s.status,
        'status',
        StudentHubStatus.loading,
      ),
      isA<StudentHubState>()
          .having((s) => s.status, 'status', StudentHubStatus.ready)
          .having((s) => s.series?.points, 'points', isEmpty),
    ],
  );

  test('weekSlotsFromSessions берёт только текущую неделю', () {
    final monday = DateTime(2026, 8, 17, 12);
    final slots = weekSlotsFromSessions([
      booked(),
      const TrainingSession(
        id: 's-old',
        coachId: 'coach-1',
        studentId: 'student-1',
        startsAt: '2026-08-10T10:00:00.000Z',
        endsAt: '2026-08-10T11:00:00.000Z',
        status: 'booked',
        createdBy: 'coach',
        finance: SessionFinance(status: 'not_tracked'),
        planTitle: 'Старое',
      ),
    ], now: monday);
    expect(slots, hasLength(1));
    expect(slots.first.title, 'Жим');
  });

  test('pickStudentPackage предпочитает активный пакет ученика', () {
    SessionPackage pkg({
      required String id,
      required String studentId,
      required String status,
    }) {
      return SessionPackage(
        id: id,
        coachId: 'c1',
        studentId: studentId,
        totalSessions: 8,
        remainingSessions: 3,
        status: status,
        createdAt: '2026-08-01T00:00:00.000Z',
        updatedAt: '2026-08-01T00:00:00.000Z',
      );
    }

    final picked = pickStudentPackage([
      pkg(id: 'other', studentId: 's2', status: 'active'),
      pkg(id: 'old', studentId: 'student-1', status: 'exhausted'),
      pkg(id: 'ok', studentId: 'student-1', status: 'active'),
    ], 'student-1');
    expect(picked?.id, 'ok');
  });

  blocTest<StudentHubCubit, StudentHubState>(
    'имя ученика берётся из связи, если нет ближайших занятий',
    build: hub,
    setUp: () {
      when(
        () => schedule.listSessions(
          status: any(named: 'status'),
          from: any(named: 'from'),
          studentId: any(named: 'studentId'),
        ),
      ).thenAnswer((_) async => []);
      when(() => invitations.listRelationships()).thenAnswer(
        (_) async => const [
          RelationshipItem(
            id: 'r1',
            coachId: 'coach-1',
            studentId: 'student-1',
            roleForViewer: 'coach',
            studentDisplayName: 'Алина Козлова',
          ),
        ],
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<StudentHubState>().having(
        (s) => s.status,
        'status',
        StudentHubStatus.loading,
      ),
      isA<StudentHubState>()
          .having((s) => s.status, 'status', StudentHubStatus.ready)
          .having((s) => s.studentDisplayName, 'name', 'Алина Козлова'),
    ],
  );
}
