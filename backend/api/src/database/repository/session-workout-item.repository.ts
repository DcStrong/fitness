import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import type { ReplaceSessionWorkoutItemParams } from '../../workout-programs/interface';
import { SessionEntity } from '../entity/session.entity';
import { SessionPrescriptionSetEntity } from '../entity/session-prescription-set.entity';
import { SessionWorkoutItemEntity } from '../entity/session-workout-item.entity';

@Injectable()
export class SessionWorkoutItemRepository {
  constructor(
    @InjectRepository(SessionWorkoutItemEntity)
    private readonly items: Repository<SessionWorkoutItemEntity>,
  ) {}

  /**
   *
   */
  async findBySessionId(sessionId: string): Promise<SessionWorkoutItemEntity[]> {
    return this.items.find({
      where: { sessionId },
      relations: { sets: true, studentPlan: true },
      order: { sortOrder: 'ASC', sets: { sortOrder: 'ASC' } },
    });
  }

  /**
   *
   */
  async findBySessionIds(
    sessionIds: string[],
  ): Promise<SessionWorkoutItemEntity[]> {
    if (sessionIds.length === 0) {
      return [];
    }

    return this.items.find({
      where: { sessionId: In(sessionIds) },
      relations: { sets: true, studentPlan: true },
      order: { sortOrder: 'ASC', sets: { sortOrder: 'ASC' } },
    });
  }

  /**
   *
   */
  async replaceForSession(
    sessionId: string,
    rows: ReplaceSessionWorkoutItemParams[],
  ): Promise<void> {
    await this.items.manager.transaction(async em => {
      await em.delete(SessionWorkoutItemEntity, { sessionId });
      const firstPlanId = rows[0]?.studentPlanId ?? null;
      await em.update(SessionEntity, { id: sessionId }, {
        studentPlanId: firstPlanId,
      });
      for (const [index, row] of rows.entries()) {
        const saved = await em.save(
          SessionWorkoutItemEntity,
          em.create(SessionWorkoutItemEntity, {
            sessionId,
            sortOrder: index,
            studentPlanId: row.studentPlanId,
            source: row.source,
            overrideAt: row.overrideAt,
          }),
        );
        if (row.sets.length === 0) {
          continue;
        }
        await em.save(
          SessionPrescriptionSetEntity,
          row.sets.map(set =>
            em.create(SessionPrescriptionSetEntity, {
              sessionWorkoutItemId: saved.id,
              exerciseId: set.exerciseId,
              exerciseName: set.exerciseName,
              exerciseKind: set.exerciseKind,
              sortOrder: set.sortOrder,
              reps: set.reps,
              weightKg:
                set.weightKg === null ? null : set.weightKg.toFixed(2),
              durationSeconds: set.durationSeconds,
            }),
          ),
        );
      }
    });
  }

  /**
   *
   */
  async sessionIsOverridden(sessionId: string): Promise<boolean> {
    const count = await this.items
      .createQueryBuilder('item')
      .where('item.session_id = :sessionId', { sessionId })
      .andWhere('item.override_at IS NOT NULL')
      .getCount();

    return count > 0;
  }
}
