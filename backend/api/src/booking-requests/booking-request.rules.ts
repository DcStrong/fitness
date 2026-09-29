import { ConflictException } from '@nestjs/common';
import type { BookingRequestStatus } from './interface';

export const BOOKING_REQUEST_RESPONSE_HOURS = 12;
export const BOOKING_REQUEST_SLOT_CUTOFF_HOURS = 2;
export const BOOKING_REQUEST_REJECTION_COMMENT_MAX_LENGTH = 500;
const MILLISECONDS_PER_HOUR = 60 * 60 * 1000;

/**
 *
 */
export function earliestRequestableSlotStart(now: Date): Date {
  return new Date(
    now.getTime() + BOOKING_REQUEST_SLOT_CUTOFF_HOURS * MILLISECONDS_PER_HOUR,
  );
}

/**
 *
 */
export function calculateBookingRequestExpiry(
  createdAt: Date,
  slotStartsAt: Date,
): Date {
  const responseWindow =
    BOOKING_REQUEST_RESPONSE_HOURS * MILLISECONDS_PER_HOUR;
  const slotCutoff =
    BOOKING_REQUEST_SLOT_CUTOFF_HOURS * MILLISECONDS_PER_HOUR;
  const responseDeadline = new Date(
    createdAt.getTime() + responseWindow,
  );
  const slotDeadline = new Date(
    slotStartsAt.getTime() - slotCutoff,
  );
  const expiresAt =
    responseDeadline.getTime() < slotDeadline.getTime()? responseDeadline: slotDeadline;
  if (expiresAt.getTime() <= createdAt.getTime()) {
    throw new ConflictException(
      'Booking request decision window has already closed',
    );
  }

  return expiresAt;
}

/**
 *
 */
export function assertPendingBookingRequest(status: BookingRequestStatus): void {
  if (status !== 'pending') {
    throw new ConflictException('Booking request is no longer pending');
  }
}
