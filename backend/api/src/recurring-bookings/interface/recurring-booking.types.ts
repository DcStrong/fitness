import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';

/** ISO weekday: 1 = Monday … 7 = Sunday */
export type WeekdayNumber = 1 | 2 | 3 | 4 | 5 | 6 | 7;

export type RecurringBookingStatus = 'active' | 'cancelled';

export type RecurringOverrideType = 'skip' | 'reschedule';

export type RecurringConflictReason =
  | 'missing_slot'
  | 'mode_mismatch'
  | 'held'
  | 'booked_other'
  | 'overlap';

export interface RecurringBookingModel {
  id: string;
  coachId: string;
  studentId: string;
  studentDisplayName: string | null;
  studentEmail: string | null;
  weekdays: WeekdayNumber[];
  startMinute: number;
  mode: ScheduleSlotMode;
  timezone: string;
  status: RecurringBookingStatus;
  horizonWeeksOverride: number | null;
  /** ISO local date YYYY-MM-DD; null when cancelled or none in horizon */
  nextOccurrenceLocalDate: string | null;
  createdAt: string;
  updatedAt: string;
  cancelledAt: string | null;
}

export interface RecurringOverrideModel {
  id: string;
  recurringBookingId: string;
  localDate: string;
  type: RecurringOverrideType;
  newStartMinute: number | null;
  newLocalDate: string | null;
}

export interface RecurringConflict {
  localDate: string;
  reason: RecurringConflictReason;
  startsAt: string;
  endsAt: string;
}

export interface RecurringSyncSummary {
  booked: number;
  skippedExisting: number;
  slotsCreated: number;
  conflicts: RecurringConflict[];
}

export interface DesiredOccurrence {
  /** Source pattern local date (before reschedule) */
  sourceLocalDate: string;
  /** Effective local date after overrides */
  localDate: string;
  startMinute: number;
}
