import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { CalendarBookingService } from './calendar-booking.service';

describe('CalendarBookingService.bookAtTime', () => {
  const links = { findByPair: jest.fn() };
  const manager = {
    findOneOrFail: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn((_entity: unknown, data: Record<string, unknown>) => ({
      ...data,
    })),
    save: jest.fn(async (entity: Record<string, unknown>) => ({
      id: entity['id'] ?? 'generated-id',
      ...entity,
    })),
    createQueryBuilder: jest.fn(),
  };
  const dataSource = {
    transaction: jest.fn(async (cb: (m: typeof manager) => Promise<unknown>) =>
      cb(manager),
    ),
  };
  const service = new CalendarBookingService(
    dataSource as unknown as DataSource,
    links as unknown as CoachStudentLinkRepository,
  );

  const baseInput = {
    coachId: 'coach-1',
    studentId: 'student-1',
    actorId: 'coach-1',
    createdBy: 'coach' as const,
    startsAt: new Date('2026-09-01T15:00:00.000Z'),
    endsAt: new Date('2026-09-01T16:00:00.000Z'),
    mode: 'offline' as const,
  };

  // Booked slot with an active session: overlaps baseInput and is not healed.
  const occupiedSlot = {
    id: 'slot-occupied',
    coachId: 'coach-1',
    startsAt: new Date('2026-09-01T15:30:00.000Z'),
    endsAt: new Date('2026-09-01T16:30:00.000Z'),
    mode: 'offline',
    status: 'booked',
  };

  beforeEach(() => {
    jest.clearAllMocks();
    links.findByPair.mockResolvedValue({ id: 'link-1' });
    manager.findOneOrFail.mockResolvedValue({ id: 'coach-1' });
    manager.findOne.mockResolvedValue({
      coachId: 'coach-1',
      defaultSessionPriceMinor: '100000',
      currency: 'RUB',
    });
    const qb = {
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      setLock: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue([]),
      getExists: jest.fn().mockResolvedValue(false),
    };
    manager.createQueryBuilder.mockReturnValue(qb);
    manager.save.mockImplementation(async (entity: Record<string, unknown>) => {
      if (entity['status'] === 'open' || entity['coachId']) {
        return {
          id: 'slot-1',
          coachId: 'coach-1',
          startsAt: baseInput.startsAt,
          endsAt: baseInput.endsAt,
          mode: 'offline',
          status: entity['status'] ?? 'open',
          seriesId: null,
          ...entity,
        };
      }
      return { id: 'session-1', ...entity };
    });
  });

  it('создаёт слот и Session при чистом интервале', async () => {
    const session = await service.bookAtTime(baseInput);
    expect(session.id).toBeDefined();
    expect(dataSource.transaction).toHaveBeenCalledTimes(1);
    expect(links.findByPair).toHaveBeenCalledWith('coach-1', 'student-1');
  });

  it('отклоняет пересечение с occupied-слотом', async () => {
    const qb = {
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      setLock: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue([occupiedSlot]),
      getExists: jest.fn().mockResolvedValue(true),
    };
    manager.createQueryBuilder.mockReturnValue(qb);

    await expect(service.bookAtTime(baseInput)).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('отклоняет невалидный диапазон', async () => {
    await expect(
      service.bookAtTime({
        ...baseInput,
        endsAt: baseInput.startsAt,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('отклоняет несвязанного ученика', async () => {
    links.findByPair.mockResolvedValue(null);
    await expect(service.bookAtTime(baseInput)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('второй вызов на тот же интервал конфликтует (sequential)', async () => {
    await service.bookAtTime(baseInput);
    const qb = {
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      setLock: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue([occupiedSlot]),
      getExists: jest.fn().mockResolvedValue(true),
    };
    manager.createQueryBuilder.mockReturnValue(qb);
    await expect(service.bookAtTime(baseInput)).rejects.toBeInstanceOf(
      ConflictException,
    );
  });
});
