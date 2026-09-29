/**
 *
 */
export interface ListSessionsQuery {
  from?: string;
  to?: string;

  /** Comma-separated or single SessionStatus */
  status?: string;
  studentId?: string;
}

/**
 *
 */
export interface FindSessionsForUserParams {
  from?: Date;
  to?: Date;
  statuses?: Array<'booked' | 'completed' | 'cancelled' | 'no_show'>;
  studentId?: string;
}
