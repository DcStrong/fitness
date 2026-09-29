import type {
  RecurringBookingModel,
  RecurringSyncSummary,
} from './recurring-booking.types';

export interface CreateRecurringBookingReturns {
  booking: RecurringBookingModel;
  sync: RecurringSyncSummary;
}
