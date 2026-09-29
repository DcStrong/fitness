import type { ScheduleSlotStatus } from './schedule-slot.types';

/**
 *
 */
export interface FindSlotsForCoachParams {
  from?: Date;
  to?: Date;
  status?: ScheduleSlotStatus;
}
