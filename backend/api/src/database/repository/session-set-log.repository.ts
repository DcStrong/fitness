import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import type {
  ProgressExerciseRow,
  ProgressLogRow,
} from '../../progress/interface/progress.types';
import type { SessionSetLogRowParams } from '../../sessions/interface/session-set-log.types';
import { SessionSetLogEntity } from '../entity/session-set-log.entity';

@Injectable()
export class SessionSetLogRepository {
  constructor(
    @InjectRepository(SessionSetLogEntity)
    private readonly logs: Repository<SessionSetLogEntity>,
  ) {}

  /**
   *
   */
  async insertMany(
    manager: EntityManager,
    rows: SessionSetLogRowParams[],
  ): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    await manager.save(
      SessionSetLogEntity,
      rows.map(row => manager.create(SessionSetLogEntity, row)),
    );
  }

  /**
   *
   */
  async countBySessionId(
    sessionId: string,
    manager?: EntityManager,
  ): Promise<number> {
    const repo = manager?.getRepository(SessionSetLogEntity) ?? this.logs;

    return repo.count({ where: { sessionId } });
  }

  /**
   *
   */
  async findBySessionId(sessionId: string): Promise<SessionSetLogEntity[]> {
    return this.logs.find({
      where: { sessionId },
      order: { sortOrder: 'ASC' },
    });
  }

  /**
   *
   */
  async findCompletedLogsForExercise(params: {
    studentId: string;
    exerciseId: string;
    coachId?: string;
  }): Promise<ProgressLogRow[]> {
    const coachFilter = params.coachId ? 'AND session.coach_id = $4' : '';
    const values = params.coachId
      ? ['completed', params.studentId, params.exerciseId, params.coachId]
      : ['completed', params.studentId, params.exerciseId];
    const rows = (await this.logs.query(
      `
      SELECT
        session.id AS "sessionId",
        session.coach_id AS "coachId",
        completed.completed_at AS "completedAt",
        log.reps AS "reps",
        log.weight_kg AS "weightKg"
      FROM session_set_logs log
      INNER JOIN sessions session ON session.id = log.session_id
      INNER JOIN (
        SELECT session_id, MIN(created_at) AS completed_at
        FROM session_history_events
        WHERE to_status = 'completed'
        GROUP BY session_id
      ) completed ON completed.session_id = session.id
      WHERE session.status = $1
        AND session.student_id = $2
        AND log.exercise_id = $3
        ${coachFilter}
      ORDER BY completed.completed_at ASC, log.sort_order ASC
      `,
      values,
    )) as Array<{
      sessionId: string;
      coachId: string;
      completedAt: Date | string;
      reps: number | string | null;
      weightKg: string | null;
    }>;

    return rows.map(row => ({
      sessionId: row.sessionId,
      coachId: row.coachId,
      completedAt:
        row.completedAt instanceof Date
          ? row.completedAt
          : new Date(row.completedAt),
      reps:
        row.reps === null || row.reps === undefined ? null : Number(row.reps),
      weightKg: row.weightKg,
    }));
  }

  /**
   *
   */
  async findLoggedExercises(params: {
    studentId: string;
    coachId?: string;
  }): Promise<ProgressExerciseRow[]> {
    const coachFilter = params.coachId ? 'AND session.coach_id = $3' : '';
    const values = params.coachId
      ? ['completed', params.studentId, params.coachId]
      : ['completed', params.studentId];
    const rows = (await this.logs.query(
      `
      SELECT
        log.exercise_id AS "exerciseId",
        exercise.name AS "name",
        COUNT(DISTINCT log.session_id)::int AS "sessionCount"
      FROM session_set_logs log
      INNER JOIN sessions session ON session.id = log.session_id
      INNER JOIN exercises exercise ON exercise.id = log.exercise_id
      WHERE session.status = $1
        AND session.student_id = $2
        ${coachFilter}
      GROUP BY log.exercise_id, exercise.name
      ORDER BY "sessionCount" DESC
      `,
      values,
    )) as Array<{
      exerciseId: string;
      name: string;
      sessionCount: number | string;
    }>;

    return rows.map(row => ({
      exerciseId: row.exerciseId,
      name: row.name,
      sessionCount: Number(row.sessionCount),
    }));
  }

  /**
   *
   */
  async findLastPlanGoalForExercise(params: {
    studentId: string;
    exerciseId: string;
    coachId?: string;
  }): Promise<string | null> {
    const coachFilter = params.coachId ? 'AND session.coach_id = $4' : '';
    const values = params.coachId
      ? ['completed', params.studentId, params.exerciseId, params.coachId]
      : ['completed', params.studentId, params.exerciseId];
    const rows = (await this.logs.query(
      `
      SELECT plan.goal AS "goal"
      FROM session_set_logs log
      INNER JOIN sessions session ON session.id = log.session_id
      INNER JOIN training_plans plan ON plan.id = session.student_plan_id
      WHERE session.status = $1
        AND session.student_id = $2
        AND log.exercise_id = $3
        ${coachFilter}
      ORDER BY session.updated_at DESC
      LIMIT 1
      `,
      values,
    )) as Array<{ goal: string }>;

    return rows[0]?.goal ?? null;
  }
}
