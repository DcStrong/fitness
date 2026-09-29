import type { BookingRequestModel } from '../interface';
import { BookingRequestResponseDto } from './booking-request-response.dto';

describe('Маппинг ответа заявки', () => {
  it('явно сохраняет безопасную публичную модель', () => {
    const model: BookingRequestModel = {
      id: 'request-1',
      coachId: 'coach-1',
      studentId: 'student-1',
      scheduleSlotId: 'slot-1',
      status: 'rejected',
      quotedPriceMinor: '175000',
      quotedCurrency: 'RUB',
      expiresAt: '2026-07-20T20:00:00.000Z',
      resolvedBy: 'coach-1',
      resolvedAt: '2026-07-20T10:00:00.000Z',
      rejectionReason: 'plans_changed',
      rejectionComment: 'Нужно перенести',
      resolution: null,
      resolvedScheduleSlotId: null,
      sessionId: null,
      requestedSlot: {
        id: 'slot-1',
        startsAt: '2026-07-21T10:00:00.000Z',
        endsAt: '2026-07-21T11:00:00.000Z',
        mode: 'offline',
      },
      resolvedSlot: null,
      counterpart: { id: 'student-1', label: 'student@example.com' },
      createdAt: '2026-07-20T08:00:00.000Z',
      updatedAt: '2026-07-20T10:00:00.000Z',
    };

    expect(new BookingRequestResponseDto(model)).toEqual(model);
  });
});
