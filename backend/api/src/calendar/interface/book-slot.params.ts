import type { SessionCreatedBy } from '../../sessions/interface/session.types';

/**
 *
 */
export interface BookSlotParams {
  scheduleSlotId: string;
  studentId: string;
  actorId: string;
  createdBy: SessionCreatedBy;
  priceMinor?: string;
  recurringBookingId?: string;
  recurringLocalDate?: string;
  /** Post a `session_booked` chat message (coach booking a student directly). */
  notifyChat?: boolean;
}
