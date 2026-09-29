import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/plans/data/plans_repository.dart';
import 'package:fitness_app/features/schedule/data/recurring_booking_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/workout_program/data/workout_program_models.dart';
import 'package:fitness_app/features/workout_program/presentation/cubit/workout_program_cubit.dart';
import 'package:fitness_app/features/workout_program/presentation/cubit/workout_program_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSchedule extends Mock implements ScheduleRepository {}

class _MockPlans extends Mock implements PlansRepository {}

RecurringBooking booking() {
  return RecurringBooking.fromJson(const {
    'id': 'rb1',
    'coachId': 'c1',
    'studentId': 's1',
    'studentDisplayName': 'Иван',
    'weekdays': [1, 6],
    'startMinute': 780,
    'mode': 'offline',
    'timezone': 'Europe/Moscow',
    'status': 'active',
    'horizonWeeksOverride': null,
    'createdAt': '2026-08-04T00:00:00.000Z',
    'updatedAt': '2026-08-04T00:00:00.000Z',
    'cancelledAt': null,
  });
}

TrainingPlanItem template() {
  return const TrainingPlanItem(
    id: 'tpl-1',
    ownerCoachId: 'c1',
    title: 'Силовая',
    body: '',
    notes: '',
    kind: 'template',
    goal: 'hypertrophy',
    tags: [],
    exercises: [
      PlanExerciseItem(
        exerciseId: 'e1',
        exerciseName: 'Жим',
        exerciseKind: 'weight_reps',
        sets: [PlanSetItem(reps: 8, weightKg: 80)],
      ),
    ],
  );
}

WorkoutProgram savedProgram() {
  return WorkoutProgram.fromJson(const {
    'id': 'p1',
    'recurringBookingId': 'rb1',
    'studentId': 's1',
    'horizonWeeks': 2,
    'days': [
      {
        'weekday': 1,
        'items': [
          {
            'templateId': 'tpl-1',
            'studentPlanId': 'copy-1',
            'title': 'Силовая',
            'sortOrder': 0,
          },
        ],
      },
      {
        'weekday': 6,
        'items': [
          {
            'templateId': 'tpl-1',
            'studentPlanId': 'copy-1',
            'title': 'Силовая',
            'sortOrder': 0,
          },
        ],
      },
    ],
    'progressionRules': [
      {
        'exerciseId': 'e1',
        'startWeightKg': 80,
        'deltaKg': 5,
        'incrementKg': 2.5,
        'holdOnMiss': true,
      },
    ],
    'preview': [],
  });
}

void main() {
  late _MockSchedule schedule;
  late _MockPlans plans;

  setUpAll(() {
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<({String exerciseId, double weightKg})>[]);
  });

  setUp(() {
    schedule = _MockSchedule();
    plans = _MockPlans();
    when(
      () => schedule.getRecurringBooking('rb1'),
    ).thenAnswer((_) async => booking());
    when(
      () => schedule.getWorkoutProgram('rb1'),
    ).thenAnswer((_) async => savedProgram());
    when(() => plans.listOwnPlans()).thenAnswer((_) async => [template()]);
    when(() => plans.getPlan(any())).thenAnswer((_) async => template());
    when(
      () => plans.updatePlanLoads(
        id: any(named: 'id'),
        items: any(named: 'items'),
      ),
    ).thenAnswer((_) async => template());
  });

  WorkoutProgramCubit cubit() {
    return WorkoutProgramCubit(
      recurringBookingId: 'rb1',
      schedule: schedule,
      plans: plans,
    );
  }

  blocTest<WorkoutProgramCubit, WorkoutProgramState>(
    'блокирует сохранение, если день серии пустой',
    build: cubit,
    seed: () => WorkoutProgramState(
      status: WorkoutProgramStatus.ready,
      booking: booking(),
      days: {
        1: const [ProgramDayDraftItem(templateId: 'tpl-1', title: 'Силовая')],
        6: const [],
      },
    ),
    act: (c) => c.save(),
    verify: (_) {
      verifyNever(
        () => schedule.putWorkoutProgram(
          recurringBookingId: any(named: 'recurringBookingId'),
          horizonWeeks: any(named: 'horizonWeeks'),
          days: any(named: 'days'),
          progressionRules: any(named: 'progressionRules'),
        ),
      );
    },
    expect: () => [
      isA<WorkoutProgramState>().having(
        (s) => s.validationMessage,
        'validation',
        'Добавьте тренировку в каждый день серии',
      ),
    ],
  );

  blocTest<WorkoutProgramCubit, WorkoutProgramState>(
    'сохраняет два weekday и дельту жима',
    build: cubit,
    seed: () => WorkoutProgramState(
      status: WorkoutProgramStatus.ready,
      booking: booking(),
      horizonWeeks: 2,
      days: const {
        1: [ProgramDayDraftItem(templateId: 'tpl-1', title: 'Силовая')],
        6: [ProgramDayDraftItem(templateId: 'tpl-1', title: 'Силовая')],
      },
      rules: const [
        ProgramRuleDraft(
          exerciseId: 'e1',
          exerciseName: 'Жим',
          startWeightKg: 80,
          deltaKg: 5,
        ),
      ],
      plansById: {},
    ),
    setUp: () {
      when(
        () => schedule.putWorkoutProgram(
          recurringBookingId: 'rb1',
          horizonWeeks: 2,
          days: any(named: 'days'),
          progressionRules: any(named: 'progressionRules'),
        ),
      ).thenAnswer((_) async => savedProgram());
    },
    act: (c) => c.save(),
    verify: (_) {
      final captured = verify(
        () => schedule.putWorkoutProgram(
          recurringBookingId: 'rb1',
          horizonWeeks: 2,
          days: captureAny(named: 'days'),
          progressionRules: captureAny(named: 'progressionRules'),
        ),
      ).captured;
      expect(captured[0], hasLength(2));
      expect(captured[1], [
        {'exerciseId': 'e1', 'startWeightKg': 80.0, 'deltaKg': 5.0},
      ]);
    },
  );
}
