import type { ScheduleSlotMode } from './schedule-slot.types';

/**
 *
 */
export interface CreateSlotParams {
  coachId: string;
  startsAt: string;
  endsAt: string;
  mode?: ScheduleSlotMode;
}
