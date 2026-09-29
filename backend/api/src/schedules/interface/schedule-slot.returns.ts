import type { ScheduleSlotMode, ScheduleSlotStatus } from './schedule-slot.types';
import type { Money } from '../../billing/interface';

/**
 *
 */
export interface ScheduleSlotReturns {
  id: string;
  coachId: string;
  startsAt: string;
  endsAt: string;
  mode: ScheduleSlotMode;
  status: ScheduleSlotStatus;
  capacity: number;
  seriesId: string | null;
  gymId: string | null;
  createdAt: string;
  price: Money | null;
  held: boolean;
}

/**
 *
 */
export interface DeleteSlotReturns {
  success: true;
}
