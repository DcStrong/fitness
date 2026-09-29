import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';

/**
 *
 */
export interface BookSessionActor {
  id: string;
  permissions: string[];
  roles?: string[];
}

/**
 * XOR: scheduleSlotId | { startsAt, endsAt, mode? }
 */
export interface BookSessionParams {
  scheduleSlotId?: string;
  startsAt?: string;
  endsAt?: string;
  mode?: ScheduleSlotMode;
  studentId?: string;
  priceMinor?: string;
}
