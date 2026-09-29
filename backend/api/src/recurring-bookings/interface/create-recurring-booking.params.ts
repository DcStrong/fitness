import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';
import type { WeekdayNumber } from './recurring-booking.types';

export interface CreateRecurringBookingParams {
  coachId: string;
  studentId: string;
  weekdays: WeekdayNumber[];
  startMinute: number;
  mode: ScheduleSlotMode;
  horizonWeeksOverride?: number | null;
}
