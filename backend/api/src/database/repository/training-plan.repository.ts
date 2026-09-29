import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { FindAssignedCopiesParams } from '../../plans/interface/find-assigned-copies.params';
import { TrainingPlanEntity } from '../entity/training-plan.entity';

@Injectable()
export class TrainingPlanRepository {
  constructor(
    @InjectRepository(TrainingPlanEntity)
    private readonly plans: Repository<TrainingPlanEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<TrainingPlanEntity>): TrainingPlanEntity {
    return this.plans.create(data);
  }

  /**
   *
   */
  async save(entity: TrainingPlanEntity): Promise<TrainingPlanEntity> {
    return this.plans.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<TrainingPlanEntity | null> {
    return this.plans.findOne({
      where: { id },
      relations: { ownerCoach: true },
    });
  }

  /**
   *
   */
  async findByOwner(
    ownerCoachId: string,
    kind = 'template' as const,
  ): Promise<TrainingPlanEntity[]> {
    return this.plans.find({
      where: { ownerCoachId, kind },
      relations: { ownerCoach: true },
      order: { updatedAt: 'DESC' },
    });
  }

  /**
   *
   */
  async findCatalogSeeds(): Promise<TrainingPlanEntity[]> {
    return this.plans.find({
      where: { kind: 'catalog_seed' },
      relations: { ownerCoach: true },
      order: { title: 'ASC' },
    });
  }

  /**
   * Plans owned by a linked coach of the student with at least one shared tag.
   */
  async findVisibleForStudent(studentId: string): Promise<TrainingPlanEntity[]> {
    return this.plans
      .createQueryBuilder('plan')
      .leftJoinAndSelect('plan.ownerCoach', 'ownerCoach')
      .innerJoin(
        'coach_student_links',
        'link',
        'link.coach_id = plan.owner_coach_id AND link.student_id = :studentId',
        { studentId },
      )
      .innerJoin(
        'training_plan_tags',
        'pt',
        'pt.plan_id = plan.id',
      )
      .innerJoin(
        'user_tags',
        'ut',
        'ut.tag_id = pt.tag_id AND ut.user_id = :studentId',
        { studentId },
      )
      .andWhere('plan.kind = :kind', { kind: 'template' })
      .distinct(true)
      .orderBy('plan.updated_at', 'DESC')
      .getMany();
  }

  /**
   *
   */
  async findStudentCopy(
    parentTemplateId: string,
    assignedStudentId: string,
  ): Promise<TrainingPlanEntity | null> {
    return this.plans.findOne({
      where: {
        parentTemplateId,
        assignedStudentId,
        kind: 'student_copy',
      },
      relations: { ownerCoach: true },
    });
  }

  /**
   *
   */
  async findAssignedCopies(
    params: FindAssignedCopiesParams,
  ): Promise<TrainingPlanEntity[]> {
    return this.plans.find({
      where: {
        kind: 'student_copy',
        assignedStudentId: params.assignedStudentId,
        ...params.ownerCoachId !== undefined
          ? { ownerCoachId: params.ownerCoachId }
          : {},
      },
      relations: { ownerCoach: true },
      order: { updatedAt: 'DESC' },
    });
  }

  /**
   *
   */
  async deleteById(id: string): Promise<void> {
    await this.plans.delete({ id });
  }

  /**
   *
   */
  async upsertById(
    entity: Partial<TrainingPlanEntity> & { id: string },
  ): Promise<void> {
    await this.plans.upsert(entity, ['id']);
  }
}
