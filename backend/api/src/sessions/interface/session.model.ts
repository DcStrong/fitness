import type {
  SessionCreatedBy,
  SessionMode,
  SessionStatus,
} from './session.types';
import type { SessionChargeModel } from '../../billing/interface';
import type { TrainingPlanReturns } from '../../plans/interface';
import type { SessionWorkoutReturns } from '../../workout-programs/interface';

/** Domain shape for mapping to public returns (emails optional). */
export interface SessionModel {
  id: string;
  coachId: string;
  studentId: string;
  scheduleSlotId: string | null;
  startsAt: Date;
  endsAt: Date;
  mode: SessionMode;
  status: SessionStatus;
  createdBy: SessionCreatedBy;
  createdAt: Date;
  studentPlanId?: string | null;
  studentPlan?: { title: string } | null;
  recurringBookingId?: string | null;
  coach?: { email: string; } | null;
  student?: { email: string; } | null;
  coachDisplayName?: string | null;
  studentDisplayName?: string | null;
  charge?: SessionChargeModel | null;
  plan?: TrainingPlanReturns | null;
  workouts?: SessionWorkoutReturns[];
}
