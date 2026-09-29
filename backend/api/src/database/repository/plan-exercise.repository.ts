import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import type { ReplacePlanExerciseParams } from '../../plans/interface';
import { PlanExerciseEntity } from '../entity/plan-exercise.entity';
import { PlanSetEntity } from '../entity/plan-set.entity';

@Injectable()
export class PlanExerciseRepository {
  constructor(
    @InjectRepository(PlanExerciseEntity)
    private readonly planExercises: Repository<PlanExerciseEntity>,
  ) {}

  /**
   *
   */
  async findByPlanId(planId: string): Promise<PlanExerciseEntity[]> {
    return this.planExercises.find({
      where: { planId },
      relations: { exercise: true, sets: true },
      order: { sortOrder: 'ASC', sets: { sortOrder: 'ASC' } },
    });
  }

  /**
   *
   */
  async findByPlanIds(planIds: string[]): Promise<PlanExerciseEntity[]> {
    if (planIds.length === 0) {
      return [];
    }

    return this.planExercises.find({
      where: { planId: In(planIds) },
      relations: { exercise: true, sets: true },
      order: { sortOrder: 'ASC', sets: { sortOrder: 'ASC' } },
    });
  }

  /**
   *
   */
  async countByExerciseId(exerciseId: string): Promise<number> {
    return this.planExercises.count({ where: { exerciseId } });
  }

  /**
   *
   */
  async replaceForPlan(
    planId: string,
    rows: ReplacePlanExerciseParams[],
  ): Promise<void> {
    await this.planExercises.manager.transaction(async em => {
      await em.delete(PlanExerciseEntity, { planId });
      for (const row of rows) {
        const saved = await em.save(
          PlanExerciseEntity,
          em.create(PlanExerciseEntity, {
            planId,
            exerciseId: row.exerciseId,
            sortOrder: row.sortOrder,
            restSeconds: row.restSeconds,
            notes: row.notes,
          }),
        );
        if (row.sets.length === 0) {
          continue;
        }
        await em.save(
          PlanSetEntity,
          row.sets.map(set =>
            em.create(PlanSetEntity, {
              planExerciseId: saved.id,
              sortOrder: set.sortOrder,
              reps: set.reps,
              weightKg:
                set.weightKg === null ? null : set.weightKg.toFixed(2),
              durationSeconds: set.durationSeconds,
            })),
        );
      }
    });
  }

  /**
   *
   */
  async deleteByPlanId(planId: string): Promise<void> {
    await this.planExercises.delete({ planId });
  }
}
