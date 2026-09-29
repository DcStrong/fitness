import type { SessionStatus } from './session.types';
import type { SessionExerciseLogInput } from './session-set-log.types';

/**
 *
 */
export interface TransitionSessionParams {
  sessionId: string;
  note?: string;
  /** When true and cancelling, set linked ScheduleSlot status to `open`. */
  releaseSlot?: boolean;
  logs?: SessionExerciseLogInput[];
}

/**
 *
 */
export interface TransitionSessionActor {
  id: string;
  permissions: string[];
}

/**
 *
 */
export interface MarkNoShowParams extends TransitionSessionParams {
  charge: boolean;
}

/**
 *
 */
export type LifecycleTargetStatus = 'completed' | 'cancelled' | 'no_show';

/**
 *
 */
export interface ApplyTransitionParams {
  sessionId: string;
  actorId: string;
  toStatus: LifecycleTargetStatus;
  note?: string;

  /** Required participant role for this transition */
  requireRole: 'coach' | 'participant';
  chargeNoShow?: boolean;
  /** When true and toStatus is cancelled, reopen the linked ScheduleSlot. */
  releaseSlot?: boolean;
  logs?: SessionExerciseLogInput[];
}

/**
 *
 */
export interface SessionHistoryEventReturns {
  id: string;
  sessionId: string;
  actorUserId: string;
  actorEmail: string | null;
  fromStatus: SessionStatus;
  toStatus: SessionStatus;
  note: string | null;
  createdAt: string;
}
