import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { ExerciseTagRepository } from '../database/repository/exercise-tag.repository';
import { TagRepository } from '../database/repository/tag.repository';
import { TrainingPlanTagRepository } from '../database/repository/training-plan-tag.repository';
import { UserTagRepository } from '../database/repository/user-tag.repository';
import { TagsService } from './tags.service';

describe('Сервис тегов', () => {
  const tags = {
    create: jest.fn(),
    save: jest.fn(),
    findById: jest.fn(),
    findByCreator: jest.fn(),
    findByCreatorAndName: jest.fn(),
    deleteById: jest.fn(),
  };
  const userTags = {
    findByTagId: jest.fn(),
    findTagsForUser: jest.fn(),
  };
  const links = {
    findByPair: jest.fn(),
  };
  const planTags = {
    findByTagId: jest.fn(),
  };
  const exerciseTags = {
    findByTagId: jest.fn(),
  };
  const profiles = {
    findByUserIds: jest.fn(),
  };
  const service = new TagsService(
    tags as unknown as TagRepository,
    userTags as unknown as UserTagRepository,
    links as unknown as CoachStudentLinkRepository,
    planTags as unknown as TrainingPlanTagRepository,
    exerciseTags as unknown as ExerciseTagRepository,
    profiles as unknown as import('../database/repository/user-profile.repository').UserProfileRepository,
  );

  const now = new Date('2026-08-18T10:00:00.000Z');
  const ownTag = {
    id: 'tag-1',
    name: 'ноги',
    creatorId: 'coach-1',
    createdAt: now,
    creator: { email: 'coach@test.com' },
  };

  beforeEach(() => {
    jest.clearAllMocks();
    profiles.findByUserIds.mockResolvedValue([]);
  });

  it('отдаёт хаб учеников, шаблонов и упражнений', async () => {
    tags.findById.mockResolvedValue(ownTag);
    userTags.findByTagId.mockResolvedValue([
      {
        userId: 'student-1',
        assignedAt: now,
        user: { email: 's1@test.com' },
      },
      {
        userId: 'student-2',
        assignedAt: now,
        user: { email: 's2@test.com' },
      },
    ]);
    planTags.findByTagId.mockResolvedValue([
      {
        plan: {
          id: 'plan-1',
          title: 'Низ',
          kind: 'template',
          ownerCoachId: 'coach-1',
        },
      },
    ]);
    exerciseTags.findByTagId.mockResolvedValue([
      {
        exercise: {
          id: 'ex-1',
          name: 'Присед',
          kind: 'weight_reps',
          ownerCoachId: null,
        },
      },
      {
        exercise: {
          id: 'ex-2',
          name: 'Выпады',
          kind: 'weight_reps',
          ownerCoachId: 'coach-1',
        },
      },
    ]);

    const hub = await service.getHub('coach-1', 'tag-1');
    expect(hub.users).toHaveLength(2);
    expect(hub.plans).toEqual([
      { id: 'plan-1', title: 'Низ', kind: 'template' },
    ]);
    expect(hub.exercises.map(item => item.id)).toEqual(['ex-1', 'ex-2']);
  });

  it('подставляет displayName ученика в хаб', async () => {
    tags.findById.mockResolvedValue(ownTag);
    userTags.findByTagId.mockResolvedValue([
      {
        userId: 'student-1',
        assignedAt: now,
        user: { email: 's1@test.com' },
      },
    ]);
    planTags.findByTagId.mockResolvedValue([]);
    exerciseTags.findByTagId.mockResolvedValue([]);
    profiles.findByUserIds.mockResolvedValue([
      { userId: 'student-1', displayName: 'Алина' },
    ]);

    const hub = await service.getHub('coach-1', 'tag-1');
    expect(hub.users[0]).toMatchObject({
      userId: 'student-1',
      displayName: 'Алина',
      email: 's1@test.com',
    });
  });

  it('отдаёт пустые секции хаба', async () => {
    tags.findById.mockResolvedValue(ownTag);
    userTags.findByTagId.mockResolvedValue([]);
    planTags.findByTagId.mockResolvedValue([]);
    exerciseTags.findByTagId.mockResolvedValue([]);

    const hub = await service.getHub('coach-1', 'tag-1');
    expect(hub.users).toEqual([]);
    expect(hub.plans).toEqual([]);
    expect(hub.exercises).toEqual([]);
  });

  it('отклоняет хаб чужого тега', async () => {
    tags.findById.mockResolvedValue({ ...ownTag, creatorId: 'other' });

    await expect(service.getHub('coach-1', 'tag-1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('отклоняет хаб несуществующего тега', async () => {
    tags.findById.mockResolvedValue(null);

    await expect(service.getHub('coach-1', 'missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
