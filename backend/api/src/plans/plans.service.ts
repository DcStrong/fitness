import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { QueryFailedError } from 'typeorm';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { ExerciseRepository } from '../database/repository/exercise.repository';
import { PlanExerciseRepository } from '../database/repository/plan-exercise.repository';
import { TagRepository } from '../database/repository/tag.repository';
import { TrainingPlanRepository } from '../database/repository/training-plan.repository';
import { TrainingPlanTagRepository } from '../database/repository/training-plan-tag.repository';
import { UserTagRepository } from '../database/repository/user-tag.repository';
import type { ExerciseEntity } from '../database/entity/exercise.entity';
import type { PlanExerciseEntity } from '../database/entity/plan-exercise.entity';
import type { TrainingPlanEntity } from '../database/entity/training-plan.entity';
import type {
  AssignPlanParams,
  AssignPlansBatchParams,
  CreatePlanParams,
  ListPlansQueryParams,
  PlanExerciseInput,
  PlanExerciseReturns,
  PlanKind,
  PlanListScope,
  PlanSetReturns,
  ReplacePlanExerciseParams,
  TrainingPlanReturns,
  TrainingPlanTagSummary,
  UpdatePlanParams,
  PatchPlanLoadsParams,
} from './interface';
import { hasTagIntersection } from './plan-visibility';

@Injectable()
export class PlansService {
  constructor(
    private readonly plans: TrainingPlanRepository,
    private readonly planTags: TrainingPlanTagRepository,
    private readonly planExercises: PlanExerciseRepository,
    private readonly exercises: ExerciseRepository,
    private readonly tags: TagRepository,
    private readonly userTags: UserTagRepository,
    private readonly links: CoachStudentLinkRepository,
  ) {}

  /**
   * Создаёт шаблон тренера (`kind=template`) или копию ученика,
   * если передан `assignedStudentId` связанного студента.
   */
  async create(
    ownerCoachId: string,
    params: CreatePlanParams,
  ): Promise<TrainingPlanReturns> {
    const title = params.title.trim();
    if (!title) {
      throw new BadRequestException('Title is required');
    }
    let kind: PlanKind = 'template';
    let assignedStudentId: string | null = null;
    if (params.assignedStudentId) {
      const link = await this.links.findByPair(
        ownerCoachId,
        params.assignedStudentId,
      );
      if (!link) {
        throw new ForbiddenException('Student is not linked');
      }
      kind = 'student_copy';
      assignedStudentId = params.assignedStudentId;
    }
    const notes = this.resolveNotes(params.notes, params.body);
    const tagIds = await this.resolveOwnTagIds(
      ownerCoachId,
      params.tagIds ?? [],
    );
    const exerciseRows = await this.resolveExerciseRows(
      ownerCoachId,
      params.exercises ?? [],
    );
    const saved = await this.plans.save(
      this.plans.create({
        ownerCoachId,
        title,
        body: notes,
        kind,
        goal: params.goal ?? 'general',
        parentTemplateId: null,
        assignedStudentId,
      }),
    );
    await this.planTags.replaceForPlan(saved.id, tagIds);
    await this.planExercises.replaceForPlan(saved.id, exerciseRows);

    return this.getOwnedOrThrow(ownerCoachId, saved.id);
  }

  /**
   * Список шаблонов, каталога или назначенных копий.
   */
  async list(query: ListPlansQueryParams): Promise<TrainingPlanReturns[]> {
    if (query.kind === 'assigned') {
      return this.listAssigned(query);
    }
    if (!query.permissions.includes('plans:read_own')) {
      throw new ForbiddenException('Missing plans:read_own permission');
    }
    const scope: PlanListScope =
      query.kind === 'catalog' ? 'catalog' : 'template';
    const items = await this.listOwn(query.actorId, scope);
    if (!query.tagId) {
      return items;
    }
    await this.resolveOwnTagIds(query.actorId, [query.tagId]);

    return items.filter(item =>
      item.tags.some(tag => tag.id === query.tagId),
    );
  }

  /**
   * Список своих шаблонов или каталога.
   */
  async listOwn(
    ownerCoachId: string,
    scope: PlanListScope = 'template',
  ): Promise<TrainingPlanReturns[]> {
    if (scope === 'catalog') {
      const items = await this.plans.findCatalogSeeds();

      return this.attachRelations(items);
    }
    const items = await this.plans.findByOwner(ownerCoachId, 'template');

    return this.attachRelations(items);
  }

  /**
   *
   */
  async listVisible(studentId: string): Promise<TrainingPlanReturns[]> {
    const items = await this.plans.findVisibleForStudent(studentId);

    return this.attachRelations(items);
  }

  /**
   *
   */
  async getById(
    actorId: string,
    planId: string,
  ): Promise<TrainingPlanReturns> {
    const plan = await this.plans.findById(planId);
    if (!plan) {
      throw new NotFoundException('Plan not found');
    }
    if (plan.kind === 'catalog_seed') {
      return this.toPublic(
        plan,
        await this.tagsForPlan(planId),
        await this.exercisesForPlan(planId),
      );
    }
    if (plan.ownerCoachId === actorId) {
      return this.toPublic(
        plan,
        await this.tagsForPlan(planId),
        await this.exercisesForPlan(planId),
      );
    }
    if (plan.kind === 'student_copy' && plan.assignedStudentId === actorId) {
      return this.toPublic(
        plan,
        await this.tagsForPlan(planId),
        await this.exercisesForPlan(planId),
      );
    }
    if (plan.kind !== 'template') {
      throw new ForbiddenException('Plan not visible');
    }
    const link = await this.links.findByPair(plan.ownerCoachId, actorId);
    if (!link) {
      throw new ForbiddenException('Plan not visible');
    }
    const planTagRows = await this.planTags.findByPlanId(planId);
    const planTagIds = planTagRows.map(row => row.tagId);
    const assigned = await this.userTags.findTagsForUser(actorId);
    const studentTagIds = new Set(assigned.map(row => row.tagId));
    if (!hasTagIntersection(studentTagIds, planTagIds)) {
      throw new ForbiddenException('Plan not visible');
    }

    return this.toPublic(
      plan,
      planTagRows
        .filter(row => row.tag)
        .map(row => ({ id: row.tag.id, name: row.tag.name })),
      await this.exercisesForPlan(planId),
    );
  }

  /**
   * Обновляет свой шаблон или копию ученика. Каталог и чужие планы нельзя.
   */
  async update(
    ownerCoachId: string,
    params: UpdatePlanParams,
  ): Promise<TrainingPlanReturns> {
    const plan = await this.requireMutableOwnedPlan(ownerCoachId, params.planId);
    if (params.title !== undefined) {
      const title = params.title.trim();
      if (!title) {
        throw new BadRequestException('Title is required');
      }
      plan.title = title;
    }
    if (params.notes !== undefined || params.body !== undefined) {
      plan.body = this.resolveNotes(params.notes, params.body);
    }
    if (params.goal !== undefined) {
      plan.goal = params.goal;
    }
    await this.plans.save(plan);
    if (params.tagIds !== undefined) {
      const tagIds = await this.resolveOwnTagIds(ownerCoachId, params.tagIds);
      await this.planTags.replaceForPlan(plan.id, tagIds);
    }
    if (params.exercises !== undefined) {
      const exerciseRows = await this.resolveExerciseRows(
        ownerCoachId,
        params.exercises,
      );
      await this.planExercises.replaceForPlan(plan.id, exerciseRows);
    }

    return this.getOwnedOrThrow(ownerCoachId, plan.id);
  }

  /**
   * Меняет рабочие веса на всех сетах listed weight_reps упражнений.
   */
  async updateLoads(
    ownerCoachId: string,
    params: PatchPlanLoadsParams,
  ): Promise<TrainingPlanReturns> {
    const plan = await this.requireMutableOwnedPlan(ownerCoachId, params.planId);
    if (params.items.length === 0) {
      throw new BadRequestException('No loads to update');
    }
    const rows = await this.planExercises.findByPlanId(plan.id);
    const byExercise = new Map(rows.map(row => [row.exerciseId, row]));
    const next = rows.map((row, index) => this.toReplaceRow(row, index));
    for (const item of params.items) {
      const current = byExercise.get(item.exerciseId);
      if (!current) {
        throw new BadRequestException('Unknown exercise in plan loads');
      }
      if (current.exercise.kind !== 'weight_reps') {
        throw new BadRequestException(
          'Loads can only be set for weight_reps exercises',
        );
      }
      const target = next.find(row => row.exerciseId === item.exerciseId);
      if (!target) {
        throw new BadRequestException('Unknown exercise in plan loads');
      }
      target.sets = target.sets.map(set => ({
        ...set,
        weightKg: item.weightKg,
      }));
    }
    await this.planExercises.replaceForPlan(plan.id, next);

    return this.getOwnedOrThrow(ownerCoachId, plan.id);
  }

  /**
   *
   */
  async deleteOwn(ownerCoachId: string, planId: string): Promise<void> {
    await this.requireMutableTemplate(ownerCoachId, planId);
    await this.plans.deleteById(planId);
  }

  /**
   * Копирует каталожный шаблон в библиотеку тренера.
   */
  async cloneCatalog(
    ownerCoachId: string,
    planId: string,
  ): Promise<TrainingPlanReturns> {
    const source = await this.plans.findById(planId);
    if (!source) {
      throw new NotFoundException('Plan not found');
    }
    if (source.kind !== 'catalog_seed') {
      throw new BadRequestException('Only catalog plans can be cloned');
    }
    const sourceExercises = await this.planExercises.findByPlanId(planId);
    const saved = await this.plans.save(
      this.plans.create({
        ownerCoachId,
        title: source.title,
        body: source.body,
        kind: 'template',
        goal: source.goal,
        parentTemplateId: null,
        assignedStudentId: null,
      }),
    );
    await this.planExercises.replaceForPlan(
      saved.id,
      sourceExercises.map((row, index) => this.toReplaceRow(row, index)),
    );

    return this.getOwnedOrThrow(ownerCoachId, saved.id);
  }

  /**
   * Назначает шаблон ученикам: создаёт или возвращает `student_copy`.
   */
  async assign(
    ownerCoachId: string,
    params: AssignPlanParams,
  ): Promise<TrainingPlanReturns[]> {
    const template = await this.plans.findById(params.planId);
    if (!template) {
      throw new NotFoundException('Plan not found');
    }
    if (template.ownerCoachId !== ownerCoachId) {
      throw new ForbiddenException('Not the plan owner');
    }
    if (template.kind !== 'template') {
      throw new BadRequestException('Only templates can be assigned');
    }
    const studentIds = [...new Set(params.studentIds ?? [])];
    const tagIds = [...new Set(params.tagIds ?? [])];
    await this.resolveOwnTagIds(ownerCoachId, tagIds);
    const taggedUserIds = await this.userTags.findUserIdsByTagIds(tagIds);
    const union = [...new Set([...studentIds, ...taggedUserIds])];
    if (union.length === 0) {
      throw new BadRequestException('No students to assign');
    }
    const links = await this.links.findForUser(ownerCoachId);
    const linkedStudentIds = new Set(
      links
        .filter(link => link.coachId === ownerCoachId)
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
    const copies: TrainingPlanReturns[] = [];
    for (const studentId of resolved) {
      copies.push(await this.copyTemplateForStudent(template, studentId));
    }

    return copies;
  }

  /**
   * Назначает несколько шаблонов одному linked ученику.
   */
  async assignBatch(
    ownerCoachId: string,
    params: AssignPlansBatchParams,
  ): Promise<TrainingPlanReturns[]> {
    const planIds = [...new Set(params.planIds)];
    if (planIds.length === 0) {
      throw new BadRequestException('No plans to assign');
    }
    const link = await this.links.findByPair(ownerCoachId, params.studentId);
    if (!link) {
      throw new ForbiddenException('Student is not linked');
    }
    const templates: TrainingPlanEntity[] = [];
    for (const planId of planIds) {
      const template = await this.plans.findById(planId);
      if (!template) {
        throw new NotFoundException('Plan not found');
      }
      if (template.ownerCoachId !== ownerCoachId) {
        throw new ForbiddenException('Not the plan owner');
      }
      if (template.kind !== 'template') {
        throw new BadRequestException('Only templates can be assigned');
      }
      templates.push(template);
    }
    const copies: TrainingPlanReturns[] = [];
    for (const template of templates) {
      copies.push(await this.copyTemplateForStudent(template, params.studentId));
    }

    return copies;
  }

  /**
   *
   */
  private async listAssigned(
    query: ListPlansQueryParams,
  ): Promise<TrainingPlanReturns[]> {
    const canReadOwn = query.permissions.includes('plans:read_own');
    const canReadVisible = query.permissions.includes('plans:read_visible');
    if (query.studentId) {
      if (!canReadOwn) {
        throw new ForbiddenException('Missing plans:read_own permission');
      }
      const link = await this.links.findByPair(query.actorId, query.studentId);
      if (!link) {
        throw new ForbiddenException('Student is not linked');
      }
      const items = await this.plans.findAssignedCopies({
        ownerCoachId: query.actorId,
        assignedStudentId: query.studentId,
      });

      return this.attachRelations(items);
    }
    if (!canReadOwn && !canReadVisible) {
      throw new ForbiddenException('Missing plans read permission');
    }
    const items = await this.plans.findAssignedCopies({
      assignedStudentId: query.actorId,
    });

    return this.attachRelations(items);
  }

  /**
   *
   */
  private async copyTemplateForStudent(
    template: TrainingPlanEntity,
    studentId: string,
  ): Promise<TrainingPlanReturns> {
    const existing = await this.plans.findStudentCopy(template.id, studentId);
    if (existing) {
      return this.getOwnedOrThrow(template.ownerCoachId, existing.id);
    }
    const sourceExercises = await this.planExercises.findByPlanId(template.id);
    const sourceTags = await this.planTags.findByPlanId(template.id);
    let saved: TrainingPlanEntity;
    try {
      saved = await this.plans.save(
        this.plans.create({
          ownerCoachId: template.ownerCoachId,
          title: template.title,
          body: template.body,
          kind: 'student_copy',
          goal: template.goal,
          parentTemplateId: template.id,
          assignedStudentId: studentId,
        }),
      );
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        const raced = await this.plans.findStudentCopy(template.id, studentId);
        if (raced) {
          return this.getOwnedOrThrow(template.ownerCoachId, raced.id);
        }
      }
      throw error;
    }
    await this.planTags.replaceForPlan(
      saved.id,
      sourceTags.map(row => row.tagId),
    );
    await this.planExercises.replaceForPlan(
      saved.id,
      sourceExercises.map((row, index) => this.toReplaceRow(row, index)),
    );

    return this.getOwnedOrThrow(template.ownerCoachId, saved.id);
  }

  /**
   *
   */
  private async requireMutableOwnedPlan(
    ownerCoachId: string,
    planId: string,
  ): Promise<TrainingPlanEntity> {
    const plan = await this.plans.findById(planId);
    if (!plan) {
      throw new NotFoundException('Plan not found');
    }
    if (plan.kind === 'catalog_seed') {
      throw new ForbiddenException('Catalog plans cannot be modified');
    }
    if (plan.ownerCoachId !== ownerCoachId) {
      throw new ForbiddenException('Not the plan owner');
    }

    return plan;
  }

  /**
   *
   */
  private async requireMutableTemplate(
    ownerCoachId: string,
    planId: string,
  ): Promise<TrainingPlanEntity> {
    const plan = await this.plans.findById(planId);
    if (!plan) {
      throw new NotFoundException('Plan not found');
    }
    if (plan.kind === 'catalog_seed') {
      throw new ForbiddenException('Catalog plans cannot be modified');
    }
    if (plan.kind === 'student_copy') {
      throw new ForbiddenException('Student copies cannot be modified');
    }
    if (plan.ownerCoachId !== ownerCoachId) {
      throw new ForbiddenException('Not the plan owner');
    }

    return plan;
  }

  /**
   *
   */
  private async getOwnedOrThrow(
    ownerCoachId: string,
    planId: string,
  ): Promise<TrainingPlanReturns> {
    const plan = await this.plans.findById(planId);
    if (!plan || plan.ownerCoachId !== ownerCoachId) {
      throw new NotFoundException('Plan not found');
    }

    return this.toPublic(
      plan,
      await this.tagsForPlan(planId),
      await this.exercisesForPlan(planId),
    );
  }

  /**
   *
   */
  private resolveNotes(notes?: string, body?: string): string {
    const value = notes ?? body ?? '';

    return value.trim();
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
  private async resolveExerciseRows(
    ownerCoachId: string,
    exercises: PlanExerciseInput[],
  ): Promise<ReplacePlanExerciseParams[]> {
    const ids = [...new Set(exercises.map(item => item.exerciseId))];
    const found = await this.exercises.findByIds(ids);
    if (found.length !== ids.length) {
      throw new BadRequestException('One or more exercises are invalid');
    }
    for (const item of found) {
      this.assertExerciseReadable(ownerCoachId, item);
    }

    return exercises.map((item, index) => ({
      exerciseId: item.exerciseId,
      sortOrder: index,
      restSeconds: item.restSeconds ?? null,
      notes: item.notes?.trim() ?? '',
      sets: (item.sets ?? []).map((set, setIndex) => ({
        sortOrder: setIndex,
        reps: set.reps ?? null,
        weightKg: set.weightKg ?? null,
        durationSeconds: set.durationSeconds ?? null,
      })),
    }));
  }

  /**
   *
   */
  private assertExerciseReadable(
    ownerCoachId: string,
    exercise: ExerciseEntity,
  ): void {
    if (exercise.ownerCoachId === null) {
      return;
    }
    if (exercise.ownerCoachId !== ownerCoachId) {
      throw new ForbiddenException('One or more exercises are foreign');
    }
  }

  /**
   *
   */
  private async tagsForPlan(
    planId: string,
  ): Promise<TrainingPlanTagSummary[]> {
    const rows = await this.planTags.findByPlanId(planId);

    return rows
      .filter(row => row.tag)
      .map(row => ({ id: row.tag.id, name: row.tag.name }));
  }

  /**
   *
   */
  private async exercisesForPlan(
    planId: string,
  ): Promise<PlanExerciseReturns[]> {
    const rows = await this.planExercises.findByPlanId(planId);

    return rows.map(row => this.toExercisePublic(row));
  }

  /**
   *
   */
  private async attachRelations(
    plans: TrainingPlanEntity[],
  ): Promise<TrainingPlanReturns[]> {
    const planIds = plans.map(plan => plan.id);
    const tags = await this.planTags.findByPlanIds(planIds);
    const exercises = await this.planExercises.findByPlanIds(planIds);
    const tagsByPlan = new Map<string, TrainingPlanTagSummary[]>();
    for (const row of tags) {
      if (!row.tag) {
        continue;
      }
      const list = tagsByPlan.get(row.planId) ?? [];
      list.push({ id: row.tag.id, name: row.tag.name });
      tagsByPlan.set(row.planId, list);
    }
    const exercisesByPlan = new Map<string, PlanExerciseReturns[]>();
    for (const row of exercises) {
      const list = exercisesByPlan.get(row.planId) ?? [];
      list.push(this.toExercisePublic(row));
      exercisesByPlan.set(row.planId, list);
    }

    return plans.map(plan =>
      this.toPublic(
        plan,
        tagsByPlan.get(plan.id) ?? [],
        exercisesByPlan.get(plan.id) ?? [],
      ));
  }

  /**
   *
   */
  private toReplaceRow(
    row: PlanExerciseEntity,
    index: number,
  ): ReplacePlanExerciseParams {
    const sets = [...(row.sets ?? [])].sort(
      (a, b) => a.sortOrder - b.sortOrder,
    );

    return {
      exerciseId: row.exerciseId,
      sortOrder: index,
      restSeconds: row.restSeconds,
      notes: row.notes,
      sets: sets.map((set, setIndex) => ({
        sortOrder: setIndex,
        reps: set.reps,
        weightKg: this.parseWeight(set.weightKg),
        durationSeconds: set.durationSeconds,
      })),
    };
  }

  /**
   *
   */
  private toExercisePublic(row: PlanExerciseEntity): PlanExerciseReturns {
    const sets = [...(row.sets ?? [])].sort(
      (a, b) => a.sortOrder - b.sortOrder,
    );

    return {
      id: row.id,
      exerciseId: row.exerciseId,
      exerciseName: row.exercise?.name ?? '',
      exerciseKind: row.exercise?.kind ?? 'weight_reps',
      sortOrder: row.sortOrder,
      restSeconds: row.restSeconds,
      notes: row.notes,
      sets: sets.map(set => this.toSetPublic(set)),
    };
  }

  /**
   *
   */
  private toSetPublic(set: {
    id: string;
    sortOrder: number;
    reps: number | null;
    weightKg: string | null;
    durationSeconds: number | null;
  }): PlanSetReturns {
    return {
      id: set.id,
      sortOrder: set.sortOrder,
      reps: set.reps,
      weightKg: this.parseWeight(set.weightKg),
      durationSeconds: set.durationSeconds,
    };
  }

  /**
   *
   */
  private parseWeight(value: string | null): number | null {
    if (value === null) {
      return null;
    }
    const parsed = Number(value);

    return Number.isFinite(parsed) ? parsed : null;
  }

  /**
   *
   */
  private toPublic(
    plan: TrainingPlanEntity,
    tags: TrainingPlanTagSummary[],
    exercises: PlanExerciseReturns[],
  ): TrainingPlanReturns {
    return {
      id: plan.id,
      ownerCoachId: plan.ownerCoachId,
      ownerCoachEmail: plan.ownerCoach?.email ?? null,
      title: plan.title,
      body: plan.body,
      notes: plan.body,
      kind: plan.kind,
      goal: plan.goal,
      parentTemplateId: plan.parentTemplateId,
      assignedStudentId: plan.assignedStudentId,
      tags,
      exercises,
      createdAt: plan.createdAt.toISOString(),
      updatedAt: plan.updatedAt.toISOString(),
    };
  }

  /**
   *
   */
  private isUniqueViolation(error: unknown): boolean {
    return (
      error instanceof QueryFailedError &&
      (error.driverError as { code?: string }).code === '23505'
    );
  }
}
