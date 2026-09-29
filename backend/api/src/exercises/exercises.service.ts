import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { ExerciseRepository } from '../database/repository/exercise.repository';
import { ExerciseTagRepository } from '../database/repository/exercise-tag.repository';
import { PlanExerciseRepository } from '../database/repository/plan-exercise.repository';
import { StudentExerciseRepository } from '../database/repository/student-exercise.repository';
import { TagRepository } from '../database/repository/tag.repository';
import { UserTagRepository } from '../database/repository/user-tag.repository';
import type { ExerciseEntity } from '../database/entity/exercise.entity';
import type { ExerciseTagEntity } from '../database/entity/exercise-tag.entity';
import type {
  AssignExercisesParams,
  CreateExerciseParams,
  ExerciseReturns,
  ExerciseTagSummary,
  ListExercisesQueryParams,
  ReplaceExerciseTagsParams,
  UnassignExerciseParams,
  UpdateExerciseParams,
} from './interface';

@Injectable()
export class ExercisesService {
  constructor(
    private readonly exercises: ExerciseRepository,
    private readonly planExercises: PlanExerciseRepository,
    private readonly exerciseTags: ExerciseTagRepository,
    private readonly studentExercises: StudentExerciseRepository,
    private readonly tags: TagRepository,
    private readonly userTags: UserTagRepository,
    private readonly links: CoachStudentLinkRepository,
  ) {}

  /**
   * Создаёт упражнение, принадлежащее тренеру.
   */
  async create(
    ownerCoachId: string,
    params: CreateExerciseParams,
  ): Promise<ExerciseReturns> {
    const name = params.name.trim();
    const existing = await this.exercises.findByOwnerAndLowerName({
      ownerCoachId,
      name,
    });
    if (existing) {
      throw new ConflictException('Exercise name already exists');
    }
    const saved = await this.exercises.save(
      this.exercises.create({
        name,
        kind: params.kind,
        ownerCoachId,
      }),
    );
    if (params.tagIds !== undefined) {
      await this.replaceTrainerTags(ownerCoachId, saved.id, params.tagIds);
    }

    return this.toPublicOwned(ownerCoachId, saved);
  }

  /**
   * Список своих упражнений и каталога, опционально по тегу тренера.
   */
  async listOwnAndCatalog(
    query: ListExercisesQueryParams,
  ): Promise<ExerciseReturns[]> {
    if (query.tagId) {
      await this.resolveOwnTagIds(query.actorId, [query.tagId]);
    }
    const items = await this.exercises.findOwnAndCatalog(query.actorId);
    const mapped = await this.toPublicMany(query.actorId, items);
    if (!query.tagId) {
      return mapped;
    }

    return mapped.filter(item =>
      item.tags.some(tag => tag.id === query.tagId),
    );
  }

  /**
   * Упражнения, видимые ученику: пересечение тегов ∪ явная выдача.
   */
  async listVisible(studentId: string): Promise<ExerciseReturns[]> {
    const taggedIds =
      await this.exerciseTags.findVisibleExerciseIdsForStudent(studentId);
    const assignedIds =
      await this.studentExercises.findAssignedExerciseIdsForStudent(studentId);
    const ids = [...new Set([...taggedIds, ...assignedIds])];
    const items = await this.exercises.findByIds(ids);

    return this.toPublicMany(null, items, studentId);
  }

  /**
   * Обновляет только своё упражнение.
   */
  async update(
    ownerCoachId: string,
    params: UpdateExerciseParams,
  ): Promise<ExerciseReturns> {
    const exercise = await this.requireOwned(ownerCoachId, params.exerciseId);
    if (params.name !== undefined) {
      const name = params.name.trim();
      const existing = await this.exercises.findByOwnerAndLowerName({
        ownerCoachId,
        name,
      });
      if (existing && existing.id !== exercise.id) {
        throw new ConflictException('Exercise name already exists');
      }
      exercise.name = name;
    }
    if (params.kind !== undefined) {
      exercise.kind = params.kind;
    }
    const saved = await this.exercises.save(exercise);
    if (params.tagIds !== undefined) {
      await this.replaceTrainerTags(ownerCoachId, saved.id, params.tagIds);
    }

    return this.toPublicOwned(ownerCoachId, saved);
  }

  /**
   * Теги на своём или catalog упражнении без смены name/kind.
   */
  async replaceTags(
    trainerId: string,
    params: ReplaceExerciseTagsParams,
  ): Promise<ExerciseReturns> {
    const exercise = await this.requireTaggable(trainerId, params.exerciseId);
    await this.replaceTrainerTags(trainerId, exercise.id, params.tagIds);

    return this.toPublicOwned(trainerId, exercise);
  }

  /**
   * Явная выдача упражнений linked ученикам.
   */
  async assign(
    coachId: string,
    params: AssignExercisesParams,
  ): Promise<ExerciseReturns[]> {
    const exerciseIds = [...new Set(params.exerciseIds)];
    if (exerciseIds.length === 0) {
      throw new BadRequestException('No exercises to assign');
    }
    const found = await this.exercises.findByIds(exerciseIds);
    if (found.length !== exerciseIds.length) {
      throw new NotFoundException('Exercise not found');
    }
    for (const exercise of found) {
      if (
        exercise.ownerCoachId !== null &&
        exercise.ownerCoachId !== coachId
      ) {
        throw new ForbiddenException('Not the exercise owner');
      }
    }
    const studentIds = [...new Set(params.studentIds ?? [])];
    const tagIds = [...new Set(params.tagIds ?? [])];
    await this.resolveOwnTagIds(coachId, tagIds);
    const taggedUserIds = await this.userTags.findUserIdsByTagIds(tagIds);
    const union = [...new Set([...studentIds, ...taggedUserIds])];
    if (union.length === 0) {
      throw new BadRequestException('No students to assign');
    }
    const links = await this.links.findForUser(coachId);
    const linkedStudentIds = new Set(
      links
        .filter(link => link.coachId === coachId)
        .map(link => link.studentId),
    );
    for (const studentId of studentIds) {
      if (!linkedStudentIds.has(studentId)) {
        throw new ForbiddenException('Student is not linked');
      }
    }
    const resolved = union.filter(id => linkedStudentIds.has(id));
    if (resolved.length === 0) {
      throw new BadRequestException('No students to assign');
    }
    for (const studentId of resolved) {
      for (const exerciseId of exerciseIds) {
        const existing = await this.studentExercises.findPair(
          coachId,
          studentId,
          exerciseId,
        );
        if (existing) {
          continue;
        }
        await this.studentExercises.save(
          this.studentExercises.create({
            coachId,
            studentId,
            exerciseId,
          }),
        );
      }
    }

    return this.toPublicMany(coachId, found);
  }

  /**
   * Снимает явную выдачу упражнений у linked ученика.
   */
  async unassign(
    coachId: string,
    params: UnassignExerciseParams,
  ): Promise<void> {
    const link = await this.links.findByPair(coachId, params.studentId);
    if (!link) {
      throw new ForbiddenException('Student is not linked');
    }
    await this.studentExercises.deletePair(
      coachId,
      params.studentId,
      params.exerciseId,
    );
  }

  /**
   *
   */
  async unassignMany(
    coachId: string,
    studentId: string,
    exerciseIds: string[],
  ): Promise<void> {
    const unique = [...new Set(exerciseIds)];
    if (unique.length === 0) {
      throw new BadRequestException('No exercises to unassign');
    }
    const link = await this.links.findByPair(coachId, studentId);
    if (!link) {
      throw new ForbiddenException('Student is not linked');
    }
    for (const exerciseId of unique) {
      await this.studentExercises.deletePair(coachId, studentId, exerciseId);
    }
  }

  /**
   * Удаляет своё упражнение, если оно не используется в планах.
   */
  async deleteOwn(ownerCoachId: string, exerciseId: string): Promise<void> {
    await this.requireOwned(ownerCoachId, exerciseId);
    const referenced = await this.planExercises.countByExerciseId(exerciseId);
    if (referenced > 0) {
      throw new ConflictException('Exercise is referenced by a plan');
    }
    await this.exercises.deleteById(exerciseId);
  }

  /**
   *
   */
  private async requireOwned(
    ownerCoachId: string,
    exerciseId: string,
  ): Promise<ExerciseEntity> {
    const exercise = await this.exercises.findById(exerciseId);
    if (!exercise) {
      throw new NotFoundException('Exercise not found');
    }
    if (exercise.ownerCoachId === null) {
      throw new ForbiddenException('Catalog exercises cannot be modified');
    }
    if (exercise.ownerCoachId !== ownerCoachId) {
      throw new ForbiddenException('Not the exercise owner');
    }

    return exercise;
  }

  /**
   *
   */
  private async requireTaggable(
    trainerId: string,
    exerciseId: string,
  ): Promise<ExerciseEntity> {
    const exercise = await this.exercises.findById(exerciseId);
    if (!exercise) {
      throw new NotFoundException('Exercise not found');
    }
    if (
      exercise.ownerCoachId !== null &&
      exercise.ownerCoachId !== trainerId
    ) {
      throw new ForbiddenException('Not the exercise owner');
    }

    return exercise;
  }

  /**
   *
   */
  private async replaceTrainerTags(
    trainerId: string,
    exerciseId: string,
    tagIds: string[],
  ): Promise<void> {
    const resolved = await this.resolveOwnTagIds(trainerId, tagIds);
    await this.exerciseTags.replaceForTrainer(
      exerciseId,
      trainerId,
      resolved,
    );
  }

  /**
   *
   */
  private async resolveOwnTagIds(
    ownerCoachId: string,
    tagIds: string[],
  ): Promise<string[]> {
    const unique = [...new Set(tagIds)];
    if (unique.length === 0) {
      return [];
    }
    const found = await this.tags.findByIdsForCreator(ownerCoachId, unique);
    if (found.length !== unique.length) {
      throw new BadRequestException('One or more tags are invalid or foreign');
    }

    return unique;
  }

  /**
   *
   */
  private async toPublicOwned(
    trainerId: string,
    exercise: ExerciseEntity,
  ): Promise<ExerciseReturns> {
    const mapped = await this.toPublicMany(trainerId, [exercise]);
    const item = mapped[0];
    if (!item) {
      throw new NotFoundException('Exercise not found');
    }

    return item;
  }

  /**
   *
   */
  private async toPublicMany(
    trainerId: string | null,
    items: ExerciseEntity[],
    studentId?: string,
  ): Promise<ExerciseReturns[]> {
    const ids = items.map(item => item.id);
    const rows = trainerId
      ? await this.exerciseTags.findByExerciseIdsForCreator(ids, trainerId)
      : await this.exerciseTags.findByExerciseIds(ids);
    const tagsByExercise = this.groupTags(rows);
    if (studentId) {
      const assigned = await this.userTags.findTagsForUser(studentId);
      const allowed = new Set(assigned.map(row => row.tagId));
      for (const [exerciseId, tags] of tagsByExercise) {
        tagsByExercise.set(
          exerciseId,
          tags.filter(tag => allowed.has(tag.id)),
        );
      }
    }

    return items.map(item =>
      this.toPublic(item, tagsByExercise.get(item.id) ?? []),
    );
  }

  /**
   *
   */
  private groupTags(
    rows: ExerciseTagEntity[],
  ): Map<string, ExerciseTagSummary[]> {
    const tagsByExercise = new Map<string, ExerciseTagSummary[]>();
    for (const row of rows) {
      if (!row.tag) {
        continue;
      }
      const list = tagsByExercise.get(row.exerciseId) ?? [];
      list.push({ id: row.tag.id, name: row.tag.name });
      tagsByExercise.set(row.exerciseId, list);
    }

    return tagsByExercise;
  }

  /**
   *
   */
  private toPublic(
    exercise: ExerciseEntity,
    tags: ExerciseTagSummary[],
  ): ExerciseReturns {
    return {
      id: exercise.id,
      name: exercise.name,
      kind: exercise.kind,
      source: exercise.ownerCoachId === null ? 'catalog' : 'own',
      ownerCoachId: exercise.ownerCoachId,
      tags,
      createdAt: exercise.createdAt.toISOString(),
      updatedAt: exercise.updatedAt.toISOString(),
    };
  }
}
