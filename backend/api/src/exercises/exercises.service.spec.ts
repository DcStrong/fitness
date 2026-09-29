import {
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { ExerciseRepository } from '../database/repository/exercise.repository';
import { ExerciseTagRepository } from '../database/repository/exercise-tag.repository';
import { PlanExerciseRepository } from '../database/repository/plan-exercise.repository';
import { StudentExerciseRepository } from '../database/repository/student-exercise.repository';
import { TagRepository } from '../database/repository/tag.repository';
import { UserTagRepository } from '../database/repository/user-tag.repository';
import { ExercisesService } from './exercises.service';

describe('Сервис упражнений', () => {
  const exercises = {
    create: jest.fn(),
    save: jest.fn(),
    findById: jest.fn(),
    findByIds: jest.fn(),
    findOwnAndCatalog: jest.fn(),
    findByOwnerAndLowerName: jest.fn(),
    deleteById: jest.fn(),
  };
  const planExercises = {
    countByExerciseId: jest.fn(),
  };
  const exerciseTags = {
    findByExerciseIds: jest.fn(),
    findByExerciseIdsForCreator: jest.fn(),
    findVisibleExerciseIdsForStudent: jest.fn(),
    replaceForTrainer: jest.fn(),
  };
  const studentExercises = {
    findPair: jest.fn(),
    findAssignedExerciseIdsForStudent: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    deletePair: jest.fn(),
  };
  const tags = {
    findByIdsForCreator: jest.fn(),
  };
  const userTags = {
    findUserIdsByTagIds: jest.fn(),
    findTagsForUser: jest.fn(),
  };
  const links = {
    findForUser: jest.fn(),
    findByPair: jest.fn(),
  };
  const service = new ExercisesService(
    exercises as unknown as ExerciseRepository,
    planExercises as unknown as PlanExerciseRepository,
    exerciseTags as unknown as ExerciseTagRepository,
    studentExercises as unknown as StudentExerciseRepository,
    tags as unknown as TagRepository,
    userTags as unknown as UserTagRepository,
    links as unknown as CoachStudentLinkRepository,
  );

  const now = new Date('2026-08-18T10:00:00.000Z');
  const ownExercise = {
    id: 'ex-1',
    name: 'Жим лёжа',
    kind: 'weight_reps' as const,
    ownerCoachId: 'coach-1',
    createdAt: now,
    updatedAt: now,
  };
  const catalogExercise = {
    id: 'cat-1',
    name: 'Приседания со штангой',
    kind: 'weight_reps' as const,
    ownerCoachId: null,
    createdAt: now,
    updatedAt: now,
  };

  beforeEach(() => {
    jest.clearAllMocks();
    exerciseTags.findByExerciseIdsForCreator.mockResolvedValue([]);
    exerciseTags.findByExerciseIds.mockResolvedValue([]);
    exerciseTags.replaceForTrainer.mockResolvedValue(undefined);
    studentExercises.create.mockImplementation(data => data);
    studentExercises.save.mockResolvedValue({});
    userTags.findTagsForUser.mockResolvedValue([]);
    userTags.findUserIdsByTagIds.mockResolvedValue([]);
    links.findForUser.mockResolvedValue([]);
  });

  it('создаёт упражнение текущего тренера', async () => {
    exercises.findByOwnerAndLowerName.mockResolvedValue(null);
    exercises.create.mockReturnValue(ownExercise);
    exercises.save.mockResolvedValue(ownExercise);

    await expect(
      service.create('coach-1', { name: 'Жим лёжа', kind: 'weight_reps' }),
    ).resolves.toMatchObject({
      id: 'ex-1',
      name: 'Жим лёжа',
      source: 'own',
      ownerCoachId: 'coach-1',
      tags: [],
    });
  });

  it('отклоняет повтор имени у того же владельца', async () => {
    exercises.findByOwnerAndLowerName.mockResolvedValue({ id: 'ex-1' });

    await expect(
      service.create('coach-1', { name: 'жим лёжа', kind: 'weight_reps' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('включает каталог в список с discriminator', async () => {
    exercises.findOwnAndCatalog.mockResolvedValue([
      ownExercise,
      catalogExercise,
    ]);

    const listed = await service.listOwnAndCatalog({ actorId: 'coach-1' });
    expect(listed.map(item => item.source)).toEqual(['own', 'catalog']);
  });

  it('вешает свои теги на catalog без смены имени', async () => {
    exercises.findById.mockResolvedValue(catalogExercise);
    tags.findByIdsForCreator.mockResolvedValue([{ id: 'tag-1' }]);
    exerciseTags.findByExerciseIdsForCreator.mockResolvedValue([
      { exerciseId: 'cat-1', tag: { id: 'tag-1', name: 'ноги' } },
    ]);

    const result = await service.replaceTags('coach-1', {
      exerciseId: 'cat-1',
      tagIds: ['tag-1'],
    });
    expect(result.name).toBe('Приседания со штангой');
    expect(result.tags).toEqual([{ id: 'tag-1', name: 'ноги' }]);
    expect(exerciseTags.replaceForTrainer).toHaveBeenCalledWith(
      'cat-1',
      'coach-1',
      ['tag-1'],
    );
  });

  it('показывает упражнение ученику по общему тегу', async () => {
    exerciseTags.findVisibleExerciseIdsForStudent.mockResolvedValue(['cat-1']);
    studentExercises.findAssignedExerciseIdsForStudent.mockResolvedValue([]);
    exercises.findByIds.mockResolvedValue([catalogExercise]);
    userTags.findTagsForUser.mockResolvedValue([{ tagId: 'tag-1' }]);
    exerciseTags.findByExerciseIds.mockResolvedValue([
      { exerciseId: 'cat-1', tag: { id: 'tag-1', name: 'ноги' } },
    ]);

    const listed = await service.listVisible('student-1');
    expect(listed).toHaveLength(1);
    expect(listed[0]?.id).toBe('cat-1');
  });

  it('показывает явно выданное упражнение без общего тега', async () => {
    exerciseTags.findVisibleExerciseIdsForStudent.mockResolvedValue([]);
    studentExercises.findAssignedExerciseIdsForStudent.mockResolvedValue([
      'ex-1',
    ]);
    exercises.findByIds.mockResolvedValue([ownExercise]);

    const listed = await service.listVisible('student-1');
    expect(listed.map(item => item.id)).toEqual(['ex-1']);
  });

  it('назначает упражнения linked ученику идемпотентно', async () => {
    exercises.findByIds.mockResolvedValue([ownExercise]);
    links.findForUser.mockResolvedValue([
      { coachId: 'coach-1', studentId: 'student-1' },
    ]);
    studentExercises.findPair
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ id: 'row-1' });

    await service.assign('coach-1', {
      exerciseIds: ['ex-1'],
      studentIds: ['student-1'],
    });
    expect(studentExercises.save).toHaveBeenCalledTimes(1);

    await service.assign('coach-1', {
      exerciseIds: ['ex-1'],
      studentIds: ['student-1'],
    });
    expect(studentExercises.save).toHaveBeenCalledTimes(1);
  });

  it('отклоняет assign несвязанному ученику', async () => {
    exercises.findByIds.mockResolvedValue([ownExercise]);
    links.findForUser.mockResolvedValue([]);

    await expect(
      service.assign('coach-1', {
        exerciseIds: ['ex-1'],
        studentIds: ['stranger'],
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(studentExercises.save).not.toHaveBeenCalled();
  });

  it('отклоняет мутацию каталожного упражнения', async () => {
    exercises.findById.mockResolvedValue(catalogExercise);

    await expect(
      service.update('coach-1', { exerciseId: 'cat-1', name: 'X' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    await expect(service.deleteOwn('coach-1', 'cat-1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('отклоняет удаление упражнения, которое есть в плане', async () => {
    exercises.findById.mockResolvedValue(ownExercise);
    planExercises.countByExerciseId.mockResolvedValue(1);

    await expect(service.deleteOwn('coach-1', 'ex-1')).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('отклоняет обновление чужого упражнения', async () => {
    exercises.findById.mockResolvedValue({
      ...ownExercise,
      ownerCoachId: 'other-coach',
    });

    await expect(
      service.update('coach-1', { exerciseId: 'ex-1', name: 'X' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
