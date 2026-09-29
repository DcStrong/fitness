import type { ScheduleSlotStatus } from '../../schedules/interface/schedule-slot.types';

/** Statuses that block creating a new open/booked slot on the same interval. */
export const OCCUPIED_SLOT_STATUSES: ScheduleSlotStatus[] = [
  'open',
  'booked',
  'blocked',
];
