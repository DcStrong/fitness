import type { SessionCreatedBy } from '../../sessions/interface/session.types';
import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';

/**
 * Coach book-at-time: create a ScheduleSlot and book it in one transaction.
 */
export interface BookAtTimeParams {
  coachId: string;
  studentId: string;
  actorId: string;
  createdBy: SessionCreatedBy;
  startsAt: Date;
  endsAt: Date;
  mode: ScheduleSlotMode;
  priceMinor?: string;
  recurringBookingId?: string;
  recurringLocalDate?: string;
  /** Post a `session_booked` chat message (coach booking a student directly). */
  notifyChat?: boolean;
}
