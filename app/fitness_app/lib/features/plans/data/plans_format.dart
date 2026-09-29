import 'plans_models.dart';

String planGoalLabel(String goal) {
  switch (goal) {
    case 'hypertrophy':
      return 'Набор';
    case 'fat_loss':
      return 'Похудение';
    default:
      return 'Общее';
  }
}

({int sets, int reps, int restSeconds}) goalExerciseDefaults(String goal) {
  switch (goal) {
    case 'hypertrophy':
      return (sets: 3, reps: 10, restSeconds: 90);
    case 'fat_loss':
      return (sets: 3, reps: 15, restSeconds: 45);
    default:
      return (sets: 3, reps: 12, restSeconds: 60);
  }
}

String formatSetsCompact({
  required String kind,
  required List<PlanSetItem> sets,
  int? restSeconds,
}) {
  final rest = restSeconds == null ? '' : ' · отдых $restSecondsс';
  if (sets.isEmpty) {
    return 'без подходов$rest';
  }
  if (kind == 'duration') {
    final seconds = sets.first.durationSeconds ?? 0;
    final same = sets.every((set) => set.durationSeconds == seconds);
    final head = same
        ? '${sets.length}×$secondsс'
        : '${sets.length} подходов';
    return '$head$rest';
  }
  final reps = sets.first.reps ?? 0;
  final weight = sets.first.weightKg;
  final same = sets.every((set) => set.reps == reps && set.weightKg == weight);
  if (!same) {
    return '${sets.length} подходов$rest';
  }
  final weightPart = weight == null ? '' : ' · ${_formatKg(weight)} кг';
  return '${sets.length}×$reps$weightPart$rest';
}

double? workingWeightKg(PlanExerciseItem exercise) {
  if (exercise.exerciseKind != 'weight_reps') return null;
  double? max;
  for (final set in exercise.sets) {
    final weight = set.weightKg;
    if (weight == null) continue;
    if (max == null || weight > max) max = weight;
  }
  return max;
}

String formatPlanExerciseRow(PlanExerciseItem exercise) {
  return formatSetsCompact(
    kind: exercise.exerciseKind,
    sets: exercise.sets,
    restSeconds: exercise.restSeconds,
  );
}

List<PlanSetItem> identicalSets({
  required int count,
  required String kind,
  int reps = 10,
  double? weightKg,
  int durationSeconds = 30,
}) {
  return List<PlanSetItem>.generate(count, (index) {
    if (kind == 'duration') {
      return PlanSetItem(sortOrder: index, durationSeconds: durationSeconds);
    }
    return PlanSetItem(sortOrder: index, reps: reps, weightKg: weightKg);
  });
}

String _formatKg(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
