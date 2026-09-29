import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/widgets/fy_card.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/student_hub/data/progress_models.dart';
import 'package:fitness_app/features/student_hub/presentation/cubit/student_hub_cubit.dart';
import 'package:fitness_app/features/student_hub/presentation/cubit/student_hub_state.dart';
import 'package:fitness_app/features/student_hub/presentation/student_hub_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockHubCubit extends MockCubit<StudentHubState>
    implements StudentHubCubit {}

void main() {
  testWidgets('пустой прогресс показывает русскую подсказку', (tester) async {
    final cubit = _MockHubCubit();
    whenListen(
      cubit,
      const Stream<StudentHubState>.empty(),
      initialState: const StudentHubState(status: StudentHubStatus.ready),
    );
    when(() => cubit.isSelf).thenReturn(true);
    when(() => cubit.isTrainer).thenReturn(false);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<StudentHubCubit>.value(
          value: cubit,
          child: const StudentHubView(),
        ),
      ),
    );

    expect(
      find.text('Проведите занятие с весами, чтобы увидеть график'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('hub-progress-empty')), findsOneWidget);
  });

  testWidgets('график и цифры для hypertrophy', (tester) async {
    final cubit = _MockHubCubit();
    const state = StudentHubState(
      status: StudentHubStatus.ready,
      series: ProgressSeries(
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
    whenListen(
      cubit,
      const Stream<StudentHubState>.empty(),
      initialState: state,
    );
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.isSelf).thenReturn(false);
    when(() => cubit.isTrainer).thenReturn(true);
    when(() => cubit.studentId).thenReturn('student-1');
    when(() => cubit.load()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<StudentHubCubit>.value(
          value: cubit,
          child: const StudentHubView(),
        ),
      ),
    );

    expect(cubit.state.series?.points, hasLength(2));
    expect(find.byKey(const Key('hub-person-header')), findsOneWidget);
    expect(find.byKey(const Key('hub-action-grid')), findsOneWidget);
    expect(find.text('Ближайшие'), findsOneWidget);
    expect(find.text('Назначенные'), findsOneWidget);
    expect(
      find.text(
        'Проведите занятие с весами, чтобы увидеть график',
        skipOffstage: false,
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('hub-progress-chart'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('у ученика нет сетки действий тренера', (tester) async {
    final cubit = _MockHubCubit();
    whenListen(
      cubit,
      const Stream<StudentHubState>.empty(),
      initialState: const StudentHubState(status: StudentHubStatus.ready),
    );
    when(() => cubit.isSelf).thenReturn(true);
    when(() => cubit.isTrainer).thenReturn(false);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<StudentHubCubit>.value(
          value: cubit,
          child: const StudentHubView(),
        ),
      ),
    );

    expect(find.byKey(const Key('hub-action-grid')), findsNothing);
    expect(find.byKey(const Key('hub-progress-empty')), findsOneWidget);
  });

  testWidgets('шапка показывает короткое имя и mint-инициалы', (tester) async {
    final cubit = _MockHubCubit();
    const state = StudentHubState(
      status: StudentHubStatus.ready,
      studentDisplayName: 'Алина Козлова',
    );
    whenListen(
      cubit,
      const Stream<StudentHubState>.empty(),
      initialState: state,
    );
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.isSelf).thenReturn(false);
    when(() => cubit.isTrainer).thenReturn(true);
    when(() => cubit.studentId).thenReturn('student-1');
    when(() => cubit.load()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<StudentHubCubit>.value(
          value: cubit,
          child: const StudentHubView(),
        ),
      ),
    );

    expect(find.text('Алина К.'), findsOneWidget);
    expect(find.text('Алина Козлова'), findsOneWidget);
    expect(find.text('АК'), findsOneWidget);
    expect(find.byKey(const Key('hub-action-grid')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const Key('hub-person-header')),
        matching: find.byType(FyCard),
      ),
      findsNothing,
    );
  });

  testWidgets('ближайшее занятие — карточка с датой, не строка в шапке', (
    tester,
  ) async {
    final cubit = _MockHubCubit();
    const state = StudentHubState(
      status: StudentHubStatus.ready,
      studentDisplayName: 'Ольга Смирнова',
      upcoming: [
        TrainingSession(
          id: 's1',
          coachId: 'coach-1',
          studentId: 'student-1',
          startsAt: '2026-08-21T15:00:00.000Z',
          endsAt: '2026-08-21T16:00:00.000Z',
          status: 'booked',
          createdBy: 'coach',
          finance: SessionFinance(status: 'not_tracked'),
          planTitle: 'Сила и тонус',
        ),
      ],
    );
    whenListen(
      cubit,
      const Stream<StudentHubState>.empty(),
      initialState: state,
    );
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.isSelf).thenReturn(false);
    when(() => cubit.isTrainer).thenReturn(true);
    when(() => cubit.studentId).thenReturn('student-1');
    when(() => cubit.load()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<StudentHubCubit>.value(
          value: cubit,
          child: const StudentHubView(),
        ),
      ),
    );

    expect(find.byKey(const Key('hub-session-s1')), findsOneWidget);
    expect(find.text('Сила и тонус'), findsOneWidget);
    expect(find.text('Персональная тренировка'), findsNothing);
  });
}
