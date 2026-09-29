import type { PlanGoal } from '../../plans/interface';

/**
 *
 */
export interface ProgressPointReturns {
  sessionId: string;
  completedAt: string;
  weightKg: number | null;
  volume: number;
  coachId: string;
}

/**
 *
 */
export interface ProgressSeriesReturns {
  exerciseId: string;
  goal: PlanGoal | null;
  points: ProgressPointReturns[];
}

/**
 *
 */
export interface ProgressExerciseSummaryReturns {
  exerciseId: string;
  name: string;
  sessionCount: number;
}

/**
 *
 */
export interface ProgressCatalogReturns {
  exercises: ProgressExerciseSummaryReturns[];
}

/**
 *
 */
export interface GetProgressParams {
  actorId: string;
  studentId: string;
  exerciseId?: string;
  coachId?: string;
}

/**
 *
 */
export interface ProgressLogRow {
  sessionId: string;
  coachId: string;
  completedAt: Date;
  reps: number | null;
  weightKg: string | null;
}

/**
 *
 */
export interface ProgressExerciseRow {
  exerciseId: string;
  name: string;
  sessionCount: number;
}
