import { ConflictException } from '@nestjs/common';
import { RecurringBookingsService } from './recurring-bookings.service';

describe('RecurringBookingsService create pattern guard', () => {
  const coachId = 'coach-1';
  const studentId = 'student-1';
  const weekdays = [6] as const;

  function buildService(overrides: {
    findByPattern: jest.Mock;
    save?: jest.Mock;
    create?: jest.Mock;
    findByPair?: jest.Mock;
    findByCoachId?: jest.Mock;
    findByUserIds?: jest.Mock;
    findByIds?: jest.Mock;
    findByIdForCoach?: jest.Mock;
    findByBookingIds?: jest.Mock;
    syncImpl?: jest.Mock;
  }) {
    const bookings = {
      findByPattern: overrides.findByPattern,
      save: overrides.save ?? jest.fn(async (e: unknown) => e),
      create:
        overrides.create ??
        jest.fn((data: Record<string, unknown>) => ({
          id: 'new-id',
          createdAt: new Date('2026-08-01T00:00:00.000Z'),
          updatedAt: new Date('2026-08-01T00:00:00.000Z'),
          cancelledAt: null,
          ...data,
        })),
      findByIdForCoach:
        overrides.findByIdForCoach ?? jest.fn(async () => null),
      findActiveByCoach: jest.fn(),
      findByCoachId: jest.fn(),
      findByCoachIdAndStatus: jest.fn(),
      remove: jest.fn(),
    };
    const service = new RecurringBookingsService(
      bookings as never,
      {
        findByBookingIds:
          overrides.findByBookingIds ?? jest.fn(async () => []),
        findByBookingId: jest.fn(async () => []),
      } as never,
      {
        findByCoachId:
          overrides.findByCoachId ??
          jest.fn(async () => ({
            timezone: 'Europe/Moscow',
            horizonWeeks: 8,
          })),
      } as never,
      {
        findByPair:
          overrides.findByPair ?? jest.fn(async () => ({ id: 'link-1' })),
      } as never,
      {} as never,
      {} as never,
      {} as never,
      {} as never,
      {
        findByUserIds: overrides.findByUserIds ?? jest.fn(async () => []),
      } as never,
      {
        findByIds: overrides.findByIds ?? jest.fn(async () => []),
      } as never,
      {} as never,
      {
        applyIfPresent: jest.fn().mockResolvedValue(undefined),
      } as never,
    );
    if (overrides.syncImpl) {
      jest.spyOn(service, 'sync').mockImplementation(overrides.syncImpl);
    } else {
      jest.spyOn(service, 'sync').mockResolvedValue({
        booked: 0,
        skippedExisting: 0,
        slotsCreated: 0,
        conflicts: [],
      });
    }
    return { service, bookings };
  }

  it('возвращает 409 с existingId при active-дубликате', async () => {
    const findByPattern = jest.fn().mockResolvedValue([
      {
        id: 'existing-active',
        status: 'active',
      },
    ]);
    const { service, bookings } = buildService({ findByPattern });

    try {
      await service.create({
        coachId,
        studentId,
        weekdays: [...weekdays],
        startMinute: 600,
        mode: 'offline',
      });
      fail('ожидали ConflictException');
    } catch (error) {
      expect(error).toBeInstanceOf(ConflictException);
      expect((error as ConflictException).getResponse()).toEqual({
        message: 'Такая серия уже есть',
        existingId: 'existing-active',
      });
    }

    expect(bookings.save).not.toHaveBeenCalled();
  });

  it('реактивирует cancelled twin с тем же id', async () => {
    const cancelled = {
      id: 'cancelled-1',
      coachId,
      studentId,
      weekdays: [6],
      startMinute: 600,
      mode: 'offline' as const,
      timezone: 'Europe/Moscow',
      status: 'cancelled' as const,
      horizonWeeksOverride: 4,
      cancelledAt: new Date('2026-08-07T00:00:00.000Z'),
      createdAt: new Date('2026-08-01T00:00:00.000Z'),
      updatedAt: new Date('2026-08-07T00:00:00.000Z'),
    };
    const findByPattern = jest
      .fn()
      .mockResolvedValueOnce([]) // active
      .mockResolvedValueOnce([cancelled]); // cancelled
    const save = jest.fn(async (e: typeof cancelled) => e);
    const { service } = buildService({ findByPattern, save });

    const result = await service.create({
      coachId,
      studentId,
      weekdays: [...weekdays],
      startMinute: 600,
      mode: 'offline',
      horizonWeeksOverride: 8,
    });

    expect(result.booking.id).toBe('cancelled-1');
    expect(result.booking.status).toBe('active');
    expect(save).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 'cancelled-1',
        status: 'active',
        cancelledAt: null,
        horizonWeeksOverride: 8,
      }),
    );
  });

  it('restore поднимает cancelled и отклоняет active', async () => {
    const cancelled = {
      id: 'cancelled-1',
      coachId,
      studentId,
      weekdays: [6],
      startMinute: 600,
      mode: 'offline' as const,
      timezone: 'Europe/Moscow',
      status: 'cancelled' as const,
      horizonWeeksOverride: null,
      cancelledAt: new Date('2026-08-07T00:00:00.000Z'),
      createdAt: new Date('2026-08-01T00:00:00.000Z'),
      updatedAt: new Date('2026-08-07T00:00:00.000Z'),
    };
    const findByPattern = jest.fn().mockResolvedValue([]);
    const save = jest.fn(async (e: typeof cancelled) => e);
    const { service } = buildService({
      findByPattern,
      save,
      findByIdForCoach: jest.fn(async () => ({ ...cancelled })),
    });

    const restored = await service.restore(coachId, cancelled.id);
    expect(restored.booking.id).toBe('cancelled-1');
    expect(restored.booking.status).toBe('active');

    const { service: activeService } = buildService({
      findByPattern: jest.fn(),
      findByIdForCoach: jest.fn(async () => ({
        ...cancelled,
        status: 'active',
        cancelledAt: null,
      })),
    });
    await expect(activeService.restore(coachId, cancelled.id)).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('restore конфликтует с другим active по паттерну', async () => {
    const cancelled = {
      id: 'cancelled-1',
      coachId,
      studentId,
      weekdays: [6],
      startMinute: 600,
      mode: 'offline' as const,
      timezone: 'Europe/Moscow',
      status: 'cancelled' as const,
      horizonWeeksOverride: null,
      cancelledAt: new Date('2026-08-07T00:00:00.000Z'),
      createdAt: new Date('2026-08-01T00:00:00.000Z'),
      updatedAt: new Date('2026-08-07T00:00:00.000Z'),
    };
    const { service } = buildService({
      findByPattern: jest.fn().mockResolvedValue([
        { id: 'other-active', status: 'active' },
      ]),
      findByIdForCoach: jest.fn(async () => ({ ...cancelled })),
    });

    try {
      await service.restore(coachId, cancelled.id);
      fail('ожидали ConflictException');
    } catch (error) {
      expect(error).toBeInstanceOf(ConflictException);
      expect((error as ConflictException).getResponse()).toEqual({
        message: 'Такая серия уже есть',
        existingId: 'other-active',
      });
    }
  });
});
