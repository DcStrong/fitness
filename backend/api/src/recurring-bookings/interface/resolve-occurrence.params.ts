import type { RecurringOverrideType } from './recurring-booking.types';

export interface ResolveOccurrenceParams {
  coachId: string;
  recurringBookingId: string;
  localDate: string;
  type: RecurringOverrideType;
  newStartMinute?: number;
  newLocalDate?: string;
}
