import type { WeekdayNumber } from '../../recurring-bookings/interface/recurring-booking.types';
import type { ExerciseKind } from '../../exercises/interface';
import type { PlanGoal } from '../../plans/interface';

export const SESSION_WORKOUT_SOURCES = ['program', 'manual'] as const;

export type SessionWorkoutSource = (typeof SESSION_WORKOUT_SOURCES)[number];

export interface WorkoutProgramDayItemInput {
  templateId: string;
}

export interface WorkoutProgramDayInput {
  weekday: WeekdayNumber;
  items: WorkoutProgramDayItemInput[];
}

export interface WorkoutProgressionRuleInput {
  exerciseId: string;
  startWeightKg?: number | null;
  deltaKg?: number;
  incrementKg?: number;
  holdOnMiss?: boolean;
}

export interface UpsertWorkoutProgramParams {
  coachId: string;
  recurringBookingId: string;
  horizonWeeks?: number;
  days: WorkoutProgramDayInput[];
  progressionRules?: WorkoutProgressionRuleInput[];
}

export interface ApplyWorkoutProgramParams {
  coachId: string;
  recurringBookingId: string;
  force?: boolean;
}

export interface WorkoutProgramDayItemReturns {
  templateId: string;
  studentPlanId: string;
  title: string;
  sortOrder: number;
}

export interface WorkoutProgramDayReturns {
  weekday: WeekdayNumber;
  items: WorkoutProgramDayItemReturns[];
}

export interface WorkoutProgressionRuleReturns {
  exerciseId: string;
  startWeightKg: number | null;
  deltaKg: number;
  incrementKg: number;
  holdOnMiss: boolean;
  heldWeightKg: number | null;
}

export interface WorkoutProgramPreviewPoint {
  date: string;
  weekday: WeekdayNumber;
  exerciseId: string;
  weightKg: number;
}

export interface WorkoutProgramReturns {
  id: string;
  recurringBookingId: string;
  studentId: string;
  horizonWeeks: number;
  days: WorkoutProgramDayReturns[];
  progressionRules: WorkoutProgressionRuleReturns[];
  preview: WorkoutProgramPreviewPoint[];
}

export interface ReplaceProgramDayItemParams {
  templateId: string;
  studentPlanId: string;
  sortOrder: number;
}

export interface ReplaceProgramDayParams {
  weekday: WeekdayNumber;
  items: ReplaceProgramDayItemParams[];
}

export interface ReplaceProgressionRuleParams {
  exerciseId: string;
  startWeightKg: number | null;
  deltaKg: number;
  incrementKg: number;
  holdOnMiss: boolean;
  heldWeightKg: number | null;
}

export interface SessionPrescriptionSetReturns {
  exerciseId: string;
  exerciseName: string;
  exerciseKind: ExerciseKind;
  sortOrder: number;
  reps: number | null;
  weightKg: number | null;
  durationSeconds: number | null;
}

export interface SessionWorkoutReturns {
  studentPlanId: string;
  title: string;
  goal: PlanGoal;
  source: SessionWorkoutSource;
  overridden: boolean;
  exercises: SessionPrescriptionSetGroupReturns[];
}

export interface SessionPrescriptionSetGroupReturns {
  exerciseId: string;
  exerciseName: string;
  exerciseKind: ExerciseKind;
  sets: SessionPrescriptionSetReturns[];
}

export interface ReplaceSessionWorkoutItemParams {
  studentPlanId: string;
  title: string;
  source: SessionWorkoutSource;
  overrideAt: Date | null;
  sets: ReplaceSessionPrescriptionSetParams[];
}

export interface ReplaceSessionPrescriptionSetParams {
  exerciseId: string;
  exerciseName: string;
  exerciseKind: ExerciseKind;
  sortOrder: number;
  reps: number | null;
  weightKg: number | null;
  durationSeconds: number | null;
}
