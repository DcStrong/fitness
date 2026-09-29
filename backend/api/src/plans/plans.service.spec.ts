import {
  ForbiddenException,
} from '@nestjs/common';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { ExerciseRepository } from '../database/repository/exercise.repository';
import { PlanExerciseRepository } from '../database/repository/plan-exercise.repository';
import { TagRepository } from '../database/repository/tag.repository';
import { TrainingPlanRepository } from '../database/repository/training-plan.repository';
import { TrainingPlanTagRepository } from '../database/repository/training-plan-tag.repository';
import { UserTagRepository } from '../database/repository/user-tag.repository';
import { PlansService } from './plans.service';

describe('Сервис планов со структурой', () => {
  const plans = {
    create: jest.fn(),
    save: jest.fn(),
    findById: jest.fn(),
    findByOwner: jest.fn(),
    findCatalogSeeds: jest.fn(),
    findStudentCopy: jest.fn(),
    findAssignedCopies: jest.fn(),
    deleteById: jest.fn(),
  };
  const planTags = {
    replaceForPlan: jest.fn(),
    findByPlanId: jest.fn(),
    findByPlanIds: jest.fn(),
  };
  const planExercises = {
    replaceForPlan: jest.fn(),
    findByPlanId: jest.fn(),
    findByPlanIds: jest.fn(),
  };
  const exercises = {
    findByIds: jest.fn(),
  };
  const tags = {
    findByIdsForCreator: jest.fn(),
  };
  const userTags = {
    findTagsForUser: jest.fn(),
    findUserIdsByTagIds: jest.fn(),
  };
  const links = {
    findByPair: jest.fn(),
    findForUser: jest.fn(),
  };

  const service = new PlansService(
    plans as unknown as TrainingPlanRepository,
    planTags as unknown as TrainingPlanTagRepository,
    planExercises as unknown as PlanExerciseRepository,
    exercises as unknown as ExerciseRepository,
    tags as unknown as TagRepository,
    userTags as unknown as UserTagRepository,
    links as unknown as CoachStudentLinkRepository,
  );

  const now = new Date('2026-08-18T10:00:00.000Z');
  const ownedPlan = {
    id: 'plan-1',
    ownerCoachId: 'coach-1',
    title: 'Верх',
    body: 'заметка',
    kind: 'template' as const,
    goal: 'hypertrophy' as const,
    parentTemplateId: null,
    assignedStudentId: null,
    createdAt: now,
    updatedAt: now,
    ownerCoach: { email: 'coach@test.com' },
  };

  beforeEach(() => {
    jest.clearAllMocks();
    tags.findByIdsForCreator.mockResolvedValue([{ id: 'tag-1' }]);
    exercises.findByIds.mockResolvedValue([
      { id: 'ex-1', ownerCoachId: 'coach-1', name: 'Жим', kind: 'weight_reps' },
    ]);
    plans.create.mockImplementation(data => data);
    plans.save.mockResolvedValue(ownedPlan);
    plans.findById.mockResolvedValue(ownedPlan);
    planTags.replaceForPlan.mockResolvedValue(undefined);
    planExercises.replaceForPlan.mockResolvedValue(undefined);
    planTags.findByPlanId.mockResolvedValue([
      { tag: { id: 'tag-1', name: 'Верх' } },
    ]);
    planExercises.findByPlanId.mockResolvedValue([
      {
        id: 'pe-1',
        planId: 'plan-1',
        exerciseId: 'ex-1',
        exercise: { name: 'Жим', kind: 'weight_reps' },
        sortOrder: 0,
        restSeconds: 90,
        notes: '',
        sets: [
          {
            id: 'set-1',
            sortOrder: 0,
            reps: 10,
            weightKg: '20.00',
            durationSeconds: null,
          },
        ],
      },
    ]);
    planTags.findByPlanIds.mockResolvedValue([]);
    planExercises.findByPlanIds.mockResolvedValue([]);
    userTags.findUserIdsByTagIds.mockResolvedValue([]);
    links.findForUser.mockResolvedValue([]);
  });

  it('создаёт шаблон с nested упражнениями и тегами', async () => {
    const result = await service.create('coach-1', {
      title: 'Верх',
      notes: 'заметка',
      goal: 'hypertrophy',
      tagIds: ['tag-1'],
      exercises: [
        {
          exerciseId: 'ex-1',
          restSeconds: 90,
          sets: [{ reps: 10, weightKg: 20 }],
        },
      ],
    });

    expect(plans.create).toHaveBeenCalledWith(
      expect.objectContaining({
        ownerCoachId: 'coach-1',
        kind: 'template',
        goal: 'hypertrophy',
        body: 'заметка',
      }),
    );
    expect(planExercises.replaceForPlan).toHaveBeenCalledWith(
      'plan-1',
      expect.arrayContaining([
        expect.objectContaining({
          exerciseId: 'ex-1',
          restSeconds: 90,
          sets: [expect.objectContaining({ reps: 10, weightKg: 20 })],
        }),
      ]),
    );
    expect(result.notes).toBe('заметка');
    expect(result.body).toBe('заметка');
    expect(result.exercises).toHaveLength(1);
    expect(result.tags).toEqual([{ id: 'tag-1', name: 'Верх' }]);
  });

  it('создаёт student_copy, если задан assignedStudentId связанного ученика', async () => {
    links.findByPair.mockResolvedValue({
      coachId: 'coach-1',
      studentId: 'student-1',
    });
    tags.findByIdsForCreator.mockResolvedValue([]);
    exercises.findByIds.mockResolvedValue([]);
    const copy = {
      ...ownedPlan,
      kind: 'student_copy' as const,
      assignedStudentId: 'student-1',
    };
    plans.save.mockResolvedValue(copy);
    plans.findById.mockResolvedValue(copy);
    planTags.findByPlanId.mockResolvedValue([]);
    planExercises.findByPlanId.mockResolvedValue([]);

    await service.create('coach-1', {
      title: 'Занятие · Иван',
      assignedStudentId: 'student-1',
    });

    expect(plans.create).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'student_copy',
        assignedStudentId: 'student-1',
        parentTemplateId: null,
      }),
    );
  });

  it('отклоняет student_copy без связки тренер–ученик', async () => {
    links.findByPair.mockResolvedValue(null);

    await expect(
      service.create('coach-1', {
        title: 'Занятие',
        assignedStudentId: 'student-1',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(plans.save).not.toHaveBeenCalled();
  });

  it('заменяет список упражнений при PATCH', async () => {
    await service.update('coach-1', {
      planId: 'plan-1',
      exercises: [{ exerciseId: 'ex-1', sets: [{ reps: 12 }] }],
    });

    expect(planExercises.replaceForPlan).toHaveBeenCalledWith(
      'plan-1',
      expect.arrayContaining([
        expect.objectContaining({
          exerciseId: 'ex-1',
          sets: [expect.objectContaining({ reps: 12 })],
        }),
      ]),
    );
  });

  it('в списке своих отдаёт только template, каталог — отдельно', async () => {
    plans.findByOwner.mockResolvedValue([ownedPlan]);
    plans.findCatalogSeeds.mockResolvedValue([
      { ...ownedPlan, id: 'cat-1', kind: 'catalog_seed' },
    ]);

    await service.listOwn('coach-1');
    expect(plans.findByOwner).toHaveBeenCalledWith('coach-1', 'template');

    await service.listOwn('coach-1', 'catalog');
    expect(plans.findCatalogSeeds).toHaveBeenCalled();
  });

  it('клонирует каталог в свой шаблон и не мутирует исходный', async () => {
    const catalog = {
      ...ownedPlan,
      id: 'cat-1',
      kind: 'catalog_seed' as const,
      ownerCoachId: 'catalog-owner',
    };
    plans.findById
      .mockResolvedValueOnce(catalog)
      .mockResolvedValueOnce({ ...ownedPlan, id: 'clone-1' });
    plans.save.mockResolvedValue({ ...ownedPlan, id: 'clone-1' });
    planExercises.findByPlanId
      .mockResolvedValueOnce([
        {
          id: 'pe-cat',
          planId: 'cat-1',
          exerciseId: 'ex-1',
          restSeconds: 90,
          notes: '',
          sets: [
            {
              id: 's1',
              sortOrder: 0,
              reps: 10,
              weightKg: null,
              durationSeconds: null,
            },
          ],
        },
      ])
      .mockResolvedValueOnce([]);
    planTags.findByPlanId.mockResolvedValue([]);

    const cloned = await service.cloneCatalog('coach-1', 'cat-1');
    expect(plans.create).toHaveBeenCalledWith(
      expect.objectContaining({
        ownerCoachId: 'coach-1',
        kind: 'template',
        goal: 'hypertrophy',
        parentTemplateId: null,
      }),
    );
    expect(planExercises.replaceForPlan).toHaveBeenCalledWith(
      'clone-1',
      expect.arrayContaining([
        expect.objectContaining({ exerciseId: 'ex-1' }),
      ]),
    );
    expect(cloned.id).toBe('clone-1');
  });

  it('запрещает PATCH/DELETE каталога и чужого шаблона', async () => {
    plans.findById.mockResolvedValue({
      ...ownedPlan,
      kind: 'catalog_seed',
    });
    await expect(
      service.update('coach-1', { planId: 'cat-1', title: 'X' }),
    ).rejects.toBeInstanceOf(ForbiddenException);

    plans.findById.mockResolvedValue({
      ...ownedPlan,
      ownerCoachId: 'other',
    });
    await expect(
      service.update('coach-1', { planId: 'plan-1', title: 'X' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('отдаёт notes из legacy body', async () => {
    planExercises.findByPlanId.mockResolvedValue([]);
    planTags.findByPlanId.mockResolvedValue([]);
    const result = await service.getById('coach-1', 'plan-1');
    expect(result.notes).toBe('заметка');
    expect(result.body).toBe('заметка');
    expect(result.exercises).toEqual([]);
  });

  it('назначает шаблон одному ученику как student_copy', async () => {
    links.findForUser.mockResolvedValue([
      { coachId: 'coach-1', studentId: 'student-1' },
    ]);
    userTags.findUserIdsByTagIds.mockResolvedValue([]);
    plans.findStudentCopy.mockResolvedValue(null);
    const copy = {
      ...ownedPlan,
      id: 'copy-1',
      kind: 'student_copy' as const,
      parentTemplateId: 'plan-1',
      assignedStudentId: 'student-1',
    };
    plans.save.mockResolvedValue(copy);
    plans.findById
      .mockResolvedValueOnce(ownedPlan)
      .mockResolvedValueOnce(copy);
    planTags.findByPlanId.mockResolvedValue([{ tagId: 'tag-1' }]);
    planExercises.findByPlanId.mockResolvedValue([
      {
        id: 'pe-1',
        planId: 'plan-1',
        exerciseId: 'ex-1',
        restSeconds: 90,
        notes: '',
        sets: [
          {
            id: 'set-1',
            sortOrder: 0,
            reps: 10,
            weightKg: '20.00',
            durationSeconds: null,
          },
        ],
      },
    ]);

    const result = await service.assign('coach-1', {
      planId: 'plan-1',
      studentIds: ['student-1'],
    });

    expect(plans.create).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'student_copy',
        parentTemplateId: 'plan-1',
        assignedStudentId: 'student-1',
        title: 'Верх',
      }),
    );
    expect(result).toHaveLength(1);
    expect(result[0]?.id).toBe('copy-1');
    expect(ownedPlan.kind).toBe('template');
  });

  it('повторный assign возвращает существующую копию', async () => {
    links.findForUser.mockResolvedValue([
      { coachId: 'coach-1', studentId: 'student-1' },
    ]);
    userTags.findUserIdsByTagIds.mockResolvedValue([]);
    const copy = {
      ...ownedPlan,
      id: 'copy-1',
      kind: 'student_copy' as const,
      parentTemplateId: 'plan-1',
      assignedStudentId: 'student-1',
    };
    plans.findStudentCopy.mockResolvedValue(copy);
    plans.findById.mockResolvedValueOnce(ownedPlan).mockResolvedValueOnce(copy);

    const result = await service.assign('coach-1', {
      planId: 'plan-1',
      studentIds: ['student-1'],
    });

    expect(plans.save).not.toHaveBeenCalled();
    expect(result[0]?.id).toBe('copy-1');
  });

  it('назначает через тег двум связанным ученикам', async () => {
    links.findForUser.mockResolvedValue([
      { coachId: 'coach-1', studentId: 'student-1' },
      { coachId: 'coach-1', studentId: 'student-2' },
    ]);
    userTags.findUserIdsByTagIds.mockResolvedValue(['student-1', 'student-2']);
    plans.findStudentCopy.mockResolvedValue(null);
    plans.save
      .mockResolvedValueOnce({
        ...ownedPlan,
        id: 'copy-1',
        kind: 'student_copy',
        assignedStudentId: 'student-1',
      })
      .mockResolvedValueOnce({
        ...ownedPlan,
        id: 'copy-2',
        kind: 'student_copy',
        assignedStudentId: 'student-2',
      });
    plans.findById
      .mockResolvedValueOnce(ownedPlan)
      .mockResolvedValueOnce({
        ...ownedPlan,
        id: 'copy-1',
        kind: 'student_copy',
      })
      .mockResolvedValueOnce({
        ...ownedPlan,
        id: 'copy-2',
        kind: 'student_copy',
      });
    planTags.findByPlanId.mockResolvedValue([]);
    planExercises.findByPlanId.mockResolvedValue([]);

    const result = await service.assign('coach-1', {
      planId: 'plan-1',
      tagIds: ['tag-1'],
    });

    expect(result).toHaveLength(2);
    expect(plans.save).toHaveBeenCalledTimes(2);
  });

  it('отклоняет assign несвязанному ученику', async () => {
    links.findForUser.mockResolvedValue([]);
    userTags.findUserIdsByTagIds.mockResolvedValue([]);

    await expect(
      service.assign('coach-1', {
        planId: 'plan-1',
        studentIds: ['stranger-1'],
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(plans.save).not.toHaveBeenCalled();
  });

  it('правит копию ученика, не трогая шаблон', async () => {
    const copy = {
      ...ownedPlan,
      id: 'copy-1',
      kind: 'student_copy' as const,
      parentTemplateId: 'plan-1',
      assignedStudentId: 'student-1',
    };
    plans.findById.mockResolvedValue(copy);

    await service.update('coach-1', {
      planId: 'copy-1',
      exercises: [{ exerciseId: 'ex-1', sets: [{ reps: 6 }] }],
    });

    expect(plans.save).toHaveBeenCalledWith(copy);
    expect(planExercises.replaceForPlan).toHaveBeenCalledWith(
      'copy-1',
      expect.arrayContaining([
        expect.objectContaining({
          sets: [expect.objectContaining({ reps: 6 })],
        }),
      ]),
    );
  });

  it('запрещает ученику PATCH своей копии', async () => {
    plans.findById.mockResolvedValue({
      ...ownedPlan,
      id: 'copy-1',
      kind: 'student_copy',
      ownerCoachId: 'coach-1',
      assignedStudentId: 'student-1',
    });

    await expect(
      service.update('student-1', { planId: 'copy-1', title: 'X' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('назначает два шаблона одному ученику', async () => {
    const second = { ...ownedPlan, id: 'plan-2', title: 'Низ' };
    links.findByPair.mockResolvedValue({ coachId: 'coach-1', studentId: 'student-1' });
    plans.findStudentCopy.mockResolvedValue(null);
    plans.findById
      .mockResolvedValueOnce(ownedPlan)
      .mockResolvedValueOnce(second)
      .mockResolvedValueOnce({
        ...ownedPlan,
        id: 'copy-1',
        kind: 'student_copy',
      })
      .mockResolvedValueOnce({
        ...second,
        id: 'copy-2',
        kind: 'student_copy',
      });
    planTags.findByPlanId.mockResolvedValue([]);
    planExercises.findByPlanId.mockResolvedValue([]);

    const result = await service.assignBatch('coach-1', {
      studentId: 'student-1',
      planIds: ['plan-1', 'plan-2'],
    });

    expect(result).toHaveLength(2);
    expect(plans.save).toHaveBeenCalledTimes(2);
  });

  it('отклоняет batch несвязанному ученику без копий', async () => {
    links.findByPair.mockResolvedValue(null);

    await expect(
      service.assignBatch('coach-1', {
        studentId: 'stranger-1',
        planIds: ['plan-1', 'plan-2'],
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(plans.findById).not.toHaveBeenCalled();
    expect(plans.save).not.toHaveBeenCalled();
  });

  it('меняет веса на копии, не трогая шаблон', async () => {
    const copy = {
      ...ownedPlan,
      id: 'copy-1',
      kind: 'student_copy' as const,
      parentTemplateId: 'plan-1',
      assignedStudentId: 'student-1',
    };
    plans.findById.mockResolvedValue(copy);
    planExercises.findByPlanId.mockResolvedValue([
      {
        id: 'pe-1',
        planId: 'copy-1',
        exerciseId: 'ex-1',
        exercise: { name: 'Жим', kind: 'weight_reps' },
        sortOrder: 0,
        restSeconds: 90,
        notes: '',
        sets: [{ id: 'set-1', sortOrder: 0, reps: 10, weightKg: '40.00', durationSeconds: null }],
      },
    ]);

    await service.updateLoads('coach-1', {
      planId: 'copy-1',
      items: [{ exerciseId: 'ex-1', weightKg: 80 }],
    });

    expect(planExercises.replaceForPlan).toHaveBeenCalledWith(
      'copy-1',
      expect.arrayContaining([
        expect.objectContaining({
          exerciseId: 'ex-1',
          sets: [expect.objectContaining({ weightKg: 80 })],
        }),
      ]),
    );
    expect(plans.save).not.toHaveBeenCalledWith(
      expect.objectContaining({ id: 'plan-1' }),
    );
  });
});
