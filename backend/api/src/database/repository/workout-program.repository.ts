import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type {
  ReplaceProgramDayParams,
  ReplaceProgressionRuleParams,
} from '../../workout-programs/interface';
import { WorkoutProgramDayEntity } from '../entity/workout-program-day.entity';
import { WorkoutProgramDayItemEntity } from '../entity/workout-program-day-item.entity';
import { WorkoutProgramEntity } from '../entity/workout-program.entity';
import { WorkoutProgressionRuleEntity } from '../entity/workout-progression-rule.entity';

@Injectable()
export class WorkoutProgramRepository {
  constructor(
    @InjectRepository(WorkoutProgramEntity)
    private readonly programs: Repository<WorkoutProgramEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<WorkoutProgramEntity>): WorkoutProgramEntity {
    return this.programs.create(data);
  }

  /**
   *
   */
  async save(entity: WorkoutProgramEntity): Promise<WorkoutProgramEntity> {
    return this.programs.save(entity);
  }

  /**
   *
   */
  async findByRecurringBookingId(
    recurringBookingId: string,
  ): Promise<WorkoutProgramEntity | null> {
    return this.programs.findOne({
      where: { recurringBookingId },
      relations: {
        days: { items: { studentPlan: true } },
        rules: true,
      },
      order: {
        days: { weekday: 'ASC', items: { sortOrder: 'ASC' } },
      },
    });
  }

  /**
   *
   */
  async findById(id: string): Promise<WorkoutProgramEntity | null> {
    return this.programs.findOne({
      where: { id },
      relations: {
        days: { items: { studentPlan: true } },
        rules: true,
      },
      order: {
        days: { weekday: 'ASC', items: { sortOrder: 'ASC' } },
      },
    });
  }

  /**
   *
   */
  async replaceContents(
    programId: string,
    days: ReplaceProgramDayParams[],
    rules: ReplaceProgressionRuleParams[],
  ): Promise<void> {
    await this.programs.manager.transaction(async em => {
      await em.delete(WorkoutProgramDayEntity, { programId });
      await em.delete(WorkoutProgressionRuleEntity, { programId });
      for (const day of days) {
        const savedDay = await em.save(
          WorkoutProgramDayEntity,
          em.create(WorkoutProgramDayEntity, {
            programId,
            weekday: day.weekday,
          }),
        );
        if (day.items.length === 0) {
          continue;
        }
        await em.save(
          WorkoutProgramDayItemEntity,
          day.items.map(item =>
            em.create(WorkoutProgramDayItemEntity, {
              programDayId: savedDay.id,
              sortOrder: item.sortOrder,
              templateId: item.templateId,
              studentPlanId: item.studentPlanId,
            }),
          ),
        );
      }
      if (rules.length === 0) {
        return;
      }
      await em.save(
        WorkoutProgressionRuleEntity,
        rules.map(rule =>
          em.create(WorkoutProgressionRuleEntity, {
            programId,
            exerciseId: rule.exerciseId,
            startWeightKg:
              rule.startWeightKg === null
                ? null
                : rule.startWeightKg.toFixed(2),
            deltaKg: rule.deltaKg.toFixed(2),
            incrementKg: rule.incrementKg.toFixed(2),
            holdOnMiss: rule.holdOnMiss,
            heldWeightKg:
              rule.heldWeightKg === null
                ? null
                : rule.heldWeightKg.toFixed(2),
          }),
        ),
      );
    });
  }

  /**
   *
   */
  async updateRuleHeldWeight(
    programId: string,
    exerciseId: string,
    heldWeightKg: number | null,
  ): Promise<void> {
    await this.programs.manager.update(
      WorkoutProgressionRuleEntity,
      { programId, exerciseId },
      {
        heldWeightKg:
          heldWeightKg === null ? null : heldWeightKg.toFixed(2),
      },
    );
  }

  /**
   *
   */
  async updateRuleStartWeight(
    programId: string,
    exerciseId: string,
    startWeightKg: number,
  ): Promise<void> {
    await this.programs.manager.update(
      WorkoutProgressionRuleEntity,
      { programId, exerciseId },
      { startWeightKg: startWeightKg.toFixed(2), heldWeightKg: null },
    );
  }
}
