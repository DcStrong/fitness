import type {
  SessionCreatedBy,
  SessionMode,
  SessionStatus,
} from './session.types';
import type { SessionFinanceSummary } from '../../billing/interface';
import type { TrainingPlanReturns } from '../../plans/interface';
import type { SessionWorkoutReturns } from '../../workout-programs/interface';

/**
 *
 */
export interface SessionReturns {
  id: string;
  coachId: string;
  studentId: string;
  scheduleSlotId: string | null;
  startsAt: string;
  endsAt: string;
  mode: SessionMode;
  status: SessionStatus;
  createdBy: SessionCreatedBy;
  coachEmail: string | null;
  studentEmail: string | null;
  coachDisplayName: string | null;
  studentDisplayName: string | null;
  createdAt: string;
  finance: SessionFinanceSummary;
  packageExhausted?: boolean;
  studentPlanId: string | null;
  planTitle?: string | null;
  plan?: TrainingPlanReturns | null;
  workouts: SessionWorkoutReturns[];
  recurringBookingId: string | null;
}
