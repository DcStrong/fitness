import type {
  PrescriptionExerciseSource,
  SessionExerciseLogInput,
  SessionSetLogRowParams,
} from './interface/session-set-log.types';

/**
 *
 */
export function formatLogWeightKg(
  value: string | number | null | undefined,
): string | null {
  if (value === null || value === undefined || value === '') {
    return null;
  }
  const numeric = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(numeric)) {
    return null;
  }

  return numeric.toFixed(2);
}

/**
 *
 */
export function buildLogsFromPayload(
  sessionId: string,
  logs: SessionExerciseLogInput[],
): SessionSetLogRowParams[] {
  const sortByExercise = new Map<string, number>();
  const rows: SessionSetLogRowParams[] = [];
  for (const exercise of logs) {
    for (const set of exercise.sets) {
      const sortOrder = sortByExercise.get(exercise.exerciseId) ?? 0;
      sortByExercise.set(exercise.exerciseId, sortOrder + 1);
      rows.push({
        sessionId,
        exerciseId: exercise.exerciseId,
        sortOrder,
        reps: set.reps ?? null,
        weightKg: formatLogWeightKg(set.weightKg),
        durationSeconds: set.durationSeconds ?? null,
      });
    }
  }

  return rows;
}

/**
 *
 */
export function buildLogsFromPrescription(
  sessionId: string,
  exercises: PrescriptionExerciseSource[],
): SessionSetLogRowParams[] {
  return buildLogsFromPayload(
    sessionId,
    exercises.map(exercise => ({
      exerciseId: exercise.exerciseId,
      sets: exercise.sets.map(set => ({
        reps: set.reps,
        weightKg:
          set.weightKg === null || set.weightKg === undefined
            ? null
            : Number(set.weightKg),
        durationSeconds: set.durationSeconds,
      })),
    })),
  );
}
