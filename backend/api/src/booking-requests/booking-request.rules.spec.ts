import { ConflictException } from '@nestjs/common';
import {
  assertPendingBookingRequest,
  calculateBookingRequestExpiry,
  earliestRequestableSlotStart,
} from './booking-request.rules';

describe('Правила жизненного цикла заявки', () => {
  it('ограничивает срок двенадцатью часами', () => {
    const createdAt = new Date('2026-07-20T08:00:00.000Z');
    const startsAt = new Date('2026-07-22T08:00:00.000Z');

    expect(calculateBookingRequestExpiry(createdAt, startsAt)).toEqual(
      new Date('2026-07-20T20:00:00.000Z'),
    );
  });

  it('ограничивает срок двумя часами до слота', () => {
    const createdAt = new Date('2026-07-20T08:00:00.000Z');
    const startsAt = new Date('2026-07-20T14:00:00.000Z');

    expect(calculateBookingRequestExpiry(createdAt, startsAt)).toEqual(
      new Date('2026-07-20T12:00:00.000Z'),
    );
  });

  it('отклоняет закрытое окно решения', () => {
    expect(() =>
      calculateBookingRequestExpiry(
        new Date('2026-07-20T12:00:00.000Z'),
        new Date('2026-07-20T14:00:00.000Z'),
      )).toThrow(ConflictException);
  });

  it('совпадает с границей окна: now + 2 часа', () => {
    const now = new Date('2026-07-20T12:00:00.000Z');

    expect(earliestRequestableSlotStart(now)).toEqual(
      new Date('2026-07-20T14:00:00.000Z'),
    );
  });

  it('отклоняет слот ровно на cutoff', () => {
    const now = new Date('2026-07-20T12:00:00.000Z');
    const startsAt = earliestRequestableSlotStart(now);

    expect(() => calculateBookingRequestExpiry(now, startsAt)).toThrow(
      ConflictException,
    );
  });

  it('принимает слот позже cutoff', () => {
    const now = new Date('2026-07-20T12:00:00.000Z');
    const startsAt = new Date(
      earliestRequestableSlotStart(now).getTime() + 1,
    );

    expect(calculateBookingRequestExpiry(now, startsAt)).toEqual(
      new Date(now.getTime() + 1),
    );
  });

  it('разрешает переход только из pending', () => {
    expect(() => assertPendingBookingRequest('accepted')).toThrow(
      ConflictException,
    );
    expect(() => assertPendingBookingRequest('pending')).not.toThrow();
  });
});
