import { BadRequestException } from '@nestjs/common';
import { EntityManager, In, QueryFailedError } from 'typeorm';
import { ExerciseEntity } from '../database/entity/exercise.entity';
import { PlanExerciseEntity } from '../database/entity/plan-exercise.entity';
import { SessionSetLogRepository } from '../database/repository/session-set-log.repository';
import { SessionWorkoutItemEntity } from '../database/entity/session-workout-item.entity';
import type {
  SessionExerciseLogInput,
  SessionSetLogRowParams,
} from './interface/session-set-log.types';
import {
  buildLogsFromPayload,
  buildLogsFromPrescription,
} from './session-set-log.builder';

/**
 *
 */
export interface PersistCompleteLogsParams {
  sessionId: string;
  studentPlanId: string | null;
  logs?: SessionExerciseLogInput[];
}

/**
 * Writes set logs in the same transaction as complete. No-op when there is
 * nothing to snapshot. Does not run for cancel / no_show.
 */
export async function persistCompleteLogs(
  manager: EntityManager,
  logsRepo: SessionSetLogRepository,
  params: PersistCompleteLogsParams,
): Promise<void> {
  const existing = await logsRepo.countBySessionId(params.sessionId, manager);
  if (existing > 0) {
    return;
  }

  if (params.logs !== undefined) {
    await assertKnownExercises(manager, params.logs);
    await insertLogs(
      logsRepo,
      manager,
      buildLogsFromPayload(params.sessionId, params.logs),
    );

    return;
  }

  const items = await manager.find(SessionWorkoutItemEntity, {
    where: { sessionId: params.sessionId },
    relations: { sets: true },
    order: { sortOrder: 'ASC', sets: { sortOrder: 'ASC' } },
  });
  const snapshotSets = items.flatMap(item =>
    [...(item.sets ?? [])].sort((left, right) => left.sortOrder - right.sortOrder),
  );
  if (snapshotSets.length > 0) {
    const byExercise = new Map<
      string,
      { exerciseId: string; sets: typeof snapshotSets }
    >();
    const order: string[] = [];
    for (const set of snapshotSets) {
      const existing = byExercise.get(set.exerciseId);
      if (!existing) {
        order.push(set.exerciseId);
        byExercise.set(set.exerciseId, { exerciseId: set.exerciseId, sets: [set] });
        continue;
      }
      existing.sets.push(set);
    }
    await insertLogs(
      logsRepo,
      manager,
      buildLogsFromPrescription(
        params.sessionId,
        order.map(exerciseId => {
          const group = byExercise.get(exerciseId)!;

          return {
            exerciseId,
            sets: group.sets.map(set => ({
              reps: set.reps,
              weightKg: set.weightKg,
              durationSeconds: set.durationSeconds,
            })),
          };
        }),
      ),
    );

    return;
  }

  if (!params.studentPlanId) {
    return;
  }

  const exercises = await manager.find(PlanExerciseEntity, {
    where: { planId: params.studentPlanId },
    relations: { sets: true },
    order: { sortOrder: 'ASC', sets: { sortOrder: 'ASC' } },
  });
  const prescription = exercises.map(exercise => {
    const sets = exercise.sets ?? [];

    return {
      exerciseId: exercise.exerciseId,
      sets: [...sets]
        .sort((left, right) => left.sortOrder - right.sortOrder)
        .map(set => ({
          reps: set.reps,
          weightKg: set.weightKg,
          durationSeconds: set.durationSeconds,
        })),
    };
  });
  await insertLogs(
    logsRepo,
    manager,
    buildLogsFromPrescription(params.sessionId, prescription),
  );
}

/**
 *
 */
async function assertKnownExercises(
  manager: EntityManager,
  logs: SessionExerciseLogInput[],
): Promise<void> {
  const ids = [...new Set(logs.map(item => item.exerciseId))];
  if (ids.length === 0) {
    return;
  }
  const found = await manager.find(ExerciseEntity, {
    where: { id: In(ids) },
    select: { id: true },
  });
  if (found.length !== ids.length) {
    throw new BadRequestException('Unknown exercise in set logs');
  }
}

/**
 *
 */
async function insertLogs(
  logsRepo: SessionSetLogRepository,
  manager: EntityManager,
  rows: SessionSetLogRowParams[],
): Promise<void> {
  try {
    await logsRepo.insertMany(manager, rows);
  } catch (error) {
    if (isForeignKeyViolation(error)) {
      throw new BadRequestException('Unknown exercise in set logs');
    }
    throw error;
  }
}

/**
 *
 */
function isForeignKeyViolation(error: unknown): boolean {
  if (!(error instanceof QueryFailedError)) {
    return false;
  }
  const driverError: unknown = error.driverError;
  if (typeof driverError !== 'object' || driverError === null) {
    return false;
  }

  return 'code' in driverError && driverError.code === '23503';
}
