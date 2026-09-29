import { BadRequestException } from '@nestjs/common';
import { WorkoutProgramsService } from './workout-programs.service';

describe('Сервис программ тренировок', () => {
  const bookings = {
    findById: jest.fn(),
  };
  const programs = {
    findByRecurringBookingId: jest.fn(),
    save: jest.fn(),
    create: jest.fn(),
    replaceContents: jest.fn(),
    findById: jest.fn(),
  };
  const sessions = {
    findBookedByRecurringInRange: jest.fn().mockResolvedValue([]),
  };
  const workoutItems = {
    sessionIsOverridden: jest.fn().mockResolvedValue(false),
    replaceForSession: jest.fn(),
    findBySessionId: jest.fn(),
  };
  const plans = {
    assign: jest.fn(),
    getById: jest.fn(),
    updateLoads: jest.fn(),
  };
  const setLogs = { findBySessionId: jest.fn() };

  const service = new WorkoutProgramsService(
    bookings as never,
    programs as never,
    sessions as never,
    workoutItems as never,
    plans as never,
    setLogs as never,
  );

  beforeEach(() => jest.clearAllMocks());

  it('отклоняет weekday вне серии', async () => {
    bookings.findById.mockResolvedValue({
      id: 'rb-1',
      coachId: 'coach-1',
      studentId: 'student-1',
      weekdays: [1, 4, 6],
      status: 'active',
      timezone: 'Europe/Moscow',
    });

    await expect(
      service.upsert({
        coachId: 'coach-1',
        recurringBookingId: 'rb-1',
        days: [{ weekday: 2, items: [{ templateId: 'tpl-1' }] }],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(programs.save).not.toHaveBeenCalled();
  });
});
