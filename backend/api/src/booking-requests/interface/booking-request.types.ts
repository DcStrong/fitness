import type { BillingCurrency, MoneyMinor } from '../../billing/interface';
import type { ScheduleSlotMode } from '../../schedules/interface';

/**
 *
 */
export type BookingRequestStatus =
  | 'pending'
  | 'accepted'
  | 'rejected'
  | 'withdrawn'
  | 'expired';

/**
 *
 */
export type BookingRequestRejectionReason =
  | 'time_unavailable'
  | 'plans_changed'
  | 'other';

/**
 *
 */
export type BookingRequestResolution = 'requested_slot' | 'alternate_slot';

/**
 *
 */
export type BookingRequestEventType =
  | 'created'
  | 'accepted'
  | 'rejected'
  | 'withdrawn'
  | 'expired';

/**
 *
 */
export interface BookingRequestActor {
  id: string;
  roles: string[];
}

/**
 *
 */
export interface CreateBookingRequestParams {
  studentId: string;
  scheduleSlotId: string;
}

/**
 *
 */
export interface BookingRequestPageParams {
  page: number;
  limit: number;
  status?: BookingRequestStatus;
}

/**
 *
 */
export interface RejectBookingRequestParams {
  requestId: string;
  coachId: string;
  reason: BookingRequestRejectionReason;
  comment?: string;
}

/**
 *
 */
export interface AlternateBookingRequestParams {
  requestId: string;
  coachId: string;
  startsAt: string;
}

/**
 *
 */
export interface BookingRequestSlotSummary {
  id: string;
  startsAt: string;
  endsAt: string;
  mode: ScheduleSlotMode;
}

/**
 *
 */
export interface BookingRequestModel {
  id: string;
  coachId: string;
  studentId: string;
  scheduleSlotId: string;
  status: BookingRequestStatus;
  quotedPriceMinor: MoneyMinor;
  quotedCurrency: BillingCurrency;
  expiresAt: string;
  resolvedBy: string | null;
  resolvedAt: string | null;
  rejectionReason: BookingRequestRejectionReason | null;
  rejectionComment: string | null;
  resolution: BookingRequestResolution | null;
  resolvedScheduleSlotId: string | null;
  sessionId: string | null;
  requestedSlot: BookingRequestSlotSummary;
  resolvedSlot: BookingRequestSlotSummary | null;
  counterpart: { id: string; label: string; };
  createdAt: string;
  updatedAt: string;
}

/**
 *
 */
export interface BookingRequestPage {
  items: BookingRequestModel[];
  meta: { page: number; limit: number; total: number; totalPages: number; };
}

/**
 *
 */
export interface PendingCountReturns {
  count: number;
}

/**
 *
 */
export interface ExpireDueReturns {
  expiredCount: number;
}
