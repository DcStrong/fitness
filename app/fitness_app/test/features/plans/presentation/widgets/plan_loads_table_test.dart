import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/plans/presentation/widgets/plan_loads_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('таблица нагрузок показывает только weight_reps', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PlanLoadsTable(
            exercises: const [
              PlanExerciseItem(
                exerciseId: 'e1',
                exerciseName: 'Жим',
                exerciseKind: 'weight_reps',
                sets: [PlanSetItem(reps: 8, weightKg: 80)],
              ),
              PlanExerciseItem(
                exerciseId: 'e2',
                exerciseName: 'Планка',
                exerciseKind: 'bodyweight_reps',
                sets: [PlanSetItem(reps: 12)],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Нагрузки'), findsOneWidget);
    expect(find.text('Жим'), findsOneWidget);
    expect(find.text('Планка'), findsNothing);
    expect(find.byKey(const Key('plan-load-e1')), findsOneWidget);
    expect(find.byKey(const Key('plan-load-e2')), findsNothing);
  });
}
