import { ForbiddenException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { SessionHistoryEventRepository } from '../database/repository/session-history-event.repository';
import { SessionRepository } from '../database/repository/session.repository';
import { SessionSetLogRepository } from '../database/repository/session-set-log.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import { SessionEntity } from '../database/entity/session.entity';
import { SessionLifecycleService } from './session-lifecycle.service';

jest.mock('../session-packages/apply-session-package-debit', () => ({
  applySessionPackageDebit: jest.fn().mockResolvedValue({ packageExhausted: false }),
}));

describe('SessionLifecycleService complete/cancel', () => {
  const booked = {
    id: 's1',
    coachId: 'coach-1',
    studentId: 'student-1',
    status: 'booked',
    studentPlanId: null,
    scheduleSlotId: null,
    startsAt: new Date(),
    endsAt: new Date(),
    mode: 'offline',
    createdBy: 'coach',
    createdAt: new Date(),
  };

  const findOne = jest.fn();
  const save = jest.fn(async (value: unknown) => value);
  const create = jest.fn((_cls: unknown, data: unknown) => data);
  const manager = { findOne, save, create };
  const dataSource = {
    transaction: jest.fn(async (cb: (em: typeof manager) => Promise<unknown>) =>
      cb(manager),
    ),
  };
  const sessions = { findByIdWithPeople: jest.fn() };
  const history = {};
  const profiles = { findByUserIds: jest.fn().mockResolvedValue([]) };
  const setLogs = { countBySessionId: jest.fn(), insertMany: jest.fn() };
  const workoutItems = { findBySessionId: jest.fn().mockResolvedValue([]) };
  const service = new SessionLifecycleService(
    dataSource as unknown as DataSource,
    sessions as unknown as SessionRepository,
    history as unknown as SessionHistoryEventRepository,
    profiles as unknown as UserProfileRepository,
    setLogs as unknown as SessionSetLogRepository,
    workoutItems as unknown as import('../database/repository/session-workout-item.repository').SessionWorkoutItemRepository,
  );

  beforeEach(() => {
    jest.clearAllMocks();
    findOne.mockImplementation((entity: unknown) => {
      if (entity === SessionEntity) {
        return Promise.resolve({ ...booked });
      }

      return Promise.resolve(null);
    });
    sessions.findByIdWithPeople.mockResolvedValue({ ...booked, status: 'completed' });
    setLogs.countBySessionId.mockResolvedValue(0);
    dataSource.transaction.mockImplementation(
      async (cb: (em: typeof manager) => Promise<unknown>) => cb(manager),
    );
  });

  it('отклоняет complete не-тренера сессии', async () => {
    await expect(
      service.complete(
        { id: 'other', permissions: ['sessions:complete'] },
        { sessionId: 's1' },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('отклоняет complete без permission', async () => {
    await expect(
      service.complete({ id: 'coach-1', permissions: [] }, { sessionId: 's1' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('cancel не пишет логи', async () => {
    sessions.findByIdWithPeople.mockResolvedValue({
      ...booked,
      status: 'cancelled',
    });

    await service.cancel(
      { id: 'coach-1', permissions: ['sessions:cancel'] },
      { sessionId: 's1' },
    );

    expect(setLogs.insertMany).not.toHaveBeenCalled();
    expect(setLogs.countBySessionId).not.toHaveBeenCalled();
  });
});
