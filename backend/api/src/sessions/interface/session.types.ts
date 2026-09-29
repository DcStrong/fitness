import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';

/**
 *
 */
export type SessionStatus =
  | 'booked'
  | 'completed'
  | 'cancelled'
  | 'no_show';

/**
 *
 */
export type SessionCreatedBy = 'coach' | 'student';

/** Same literals as schedule slot mode — schedules owns the union. */
export type SessionMode = ScheduleSlotMode;
