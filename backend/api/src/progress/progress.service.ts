import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { SessionSetLogRepository } from '../database/repository/session-set-log.repository';
import { UserRepository } from '../database/repository/user.repository';
import { PLAN_GOALS, type PlanGoal } from '../plans/interface';
import type {
  GetProgressParams,
  ProgressCatalogReturns,
  ProgressSeriesReturns,
} from './interface/progress.types';
import { aggregateProgressPoints } from './progress-points';

const PLAN_GOAL_VALUES: ReadonlySet<string> = new Set(PLAN_GOALS);

@Injectable()
export class ProgressService {
  constructor(
    private readonly links: CoachStudentLinkRepository,
    private readonly logs: SessionSetLogRepository,
    private readonly users: UserRepository,
  ) {}

  /**
   *
   */
  async getProgress(
    params: GetProgressParams,
  ): Promise<ProgressSeriesReturns | ProgressCatalogReturns> {
    await this.assertCanRead(params.actorId, params.studentId);
    const exerciseId = params.exerciseId;
    if (!exerciseId) {
      return this.listLoggedExercises(params);
    }

    return this.getSeries({ ...params, exerciseId });
  }

  /**
   *
   */
  private async listLoggedExercises(
    params: GetProgressParams,
  ): Promise<ProgressCatalogReturns> {
    const exercises = await this.logs.findLoggedExercises({
      studentId: params.studentId,
      ...this.coachScope(params),
    });

    return { exercises };
  }

  /**
   *
   */
  private async getSeries(
    params: GetProgressParams & { exerciseId: string; },
  ): Promise<ProgressSeriesReturns> {
    const scope = {
      studentId: params.studentId,
      exerciseId: params.exerciseId,
      ...this.coachScope(params),
    };
    const rows = await this.logs.findCompletedLogsForExercise(scope);
    const goal = await this.logs.findLastPlanGoalForExercise(scope);

    return {
      exerciseId: params.exerciseId,
      goal: isPlanGoal(goal) ? goal : null,
      points: aggregateProgressPoints(rows),
    };
  }

  /**
   *
   */
  private async assertCanRead(
    actorId: string,
    studentId: string,
  ): Promise<void> {
    const student = await this.users.findById(studentId);
    if (!student) {
      throw new NotFoundException('Student not found');
    }
    if (actorId === studentId) {
      return;
    }
    const link = await this.links.findByPair(actorId, studentId);
    if (!link) {
      throw new ForbiddenException('Not the linked coach or the student');
    }
  }

  /**
   *
   */
  private coachScope(
    params: GetProgressParams,
  ): { coachId: string; } | Record<string, never> {
    const coachId =
      params.actorId !== params.studentId ? params.actorId : params.coachId;
    if (!coachId) {
      return {};
    }

    return { coachId };
  }
}

/**
 *
 */
function isPlanGoal(value: string | null): value is PlanGoal {
  return value !== null && PLAN_GOAL_VALUES.has(value);
}
