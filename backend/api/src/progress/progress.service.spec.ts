import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { SessionSetLogRepository } from '../database/repository/session-set-log.repository';
import { UserRepository } from '../database/repository/user.repository';
import { ProgressService } from './progress.service';

describe('ProgressService', () => {
  const links = { findByPair: jest.fn() };
  const logs = {
    findLoggedExercises: jest.fn(),
    findCompletedLogsForExercise: jest.fn(),
    findLastPlanGoalForExercise: jest.fn(),
  };
  const users = { findById: jest.fn() };
  const service = new ProgressService(
    links as unknown as CoachStudentLinkRepository,
    logs as unknown as SessionSetLogRepository,
    users as unknown as UserRepository,
  );

  beforeEach(() => {
    jest.clearAllMocks();
    users.findById.mockResolvedValue({ id: 'student-1' });
    links.findByPair.mockResolvedValue({ coachId: 'coach-1', studentId: 'student-1' });
  });

  it('отдаёт две точки после двух completed сессий', async () => {
    logs.findCompletedLogsForExercise.mockResolvedValue([
      {
        sessionId: 's1',
        coachId: 'coach-1',
        completedAt: new Date('2026-08-01T10:00:00.000Z'),
        reps: 10,
        weightKg: '40',
      },
      {
        sessionId: 's2',
        coachId: 'coach-1',
        completedAt: new Date('2026-08-08T10:00:00.000Z'),
        reps: 8,
        weightKg: '50',
      },
    ]);
    logs.findLastPlanGoalForExercise.mockResolvedValue('hypertrophy');

    const result = await service.getProgress({
      actorId: 'coach-1',
      studentId: 'student-1',
      exerciseId: 'ex-1',
    });

    expect(result).toMatchObject({
      exerciseId: 'ex-1',
      goal: 'hypertrophy',
    });
    expect('points' in result && result.points).toHaveLength(2);
    expect(logs.findCompletedLogsForExercise).toHaveBeenCalledWith({
      studentId: 'student-1',
      exerciseId: 'ex-1',
      coachId: 'coach-1',
    });
  });

  it('без exerciseId отдаёт каталог упражнений', async () => {
    logs.findLoggedExercises.mockResolvedValue([
      { exerciseId: 'ex-1', name: 'Жим', sessionCount: 2 },
    ]);

    await expect(
      service.getProgress({
        actorId: 'coach-1',
        studentId: 'student-1',
      }),
    ).resolves.toEqual({
      exercises: [{ exerciseId: 'ex-1', name: 'Жим', sessionCount: 2 }],
    });
  });

  it('чужому пользователю отвечает 403', async () => {
    links.findByPair.mockResolvedValue(null);

    await expect(
      service.getProgress({
        actorId: 'stranger',
        studentId: 'student-1',
        exerciseId: 'ex-1',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('ученик читает свои точки', async () => {
    logs.findCompletedLogsForExercise.mockResolvedValue([]);
    logs.findLastPlanGoalForExercise.mockResolvedValue(null);

    await expect(
      service.getProgress({
        actorId: 'student-1',
        studentId: 'student-1',
        exerciseId: 'ex-1',
      }),
    ).resolves.toMatchObject({ exerciseId: 'ex-1', points: [] });
    expect(links.findByPair).not.toHaveBeenCalled();
  });

  it('неизвестный goal плана не прокидывает в ответ', async () => {
    logs.findCompletedLogsForExercise.mockResolvedValue([]);
    logs.findLastPlanGoalForExercise.mockResolvedValue('not-a-goal');

    await expect(
      service.getProgress({
        actorId: 'coach-1',
        studentId: 'student-1',
        exerciseId: 'ex-1',
      }),
    ).resolves.toMatchObject({ exerciseId: 'ex-1', goal: null });
  });

  it('несуществующий ученик — 404', async () => {
    users.findById.mockResolvedValue(null);

    await expect(
      service.getProgress({
        actorId: 'coach-1',
        studentId: 'missing',
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
