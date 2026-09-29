import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../../core/widgets/fy_secondary_button.dart';
import '../../../plans/data/plans_models.dart';
import '../cubit/session_workout_cubit.dart';

Future<void> showConfirmSetsSheet(
  BuildContext context, {
  List<PlanExerciseItem>? exercises,
}) {
  final cubit = context.read<SessionWorkoutCubit>();
  final fromWorkouts = <PlanExerciseItem>[
    for (final workout in cubit.state.session?.workouts ?? const [])
      ...workout.exercises,
  ];
  final List<PlanExerciseItem> initial =
      exercises ??
      (fromWorkouts.isNotEmpty
          ? fromWorkouts
          : cubit.state.plan?.exercises ?? const <PlanExerciseItem>[]);
  if (initial.isEmpty) {
    return cubit.complete();
  }
  return showFyBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _ConfirmSetsSheet(cubit: cubit, initial: initial),
  );
}

class _ConfirmSetsSheet extends StatefulWidget {
  const _ConfirmSetsSheet({required this.cubit, required this.initial});

  final SessionWorkoutCubit cubit;
  final List<PlanExerciseItem> initial;

  @override
  State<_ConfirmSetsSheet> createState() => _ConfirmSetsSheetState();
}

class _ConfirmSetsSheetState extends State<_ConfirmSetsSheet> {
  late List<PlanExerciseItem> _exercises;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _exercises = widget.initial
        .map((item) => item.copyWith(sets: [...item.sets]))
        .toList();
  }

  bool get _changed {
    for (var i = 0; i < _exercises.length; i++) {
      final original = widget.initial[i].sets;
      final current = _exercises[i].sets;
      if (original.length != current.length) return true;
      for (var s = 0; s < current.length; s++) {
        if (original[s].reps != current[s].reps ||
            original[s].weightKg != current[s].weightKg ||
            original[s].durationSeconds != current[s].durationSeconds) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _submit({required bool asPrescribed}) async {
    setState(() => _submitting = true);
    if (asPrescribed || !_changed) {
      await widget.cubit.complete();
    } else {
      await widget.cubit.complete(logs: sessionLogsFromExercises(_exercises));
    }
    if (!mounted) return;
    if (widget.cubit.state.errorMessage != null) {
      setState(() => _submitting = false);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Факт подходов',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Проверьте веса перед «Проведена». Можно оставить как в плане.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (var e = 0; e < _exercises.length; e++) ...[
                  Text(
                    _exercises[e].exerciseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var s = 0; s < _exercises[e].sets.length; s++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 48, child: Text('Пд ${s + 1}')),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: Key('confirm-set-$e-$s-weight'),
                              initialValue:
                                  _exercises[e].sets[s].weightKg?.toString() ??
                                  '',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'кг',
                                isDense: true,
                              ),
                              onChanged: (value) {
                                final parsed = double.tryParse(
                                  value.replaceAll(',', '.'),
                                );
                                setState(() {
                                  final sets = [..._exercises[e].sets];
                                  sets[s] = sets[s].copyWith(weightKg: parsed);
                                  _exercises[e] = _exercises[e].copyWith(
                                    sets: sets,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  _exercises[e].sets[s].reps?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'повт',
                                isDense: true,
                              ),
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                setState(() {
                                  final sets = [..._exercises[e].sets];
                                  sets[s] = sets[s].copyWith(reps: parsed);
                                  _exercises[e] = _exercises[e].copyWith(
                                    sets: sets,
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          FySecondaryButton(
            key: const Key('confirm-sets-as-prescribed'),
            label: 'Как в плане',
            onPressed: _submitting ? null : () => _submit(asPrescribed: true),
          ),
          const SizedBox(height: 8),
          FyPrimaryButton(
            key: const Key('confirm-sets-submit'),
            label: 'Проведена',
            onPressed: _submitting ? null : () => _submit(asPrescribed: false),
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> sessionLogsFromExercises(
  List<PlanExerciseItem> exercises,
) {
  return [
    for (final exercise in exercises)
      {
        'exerciseId': exercise.exerciseId,
        'sets': [
          for (final set in exercise.sets)
            {
              if (set.reps != null) 'reps': set.reps,
              if (set.weightKg != null) 'weightKg': set.weightKg,
              if (set.durationSeconds != null)
                'durationSeconds': set.durationSeconds,
            },
        ],
      },
  ];
}
