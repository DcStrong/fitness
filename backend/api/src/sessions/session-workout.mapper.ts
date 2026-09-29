import type { SessionWorkoutReturns } from '../workout-programs/interface';
import type { SessionWorkoutItemEntity } from '../database/entity/session-workout-item.entity';
import type { SessionPrescriptionSetEntity } from '../database/entity/session-prescription-set.entity';

/**
 *
 */
export function toSessionWorkouts(
  items: SessionWorkoutItemEntity[],
): SessionWorkoutReturns[] {
  return [...items]
    .sort((left, right) => left.sortOrder - right.sortOrder)
    .map(item => ({
      studentPlanId: item.studentPlanId,
      title: item.studentPlan?.title ?? '',
      goal: item.studentPlan?.goal ?? 'general',
      source: item.source,
      overridden: item.overrideAt != null,
      exercises: groupPrescriptionSets(item.sets ?? []),
    }));
}

/**
 *
 */
function groupPrescriptionSets(
  sets: SessionPrescriptionSetEntity[],
): SessionWorkoutReturns['exercises'] {
  const order: string[] = [];
  const byExercise = new Map<string, SessionPrescriptionSetEntity[]>();
  const sorted = [...sets].sort((left, right) => left.sortOrder - right.sortOrder);
  for (const set of sorted) {
    const existing = byExercise.get(set.exerciseId);
    if (!existing) {
      order.push(set.exerciseId);
      byExercise.set(set.exerciseId, [set]);
      continue;
    }
    existing.push(set);
  }

  return order.map(exerciseId => {
    const group = byExercise.get(exerciseId) ?? [];
    const first = group[0]!;

    return {
      exerciseId,
      exerciseName: first.exerciseName,
      exerciseKind: first.exerciseKind,
      sets: group.map(set => ({
        exerciseId: set.exerciseId,
        exerciseName: set.exerciseName,
        exerciseKind: set.exerciseKind,
        sortOrder: set.sortOrder,
        reps: set.reps,
        weightKg: parseWeight(set.weightKg),
        durationSeconds: set.durationSeconds,
      })),
    };
  });
}

/**
 *
 */
function parseWeight(value: string | null): number | null {
  if (value === null) {
    return null;
  }
  const parsed = Number(value);

  return Number.isFinite(parsed) ? parsed : null;
}
