/**
 *
 */
export interface SessionSetLogSetInput {
  reps?: number | null;
  weightKg?: number | null;
  durationSeconds?: number | null;
}

/**
 *
 */
export interface SessionExerciseLogInput {
  exerciseId: string;
  sets: SessionSetLogSetInput[];
}

/**
 *
 */
export interface SessionSetLogRowParams {
  sessionId: string;
  exerciseId: string;
  sortOrder: number;
  reps: number | null;
  weightKg: string | null;
  durationSeconds: number | null;
}

/**
 *
 */
export interface PrescriptionSetSource {
  reps: number | null;
  weightKg: string | number | null;
  durationSeconds: number | null;
}

/**
 *
 */
export interface PrescriptionExerciseSource {
  exerciseId: string;
  sets: PrescriptionSetSource[];
}
