import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/session_workout/presentation/cubit/session_workout_cubit.dart';
import 'package:fitness_app/features/session_workout/presentation/cubit/session_workout_state.dart';
import 'package:fitness_app/features/session_workout/presentation/session_workout_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCubit extends MockCubit<SessionWorkoutState>
    implements SessionWorkoutCubit {}

TrainingSession twoWorkouts() {
  return TrainingSession(
    id: 's1',
    coachId: 'coach-1',
    studentId: 'student-1',
    startsAt: '2026-08-18T10:00:00.000Z',
    endsAt: '2026-08-18T11:00:00.000Z',
    status: 'booked',
    createdBy: 'coach',
    studentDisplayName: 'Иван',
    finance: const SessionFinance(status: 'not_tracked'),
    studentPlanId: 'copy-1',
    workouts: const [
      SessionWorkoutAttached(
        studentPlanId: 'copy-1',
        title: 'Силовая',
        goal: 'hypertrophy',
        source: 'program',
        overridden: false,
        exercises: [
          PlanExerciseItem(
            exerciseId: 'e1',
            exerciseName: 'Жим',
            exerciseKind: 'weight_reps',
            sets: [PlanSetItem(reps: 8, weightKg: 80)],
          ),
        ],
      ),
      SessionWorkoutAttached(
        studentPlanId: 'copy-2',
        title: 'Ноги',
        goal: 'hypertrophy',
        source: 'program',
        overridden: false,
        exercises: [
          PlanExerciseItem(
            exerciseId: 'e2',
            exerciseName: 'Присед',
            exerciseKind: 'weight_reps',
            sets: [PlanSetItem(reps: 8, weightKg: 100)],
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('страница занятия показывает две тренировки', (tester) async {
    final cubit = _MockCubit();
    final session = twoWorkouts();
    whenListen(
      cubit,
      const Stream<SessionWorkoutState>.empty(),
      initialState: SessionWorkoutState(
        status: SessionWorkoutStatus.ready,
        session: session,
      ),
    );
    when(() => cubit.viewerId).thenReturn('coach-1');
    when(() => cubit.isCoach).thenReturn(true);
    when(() => cubit.canAttach).thenReturn(true);
    when(() => cubit.canEditAttachedPlan).thenReturn(true);
    when(() => cubit.canComplete).thenReturn(false);
    when(() => cubit.canNoShow).thenReturn(false);
    when(() => cubit.canCancel).thenReturn(false);
    when(() => cubit.canHistory).thenReturn(false);
    when(() => cubit.canCreateAdHocPlan).thenReturn(false);
    when(() => cubit.sessionId).thenReturn('s1');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<SessionWorkoutCubit>.value(
          value: cubit,
          child: const SessionWorkoutView(),
        ),
      ),
    );

    expect(find.text('Силовая'), findsWidgets);
    expect(find.text('Ноги'), findsWidgets);
    expect(find.text('Присед'), findsWidgets);
    expect(
      find.byKey(const Key('session-remove-workout-copy-1')),
      findsOneWidget,
    );
  });

  testWidgets('одна filled-кнопка, неявка рядом, отмена и история в шапке', (
    tester,
  ) async {
    final cubit = _MockCubit();
    final session = twoWorkouts();
    whenListen(
      cubit,
      const Stream<SessionWorkoutState>.empty(),
      initialState: SessionWorkoutState(
        status: SessionWorkoutStatus.ready,
        session: session,
      ),
    );
    when(() => cubit.viewerId).thenReturn('coach-1');
    when(() => cubit.isCoach).thenReturn(true);
    when(() => cubit.canAttach).thenReturn(false);
    when(() => cubit.canEditAttachedPlan).thenReturn(false);
    when(() => cubit.canComplete).thenReturn(true);
    when(() => cubit.canNoShow).thenReturn(true);
    when(() => cubit.canCancel).thenReturn(true);
    when(() => cubit.canHistory).thenReturn(true);
    when(() => cubit.canCreateAdHocPlan).thenReturn(false);
    when(() => cubit.sessionId).thenReturn('s1');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<SessionWorkoutCubit>.value(
          value: cubit,
          child: const SessionWorkoutView(),
        ),
      ),
    );

    expect(find.byKey(const Key('session-complete')), findsOneWidget);
    expect(find.text('Отметить проведённым'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byKey(const Key('session-no-show')), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byKey(const Key('session-cancel')), findsOneWidget);
    expect(find.byKey(const Key('session-history')), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.text('Записан'), findsOneWidget);
    expect(find.text('Иван'), findsOneWidget);
  });

  testWidgets('пустое занятие: Выбрать тренировку, «Без тренировки» вторично', (
    tester,
  ) async {
    final cubit = _MockCubit();
    const session = TrainingSession(
      id: 's1',
      coachId: 'coach-1',
      studentId: 'student-1',
      startsAt: '2026-08-21T11:00:00.000Z',
      endsAt: '2026-08-21T12:00:00.000Z',
      status: 'booked',
      createdBy: 'coach',
      studentDisplayName: 'Ольга Смирнова',
      finance: SessionFinance(status: 'not_tracked'),
    );
    whenListen(
      cubit,
      const Stream<SessionWorkoutState>.empty(),
      initialState: SessionWorkoutState(
        status: SessionWorkoutStatus.ready,
        session: session,
      ),
    );
    when(() => cubit.viewerId).thenReturn('coach-1');
    when(() => cubit.isCoach).thenReturn(true);
    when(() => cubit.canAttach).thenReturn(true);
    when(() => cubit.canEditAttachedPlan).thenReturn(false);
    when(() => cubit.canComplete).thenReturn(true);
    when(() => cubit.canNoShow).thenReturn(false);
    when(() => cubit.canCancel).thenReturn(false);
    when(() => cubit.canHistory).thenReturn(false);
    when(() => cubit.canCreateAdHocPlan).thenReturn(true);
    when(() => cubit.sessionId).thenReturn('s1');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<SessionWorkoutCubit>.value(
          value: cubit,
          child: const SessionWorkoutView(),
        ),
      ),
    );

    expect(find.byKey(const Key('session-choose-workout')), findsOneWidget);
    expect(find.text('Отметить проведённым'), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Упражнения из списка'), findsOneWidget);
    expect(find.byKey(const Key('session-no-workout')), findsOneWidget);
    final complete = find.byKey(const Key('session-complete'));
    expect(complete, findsOneWidget);
    expect(
      find.descendant(of: complete, matching: find.text('Без тренировки')),
      findsOneWidget,
    );
  });
}
