/**
 *
 */
export type ChatMessageKind = 'text' | 'system';

/**
 *
 */
export type ChatSystemType =
  | 'session_booked'
  | 'session_cancelled'
  | 'session_rescheduled'
  | 'occurrence_skipped'
  | 'request_accepted'
  | 'request_alternate'
  | 'request_rejected';

/**
 * Data the app needs to render a system card; times are ISO strings.
 */
export interface ChatSystemPayload {
  sessionId?: string | null;
  bookingRequestId?: string | null;
  startsAt?: string | null;
  endsAt?: string | null;
  previousStartsAt?: string | null;

  /** Recurring occurrence date (YYYY-MM-DD) in the series time zone. */
  localDate?: string | null;
  note?: string | null;
}

/**
 *
 */
export type ChatParticipantRole = 'coach' | 'student';
