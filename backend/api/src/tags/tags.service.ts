import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { ExerciseTagRepository } from '../database/repository/exercise-tag.repository';
import { TagRepository } from '../database/repository/tag.repository';
import { TrainingPlanTagRepository } from '../database/repository/training-plan-tag.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import { UserTagRepository } from '../database/repository/user-tag.repository';
import type {
  AssignTagParams,
  CreateTagParams,
  TagAssigneeReturns,
  TagHubReturns,
  TagReturns,
} from './interface';

@Injectable()
export class TagsService {
  constructor(
    private readonly tags: TagRepository,
    private readonly userTags: UserTagRepository,
    private readonly links: CoachStudentLinkRepository,
    private readonly planTags: TrainingPlanTagRepository,
    private readonly exerciseTags: ExerciseTagRepository,
    private readonly profiles: UserProfileRepository,
  ) {}

  /**
   *
   */
  async create(creatorId: string, params: CreateTagParams): Promise<TagReturns> {
    const name = params.name.trim();
    if (!name) {
      throw new BadRequestException('Tag name is required');
    }
    const existing = await this.tags.findByCreatorAndName(creatorId, name);
    if (existing) {
      throw new ConflictException('Tag name already exists');
    }
    const saved = await this.tags.save(
      this.tags.create({ name, creatorId }),
    );
    const withCreator = await this.tags.findById(saved.id) ?? saved;

    return this.toPublic(withCreator);
  }

  /**
   *
   */
  async listForUser(
    userId: string,
    canCreate: boolean,
  ): Promise<TagReturns[]> {
    if (canCreate) {
      const items = await this.tags.findByCreator(userId);

      return items.map(item => this.toPublic(item));
    }
    const assigned = await this.userTags.findTagsForUser(userId);

    return assigned
      .filter(row => row.tag)
      .map(row => this.toPublic(row.tag));
  }

  /**
   *
   */
  async deleteOwn(actorId: string, tagId: string): Promise<void> {
    const tag = await this.tags.findById(tagId);
    if (!tag) {
      throw new NotFoundException('Tag not found');
    }
    if (tag.creatorId !== actorId) {
      throw new ForbiddenException('Not the tag owner');
    }
    await this.tags.deleteById(tagId);
  }

  /**
   *
   */
  async assign(
    actorId: string,
    params: AssignTagParams,
  ): Promise<TagAssigneeReturns> {
    const tag = await this.tags.findById(params.tagId);
    if (!tag) {
      throw new NotFoundException('Tag not found');
    }
    if (tag.creatorId !== actorId) {
      throw new ForbiddenException('Not the tag owner');
    }
    const link = await this.links.findByPair(actorId, params.userId);
    if (!link) {
      throw new ForbiddenException('Coach and student are not linked');
    }
    const existing = await this.userTags.findByUserAndTag(
      params.userId,
      params.tagId,
    );
    if (!existing) {
      await this.userTags.save(
        this.userTags.create({
          userId: params.userId,
          tagId: params.tagId,
          assignedBy: actorId,
        }),
      );
    }
    const assignees = await this.userTags.findByTagId(params.tagId);
    const row = assignees.find(item => item.userId === params.userId);
    const [mapped] = await this.toAssignees(row ? [row] : []);
    if (!mapped) {
      throw new NotFoundException('Tag assignment not found');
    }

    return mapped;
  }

  /**
   *
   */
  async unassign(
    actorId: string,
    tagId: string,
    userId: string,
  ): Promise<void> {
    const tag = await this.tags.findById(tagId);
    if (!tag) {
      throw new NotFoundException('Tag not found');
    }
    if (tag.creatorId !== actorId) {
      throw new ForbiddenException('Not the tag owner');
    }
    await this.userTags.deleteByUserAndTag(userId, tagId);
  }

  /**
   *
   */
  async listAssignees(
    actorId: string,
    tagId: string,
  ): Promise<TagAssigneeReturns[]> {
    const tag = await this.tags.findById(tagId);
    if (!tag) {
      throw new NotFoundException('Tag not found');
    }
    if (tag.creatorId !== actorId) {
      throw new ForbiddenException('Not the tag owner');
    }
    const rows = await this.userTags.findByTagId(tagId);

    return this.toAssignees(rows);
  }

  /**
   * Хаб тега: ученики, шаблоны и упражнения создателя.
   */
  async getHub(actorId: string, tagId: string): Promise<TagHubReturns> {
    const tag = await this.tags.findById(tagId);
    if (!tag) {
      throw new NotFoundException('Tag not found');
    }
    if (tag.creatorId !== actorId) {
      throw new ForbiddenException('Not the tag owner');
    }
    const users = await this.listAssignees(actorId, tagId);
    const planRows = await this.planTags.findByTagId(tagId);
    const plans = planRows.flatMap(row => {
      const plan = row.plan;
      if (!plan) {
        return [];
      }
      if (plan.ownerCoachId !== actorId || plan.kind === 'catalog_seed') {
        return [];
      }

      return [{ id: plan.id, title: plan.title, kind: plan.kind }];
    });
    const exerciseRows = await this.exerciseTags.findByTagId(tagId);
    const exercises = exerciseRows.flatMap(row => {
      const exercise = row.exercise;
      if (!exercise) {
        return [];
      }
      if (exercise.ownerCoachId !== null && exercise.ownerCoachId !== actorId) {
        return [];
      }
      const source = exercise.ownerCoachId === null ? 'catalog' as const : 'own' as const;

      return [{
        id: exercise.id,
        name: exercise.name,
        kind: exercise.kind,
        source,
      }];
    });

    return {
      ...this.toPublic(tag),
      users,
      plans,
      exercises,
    };
  }

  /**
   *
   */
  private async toAssignees(
    rows: Array<{
      userId: string;
      assignedAt: Date;
      user?: { email?: string; } | null;
    }>,
  ): Promise<TagAssigneeReturns[]> {
    const profiles = await this.profiles.findByUserIds(
      rows.map(row => row.userId),
    );
    const nameById = new Map(
      profiles.map(profile => [profile.userId, profile.displayName]),
    );

    return rows.map(row => ({
      userId: row.userId,
      email: row.user?.email ?? null,
      displayName: nameById.get(row.userId) ?? null,
      assignedAt: row.assignedAt.toISOString(),
    }));
  }

  /**
   *
   */
  private toPublic(tag: {
    id: string;
    name: string;
    creatorId: string;
    createdAt: Date;
    creator?: { email?: string; } | null;
  }): TagReturns {
    return {
      id: tag.id,
      name: tag.name,
      creatorId: tag.creatorId,
      creatorEmail: tag.creator?.email ?? null,
      createdAt: tag.createdAt.toISOString(),
    };
  }
}
