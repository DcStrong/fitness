import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { CalendarBookingService } from '../calendar/calendar-booking.service';
import { SessionRepository } from '../database/repository/session.repository';
import { SessionsService } from './sessions.service';
import { BookingRequestsService } from '../booking-requests/booking-requests.service';

describe('Сервис бронирования тренировок', () => {
  const booking = { book: jest.fn(), bookAtTime: jest.fn() };
  const sessions = {
    findByIdWithPeople: jest.fn(),
    updateStudentPlanId: jest.fn(),
  };
  const bookingRequests = { expireDue: jest.fn().mockResolvedValue({ expiredCount: 0 }) };
  const profiles = { findByUserIds: jest.fn().mockResolvedValue([]) };
  const plans = { getById: jest.fn() };
  const workoutItems = {
    findBySessionIds: jest.fn().mockResolvedValue([]),
    findBySessionId: jest.fn().mockResolvedValue([]),
    replaceForSession: jest.fn().mockResolvedValue(undefined),
  };
  const service = new SessionsService(
    booking as unknown as CalendarBookingService,
    sessions as unknown as SessionRepository,
    bookingRequests as unknown as BookingRequestsService,
    profiles as unknown as import('../database/repository/user-profile.repository').UserProfileRepository,
    plans as unknown as import('../plans/plans.service').PlansService,
    workoutItems as unknown as import('../database/repository/session-workout-item.repository').SessionWorkoutItemRepository,
  );

  beforeEach(() => jest.clearAllMocks());

  it('отклоняет прямую запись студента со старым permission', async () => {
    await expect(
      service.book(
        {
          id: 'student-1',
          roles: ['student'],
          permissions: ['sessions:book_self'],
        },
        { scheduleSlotId: 'slot-1' },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(booking.book).not.toHaveBeenCalled();
  });

  it('сохраняет прямую запись тренером на слот', async () => {
    booking.book.mockResolvedValue({
      id: 'session-1',
      coachId: 'coach-1',
      studentId: 'student-1',
      scheduleSlotId: 'slot-1',
      startsAt: new Date('2026-07-21T10:00:00.000Z'),
      endsAt: new Date('2026-07-21T11:00:00.000Z'),
      mode: 'offline',
      status: 'booked',
      createdBy: 'coach',
      createdAt: new Date('2026-07-20T10:00:00.000Z'),
    });
    sessions.findByIdWithPeople.mockResolvedValue(null);

    await expect(
      service.book(
        {
          id: 'coach-1',
          roles: ['trainer'],
          permissions: ['sessions:book_for_student'],
        },
        { scheduleSlotId: 'slot-1', studentId: 'student-1' },
      ),
    ).resolves.toMatchObject({ id: 'session-1', createdBy: 'coach' });
    expect(booking.book).toHaveBeenCalledTimes(1);
  });

  it('записывает ученика на произвольное время через bookAtTime', async () => {
    booking.bookAtTime.mockResolvedValue({
      id: 'session-2',
      coachId: 'coach-1',
      studentId: 'student-1',
      scheduleSlotId: 'slot-new',
      startsAt: new Date('2026-09-01T15:00:00.000Z'),
      endsAt: new Date('2026-09-01T16:00:00.000Z'),
      mode: 'offline',
      status: 'booked',
      createdBy: 'coach',
      createdAt: new Date('2026-08-04T10:00:00.000Z'),
    });
    sessions.findByIdWithPeople.mockResolvedValue(null);

    await expect(
      service.book(
        {
          id: 'coach-1',
          roles: ['trainer'],
          permissions: ['sessions:book_for_student'],
        },
        {
          startsAt: '2026-09-01T15:00:00.000Z',
          endsAt: '2026-09-01T16:00:00.000Z',
          mode: 'offline',
          studentId: 'student-1',
        },
      ),
    ).resolves.toMatchObject({ id: 'session-2' });
    expect(booking.bookAtTime).toHaveBeenCalledTimes(1);
    expect(booking.book).not.toHaveBeenCalled();
  });

  const bookedSession = {
    id: 'session-1',
    coachId: 'coach-1',
    studentId: 'student-1',
    scheduleSlotId: 'slot-1',
    startsAt: new Date('2026-07-21T10:00:00.000Z'),
    endsAt: new Date('2026-07-21T11:00:00.000Z'),
    mode: 'offline' as const,
    status: 'booked' as const,
    createdBy: 'coach' as const,
    createdAt: new Date('2026-07-20T10:00:00.000Z'),
    studentPlanId: null as string | null,
  };

  it('привязывает копию ученика к сессии', async () => {
    sessions.findByIdWithPeople.mockResolvedValue(bookedSession);
    sessions.updateStudentPlanId.mockResolvedValue(undefined);
    plans.getById.mockResolvedValue({
      id: 'copy-1',
      kind: 'student_copy',
      assignedStudentId: 'student-1',
      ownerCoachId: 'coach-1',
      title: 'Верх',
      goal: 'hypertrophy',
      tags: [],
      exercises: [],
    });
    sessions.findByIdWithPeople
      .mockResolvedValueOnce(bookedSession)
      .mockResolvedValueOnce({ ...bookedSession, studentPlanId: 'copy-1' });
    workoutItems.findBySessionIds.mockResolvedValue([
      {
        sessionId: 'session-1',
        studentPlanId: 'copy-1',
        sortOrder: 0,
        source: 'manual',
        overrideAt: new Date(),
        studentPlan: { title: 'Верх', goal: 'hypertrophy' },
        sets: [],
      },
    ]);

    const result = await service.patchStudentPlan({
      actorId: 'coach-1',
      permissions: ['sessions:book_for_student'],
      sessionId: 'session-1',
      studentPlanId: 'copy-1',
    });

    expect(workoutItems.replaceForSession).toHaveBeenCalledWith(
      'session-1',
      expect.arrayContaining([
        expect.objectContaining({ studentPlanId: 'copy-1', source: 'manual' }),
      ]),
    );
    expect(result.studentPlanId).toBe('copy-1');
    expect(result.workouts).toHaveLength(1);
  });

  it('отклоняет копию другого ученика', async () => {
    sessions.findByIdWithPeople.mockResolvedValue(bookedSession);
    plans.getById.mockResolvedValue({
      id: 'copy-2',
      kind: 'student_copy',
      assignedStudentId: 'other-student',
      ownerCoachId: 'coach-1',
    });

    await expect(
      service.patchStudentPlan({
        actorId: 'coach-1',
        permissions: ['sessions:book_for_student'],
        sessionId: 'session-1',
        studentPlanId: 'copy-2',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(workoutItems.replaceForSession).not.toHaveBeenCalled();
  });

  it('запрещает ученику привязывать план', async () => {
    await expect(
      service.patchStudentPlan({
        actorId: 'student-1',
        permissions: ['sessions:book_self'],
        sessionId: 'session-1',
        studentPlanId: 'copy-1',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('отвязывает план через null', async () => {
    sessions.findByIdWithPeople
      .mockResolvedValueOnce({
        ...bookedSession,
        studentPlanId: 'copy-1',
      })
      .mockResolvedValueOnce({
        ...bookedSession,
        studentPlanId: null,
      });
    sessions.updateStudentPlanId.mockResolvedValue(undefined);
    workoutItems.replaceForSession.mockResolvedValue(undefined);

    const result = await service.patchStudentPlan({
      actorId: 'coach-1',
      permissions: ['sessions:book_for_student'],
      sessionId: 'session-1',
      studentPlanId: null,
    });

    expect(workoutItems.replaceForSession).toHaveBeenCalledWith(
      'session-1',
      [],
    );
    expect(result.studentPlanId).toBeNull();
  });

  it('вешает две копии на одно занятие', async () => {
    sessions.findByIdWithPeople.mockResolvedValue(bookedSession);
    plans.getById
      .mockResolvedValueOnce({
        id: 'copy-1',
        kind: 'student_copy',
        assignedStudentId: 'student-1',
        ownerCoachId: 'coach-1',
        title: 'Силовая',
        goal: 'hypertrophy',
        exercises: [],
      })
      .mockResolvedValueOnce({
        id: 'copy-2',
        kind: 'student_copy',
        assignedStudentId: 'student-1',
        ownerCoachId: 'coach-1',
        title: 'Кор',
        goal: 'general',
        exercises: [],
      });
    workoutItems.findBySessionIds.mockResolvedValue([
      {
        sessionId: 'session-1',
        studentPlanId: 'copy-1',
        sortOrder: 0,
        source: 'manual',
        overrideAt: new Date(),
        studentPlan: { title: 'Силовая', goal: 'hypertrophy' },
        sets: [],
      },
      {
        sessionId: 'session-1',
        studentPlanId: 'copy-2',
        sortOrder: 1,
        source: 'manual',
        overrideAt: new Date(),
        studentPlan: { title: 'Кор', goal: 'general' },
        sets: [],
      },
    ]);

    const result = await service.patchStudentPlan({
      actorId: 'coach-1',
      permissions: ['sessions:book_for_student'],
      sessionId: 'session-1',
      workoutPlanIds: ['copy-1', 'copy-2'],
    });

    expect(workoutItems.replaceForSession).toHaveBeenCalledWith(
      'session-1',
      [
        expect.objectContaining({ studentPlanId: 'copy-1' }),
        expect.objectContaining({ studentPlanId: 'copy-2' }),
      ],
    );
    expect(result.workouts).toHaveLength(2);
    expect(result.workouts[0]?.title).toBe('Силовая');
  });

  it('правка кг на сессии ставит override и не трогает другие тренировки', async () => {
    sessions.findByIdWithPeople
      .mockResolvedValueOnce(bookedSession)
      .mockResolvedValueOnce({ ...bookedSession, studentPlanId: 'copy-1' });
    workoutItems.findBySessionId = jest.fn().mockResolvedValue([
      {
        sessionId: 'session-1',
        studentPlanId: 'copy-1',
        sortOrder: 0,
        source: 'program',
        overrideAt: null,
        studentPlan: { title: 'Силовая', goal: 'hypertrophy' },
        sets: [
          {
            exerciseId: 'ex-bench',
            exerciseName: 'Жим',
            exerciseKind: 'weight_reps',
            sortOrder: 0,
            reps: 8,
            weightKg: '80.00',
            durationSeconds: null,
          },
        ],
      },
      {
        sessionId: 'session-1',
        studentPlanId: 'copy-2',
        sortOrder: 1,
        source: 'program',
        overrideAt: null,
        studentPlan: { title: 'Ноги', goal: 'hypertrophy' },
        sets: [
          {
            exerciseId: 'ex-squat',
            exerciseName: 'Присед',
            exerciseKind: 'weight_reps',
            sortOrder: 0,
            reps: 8,
            weightKg: '100.00',
            durationSeconds: null,
          },
        ],
      },
    ]);
    workoutItems.findBySessionIds.mockResolvedValue([
      {
        sessionId: 'session-1',
        studentPlanId: 'copy-1',
        sortOrder: 0,
        source: 'program',
        overrideAt: new Date(),
        studentPlan: { title: 'Силовая', goal: 'hypertrophy' },
        sets: [],
      },
    ]);

    await service.patchWorkoutLoads({
      actorId: 'coach-1',
      permissions: ['sessions:book_for_student'],
      sessionId: 'session-1',
      studentPlanId: 'copy-1',
      items: [{ exerciseId: 'ex-bench', weightKg: 85 }],
    });

    expect(workoutItems.replaceForSession).toHaveBeenCalledWith(
      'session-1',
      [
        expect.objectContaining({
          studentPlanId: 'copy-1',
          overrideAt: expect.any(Date),
          sets: [expect.objectContaining({ exerciseId: 'ex-bench', weightKg: 85 })],
        }),
        expect.objectContaining({
          studentPlanId: 'copy-2',
          overrideAt: null,
          sets: [expect.objectContaining({ exerciseId: 'ex-squat', weightKg: 100 })],
        }),
      ],
    );
  });
});
