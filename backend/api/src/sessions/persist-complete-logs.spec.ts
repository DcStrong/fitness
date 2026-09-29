import { BadRequestException } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { ExerciseEntity } from '../database/entity/exercise.entity';
import { PlanExerciseEntity } from '../database/entity/plan-exercise.entity';
import { SessionWorkoutItemEntity } from '../database/entity/session-workout-item.entity';
import { SessionSetLogRepository } from '../database/repository/session-set-log.repository';
import { persistCompleteLogs } from './persist-complete-logs';

describe('persistCompleteLogs', () => {
  const insertMany = jest.fn();
  const countBySessionId = jest.fn();
  const logsRepo = {
    insertMany,
    countBySessionId,
  } as unknown as SessionSetLogRepository;
  const find = jest.fn();
  const manager = { find } as unknown as EntityManager;

  beforeEach(() => {
    jest.clearAllMocks();
    countBySessionId.mockResolvedValue(0);
    find.mockImplementation(async (entity: unknown) => {
      if (entity === ExerciseEntity) {
        return [{ id: 'ex-1' }];
      }
      return [];
    });
  });

  it('пишет явные логи', async () => {
    await persistCompleteLogs(manager, logsRepo, {
      sessionId: 's1',
      studentPlanId: 'plan-1',
      logs: [{ exerciseId: 'ex-1', sets: [{ reps: 5, weightKg: 80 }] }],
    });

    expect(find).toHaveBeenCalledWith(
      ExerciseEntity,
      expect.objectContaining({ where: expect.anything() }),
    );
    expect(insertMany).toHaveBeenCalledWith(
      manager,
      expect.arrayContaining([
        expect.objectContaining({ exerciseId: 'ex-1', reps: 5, weightKg: '80.00' }),
      ]),
    );
  });

  it('копирует prescription если logs не переданы', async () => {
    find.mockImplementation(async (entity: unknown) => {
      if (entity === PlanExerciseEntity) {
        return [
          {
            exerciseId: 'ex-1',
            sets: [
              {
                sortOrder: 0,
                reps: 10,
                weightKg: '40.00',
                durationSeconds: null,
              },
            ],
          },
        ];
      }
      return [];
    });

    await persistCompleteLogs(manager, logsRepo, {
      sessionId: 's1',
      studentPlanId: 'plan-1',
    });

    expect(find).toHaveBeenCalledWith(
      PlanExerciseEntity,
      expect.objectContaining({ where: { planId: 'plan-1' } }),
    );
    expect(insertMany).toHaveBeenCalledWith(
      manager,
      expect.arrayContaining([
        expect.objectContaining({ exerciseId: 'ex-1', reps: 10 }),
      ]),
    );
  });

  it('копирует snapshot сессии вместо живой копии', async () => {
    find.mockImplementation(async (entity: unknown) => {
      if (entity === SessionWorkoutItemEntity) {
        return [
          {
            sortOrder: 0,
            sets: [
              {
                exerciseId: 'ex-1',
                sortOrder: 0,
                reps: 5,
                weightKg: '80.00',
                durationSeconds: null,
              },
            ],
          },
        ];
      }
      if (entity === PlanExerciseEntity) {
        return [
          {
            exerciseId: 'ex-1',
            sets: [{ sortOrder: 0, reps: 10, weightKg: '40.00' }],
          },
        ];
      }

      return [];
    });

    await persistCompleteLogs(manager, logsRepo, {
      sessionId: 's1',
      studentPlanId: 'plan-1',
    });

    expect(insertMany).toHaveBeenCalledWith(
      manager,
      expect.arrayContaining([
        expect.objectContaining({
          exerciseId: 'ex-1',
          reps: 5,
          weightKg: '80.00',
        }),
      ]),
    );
  });

  it('без плана, snapshot и логов ничего не пишет', async () => {
    await persistCompleteLogs(manager, logsRepo, {
      sessionId: 's1',
      studentPlanId: null,
    });

    expect(insertMany).not.toHaveBeenCalled();
  });

  it('не меняет уже записанные логи', async () => {
    countBySessionId.mockResolvedValue(3);

    await persistCompleteLogs(manager, logsRepo, {
      sessionId: 's1',
      studentPlanId: 'plan-1',
      logs: [{ exerciseId: 'ex-1', sets: [{ reps: 1 }] }],
    });

    expect(insertMany).not.toHaveBeenCalled();
  });

  it('неизвестный exerciseId — 400', async () => {
    find.mockResolvedValue([]);

    await expect(
      persistCompleteLogs(manager, logsRepo, {
        sessionId: 's1',
        studentPlanId: null,
        logs: [{ exerciseId: 'missing', sets: [{ reps: 1 }] }],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(insertMany).not.toHaveBeenCalled();
  });
});
