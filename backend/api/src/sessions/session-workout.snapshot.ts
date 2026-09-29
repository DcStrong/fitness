import type { SessionWorkoutItemEntity } from '../database/entity/session-workout-item.entity';
import type { TrainingPlanReturns } from '../plans/interface';
import type {
  ReplaceSessionWorkoutItemParams,
  SessionWorkoutSource,
} from '../workout-programs/interface';

/**
 *
 */
export function snapshotFromPlan(
  plan: TrainingPlanReturns,
  options: {
    source: SessionWorkoutSource;
    overrideAt: Date | null;
    weightByExercise?: ReadonlyMap<string, number>;
  },
): ReplaceSessionWorkoutItemParams {
  const sets = plan.exercises.flatMap(exercise =>
    exercise.sets.map(set => ({
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      exerciseKind: exercise.exerciseKind,
      sortOrder: set.sortOrder,
      reps: set.reps,
      weightKg:
        exercise.exerciseKind === 'weight_reps' &&
        options.weightByExercise?.has(exercise.exerciseId)
          ? (options.weightByExercise.get(exercise.exerciseId) ?? set.weightKg)
          : set.weightKg,
      durationSeconds: set.durationSeconds,
    })),
  );

  return {
    studentPlanId: plan.id,
    title: plan.title,
    source: options.source,
    overrideAt: options.overrideAt,
    sets,
  };
}

/**
 *
 */
export function snapshotFromStoredItem(
  item: SessionWorkoutItemEntity,
  options?: {
    overrideAt?: Date | null;
    weightByExercise?: ReadonlyMap<string, number>;
  },
): ReplaceSessionWorkoutItemParams {
  return {
    studentPlanId: item.studentPlanId,
    title: item.studentPlan?.title ?? '',
    source: item.source,
    overrideAt:
      options?.overrideAt !== undefined ? options.overrideAt : item.overrideAt,
    sets: (item.sets ?? []).map(set => ({
      exerciseId: set.exerciseId,
      exerciseName: set.exerciseName,
      exerciseKind: set.exerciseKind,
      sortOrder: set.sortOrder,
      reps: set.reps,
      weightKg:
        set.exerciseKind === 'weight_reps' &&
        options?.weightByExercise?.has(set.exerciseId)
          ? (options.weightByExercise.get(set.exerciseId) ?? null)
          : set.weightKg === null
            ? null
            : Number(set.weightKg),
      durationSeconds: set.durationSeconds,
    })),
  };
}
