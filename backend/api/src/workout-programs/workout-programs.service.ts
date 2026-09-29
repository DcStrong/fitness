import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RecurringBookingEntity } from '../database/entity/recurring-booking.entity';
import { SessionEntity } from '../database/entity/session.entity';
import { WorkoutProgramEntity } from '../database/entity/workout-program.entity';
import { RecurringBookingRepository } from '../database/repository/recurring-booking.repository';
import { SessionRepository } from '../database/repository/session.repository';
import { SessionSetLogRepository } from '../database/repository/session-set-log.repository';
import { SessionWorkoutItemRepository } from '../database/repository/session-workout-item.repository';
import { WorkoutProgramRepository } from '../database/repository/workout-program.repository';
import { PlansService } from '../plans/plans.service';
import type { TrainingPlanReturns } from '../plans/interface';
import type { WeekdayNumber } from '../recurring-bookings/interface/recurring-booking.types';
import { snapshotFromPlan } from '../sessions/session-workout.snapshot';
import {
  formatZonedDate,
  localDateWeekday,
} from '../schedules/util/zoned-time.util';
import { interpolateWeights } from './util/interpolate-weights.util';
import type {
  ApplyWorkoutProgramParams,
  ReplaceProgramDayParams,
  ReplaceProgressionRuleParams,
  UpsertWorkoutProgramParams,
  WorkoutProgramPreviewPoint,
  WorkoutProgramReturns,
} from './interface';

const MS_PER_WEEK = 7 * 24 * 60 * 60 * 1000;

@Injectable()
export class WorkoutProgramsService {
  constructor(
    private readonly bookings: RecurringBookingRepository,
    private readonly programs: WorkoutProgramRepository,
    private readonly sessions: SessionRepository,
    private readonly workoutItems: SessionWorkoutItemRepository,
    private readonly plans: PlansService,
    private readonly setLogs: SessionSetLogRepository,
  ) {}

  /**
   *
   */
  async get(
    coachId: string,
    recurringBookingId: string,
  ): Promise<WorkoutProgramReturns> {
    const booking = await this.requireOwned(coachId, recurringBookingId);
    const program = await this.programs.findByRecurringBookingId(
      recurringBookingId,
    );
    if (!program) {
      throw new NotFoundException('Workout program not found');
    }

    return this.toReturns(program, booking);
  }

  /**
   *
   */
  async upsert(
    params: UpsertWorkoutProgramParams,
  ): Promise<WorkoutProgramReturns> {
    const booking = await this.requireOwned(
      params.coachId,
      params.recurringBookingId,
    );
    if (booking.status !== 'active') {
      throw new ConflictException('Recurring booking is not active');
    }
    this.assertDays(params.days, booking.weekdays);
    const horizonWeeks = params.horizonWeeks ?? 2;
    this.assertHorizon(horizonWeeks);
    const dayRows = await this.resolveDays(
      params.coachId,
      booking.studentId,
      params.days,
    );
    let program = await this.programs.findByRecurringBookingId(booking.id);
    if (!program) {
      program = await this.programs.save(
        this.programs.create({
          recurringBookingId: booking.id,
          ownerCoachId: booking.coachId,
          studentId: booking.studentId,
          horizonWeeks,
        }),
      );
    } else {
      program.horizonWeeks = horizonWeeks;
      program = await this.programs.save(program);
    }
    const rules = this.normalizeRules(params.progressionRules ?? []);
    await this.programs.replaceContents(program.id, dayRows, rules);
    const saved = await this.programs.findById(program.id);
    if (!saved) {
      throw new NotFoundException('Workout program not found');
    }
    await this.materialize(saved, booking, false);

    return this.toReturns(saved, booking);
  }

  /**
   *
   */
  async apply(params: ApplyWorkoutProgramParams): Promise<WorkoutProgramReturns> {
    const booking = await this.requireOwned(
      params.coachId,
      params.recurringBookingId,
    );
    if (booking.status !== 'active') {
      throw new ConflictException('Recurring booking is not active');
    }
    const program = await this.programs.findByRecurringBookingId(booking.id);
    if (!program) {
      throw new NotFoundException('Workout program not found');
    }
    await this.materialize(program, booking, params.force === true);

    return this.toReturns(program, booking);
  }

  /**
   * Sync hook: fill newly booked sessions without force-overwriting overrides.
   */
  async applyIfPresent(recurringBookingId: string): Promise<void> {
    const booking = await this.bookings.findById(recurringBookingId);
    if (!booking || booking.status !== 'active') {
      return;
    }
    const program = await this.programs.findByRecurringBookingId(
      recurringBookingId,
    );
    if (!program) {
      return;
    }
    await this.materialize(program, booking, false);
  }

  /**
   *
   */
  async onSessionCompleted(sessionId: string): Promise<void> {
    const session = await this.sessions.findById(sessionId);
    if (!session?.recurringBookingId) {
      return;
    }
    const booking = await this.bookings.findById(session.recurringBookingId);
    if (!booking) {
      return;
    }
    const program = await this.programs.findByRecurringBookingId(booking.id);
    if (!program) {
      return;
    }
    const items = await this.workoutItems.findBySessionId(session.id);
    const logs = await this.setLogs.findBySessionId(session.id);
    const snapshotMax = maxWeightByExercise(
      items.flatMap(item => item.sets ?? []),
    );
    const actualMax = maxWeightByExercise(logs);
    let missed = false;
    for (const rule of program.rules ?? []) {
      if (!rule.holdOnMiss) {
        continue;
      }
      const prescribed = snapshotMax.get(rule.exerciseId);
      if (prescribed === undefined) {
        continue;
      }
      const actual = actualMax.get(rule.exerciseId) ?? 0;
      if (actual + 1e-9 < prescribed) {
        missed = true;
        await this.programs.updateRuleHeldWeight(
          program.id,
          rule.exerciseId,
          actual,
        );
      }
    }
    const reloaded = await this.programs.findById(program.id);
    if (!reloaded) {
      return;
    }
    if (missed) {
      await this.materialize(reloaded, booking, false);

      return;
    }
    if (this.shouldRollHorizon(reloaded, session)) {
      await this.rollStartWeights(reloaded, actualMax, snapshotMax);
      const rolled = await this.programs.findById(program.id);
      if (rolled) {
        await this.materialize(rolled, booking, false);
        await this.syncCopyStarts(rolled, booking.coachId);
      }
    }
  }

  /**
   *
   */
  private async materialize(
    program: WorkoutProgramEntity,
    booking: RecurringBookingEntity,
    force: boolean,
  ): Promise<void> {
    const now = new Date();
    const horizonEnd = new Date(
      now.getTime() + program.horizonWeeks * MS_PER_WEEK,
    );
    const sessions = await this.sessions.findBookedByRecurringInRange(
      booking.id,
      now,
      horizonEnd,
    );
    const copies = await this.loadCopies(program, booking.coachId);
    const weightsBySession = this.weightsForSessions(
      program,
      booking,
      sessions,
      copies,
    );
    for (const session of sessions) {
      if (!force && (await this.workoutItems.sessionIsOverridden(session.id))) {
        continue;
      }
      const localDate = formatZonedDate(session.startsAt, booking.timezone);
      const weekday = localDateWeekday(localDate);
      const day = (program.days ?? []).find(row => row.weekday === weekday);
      if (!day || day.items.length === 0) {
        continue;
      }
      const weightMap = weightsBySession.get(session.id) ?? new Map();
      const snapshots: ReturnType<typeof snapshotFromPlan>[] = [];
      for (const item of [...day.items].sort(
        (left, right) => left.sortOrder - right.sortOrder,
      )) {
        const copy = copies.get(item.studentPlanId);
        if (!copy) {
          continue;
        }
        snapshots.push(
          snapshotFromPlan(copy, {
            source: 'program',
            overrideAt: null,
            weightByExercise: weightMap,
          }),
        );
      }
      await this.workoutItems.replaceForSession(session.id, snapshots);
    }
  }

  /**
   *
   */
  private weightsForSessions(
    program: WorkoutProgramEntity,
    booking: RecurringBookingEntity,
    sessions: SessionEntity[],
    copies: Map<string, TrainingPlanReturns>,
  ): Map<string, Map<string, number>> {
    const result = new Map<string, Map<string, number>>();
    const exerciseIds = uniqueExerciseIds(program, copies);
    for (const exerciseId of exerciseIds) {
      const rule = (program.rules ?? []).find(
        item => item.exerciseId === exerciseId,
      );
      const held = parseWeight(rule?.heldWeightKg ?? null);
      const sessionsWithExercise = sessions.filter(session => {
        const weekday = localDateWeekday(
          formatZonedDate(session.startsAt, booking.timezone),
        );
        const day = (program.days ?? []).find(row => row.weekday === weekday);
        if (!day) {
          return false;
        }

        return day.items.some(item => {
          const copy = copies.get(item.studentPlanId);

          return copy?.exercises.some(row => row.exerciseId === exerciseId);
        });
      });
      let weights: number[];
      if (held !== null) {
        weights = sessionsWithExercise.map(() => held);
      } else {
        const delta = parseWeight(rule?.deltaKg ?? null) ?? 0;
        if (delta === 0 || !rule) {
          continue;
        }
        const start =
          parseWeight(rule.startWeightKg) ??
          maxCopyWeight(copies, exerciseId) ??
          0;
        const increment = parseWeight(rule.incrementKg) ?? 2.5;
        weights = interpolateWeights({
          startWeightKg: start,
          deltaKg: delta,
          incrementKg: increment,
          occurrenceCount: sessionsWithExercise.length,
        });
      }
      sessionsWithExercise.forEach((session, index) => {
        const map = result.get(session.id) ?? new Map<string, number>();
        const weight = weights[index];
        if (weight !== undefined) {
          map.set(exerciseId, weight);
        }
        result.set(session.id, map);
      });
    }

    return result;
  }

  /**
   *
   */
  private async toReturns(
    program: WorkoutProgramEntity,
    booking: RecurringBookingEntity,
  ): Promise<WorkoutProgramReturns> {
    const copies = await this.loadCopies(program, booking.coachId);
    const now = new Date();
    const horizonEnd = new Date(
      now.getTime() + program.horizonWeeks * MS_PER_WEEK,
    );
    const sessions = await this.sessions.findBookedByRecurringInRange(
      booking.id,
      now,
      horizonEnd,
    );
    const weightsBySession = this.weightsForSessions(
      program,
      booking,
      sessions,
      copies,
    );
    const preview: WorkoutProgramPreviewPoint[] = [];
    for (const session of sessions) {
      const weekday = localDateWeekday(
        formatZonedDate(session.startsAt, booking.timezone),
      );
      const map = weightsBySession.get(session.id);
      if (!map) {
        continue;
      }
      for (const [exerciseId, weightKg] of map) {
        preview.push({
          date: formatZonedDate(session.startsAt, booking.timezone),
          weekday,
          exerciseId,
          weightKg,
        });
      }
    }

    return {
      id: program.id,
      recurringBookingId: program.recurringBookingId,
      studentId: program.studentId,
      horizonWeeks: program.horizonWeeks,
      days: [...(program.days ?? [])]
        .sort((left, right) => left.weekday - right.weekday)
        .map(day => ({
          weekday: day.weekday,
          items: [...(day.items ?? [])]
            .sort((left, right) => left.sortOrder - right.sortOrder)
            .map(item => ({
              templateId: item.templateId,
              studentPlanId: item.studentPlanId,
              title: item.studentPlan?.title ?? '',
              sortOrder: item.sortOrder,
            })),
        })),
      progressionRules: (program.rules ?? []).map(rule => ({
        exerciseId: rule.exerciseId,
        startWeightKg: parseWeight(rule.startWeightKg),
        deltaKg: parseWeight(rule.deltaKg) ?? 0,
        incrementKg: parseWeight(rule.incrementKg) ?? 2.5,
        holdOnMiss: rule.holdOnMiss,
        heldWeightKg: parseWeight(rule.heldWeightKg),
      })),
      preview,
    };
  }

  /**
   *
   */
  private async loadCopies(
    program: WorkoutProgramEntity,
    coachId: string,
  ): Promise<Map<string, TrainingPlanReturns>> {
    const ids = [
      ...new Set(
        (program.days ?? []).flatMap(day =>
          (day.items ?? []).map(item => item.studentPlanId),
        ),
      ),
    ];
    const copies = new Map<string, TrainingPlanReturns>();
    for (const id of ids) {
      copies.set(id, await this.plans.getById(coachId, id));
    }

    return copies;
  }

  /**
   *
   */
  private async resolveDays(
    coachId: string,
    studentId: string,
    days: UpsertWorkoutProgramParams['days'],
  ): Promise<ReplaceProgramDayParams[]> {
    const result: ReplaceProgramDayParams[] = [];
    for (const day of days) {
      const items: ReplaceProgramDayParams['items'] = [];
      for (const [index, item] of day.items.entries()) {
        const copies = await this.plans.assign(coachId, {
          planId: item.templateId,
          studentIds: [studentId],
        });
        const copy = copies[0];
        if (!copy) {
          throw new BadRequestException('Failed to assign template');
        }
        items.push({
          templateId: item.templateId,
          studentPlanId: copy.id,
          sortOrder: index,
        });
      }
      result.push({
        weekday: day.weekday,
        items,
      });
    }

    return result;
  }

  /**
   *
   */
  private normalizeRules(
    rules: NonNullable<UpsertWorkoutProgramParams['progressionRules']>,
  ): ReplaceProgressionRuleParams[] {
    return rules.map(rule => ({
      exerciseId: rule.exerciseId,
      startWeightKg: rule.startWeightKg ?? null,
      deltaKg: rule.deltaKg ?? 0,
      incrementKg: rule.incrementKg ?? 2.5,
      holdOnMiss: rule.holdOnMiss ?? true,
      heldWeightKg: null,
    }));
  }

  /**
   *
   */
  private shouldRollHorizon(
    program: WorkoutProgramEntity,
    completed: SessionEntity,
  ): boolean {
    const now = completed.startsAt;
    const horizonEnd = new Date(
      now.getTime() + program.horizonWeeks * MS_PER_WEEK,
    );
    const remaining = horizonEnd.getTime() - now.getTime();

    return remaining < MS_PER_WEEK;
  }

  /**
   *
   */
  private async rollStartWeights(
    program: WorkoutProgramEntity,
    actualMax: Map<string, number>,
    snapshotMax: Map<string, number>,
  ): Promise<void> {
    for (const rule of program.rules ?? []) {
      const next =
        actualMax.get(rule.exerciseId) ?? snapshotMax.get(rule.exerciseId);
      if (next === undefined) {
        continue;
      }
      await this.programs.updateRuleStartWeight(
        program.id,
        rule.exerciseId,
        next,
      );
    }
  }

  /**
   *
   */
  private async syncCopyStarts(
    program: WorkoutProgramEntity,
    coachId: string,
  ): Promise<void> {
    const copies = await this.loadCopies(program, coachId);
    for (const rule of program.rules ?? []) {
      const start = parseWeight(rule.startWeightKg);
      if (start === null) {
        continue;
      }
      for (const copy of copies.values()) {
        if (!copy.exercises.some(row => row.exerciseId === rule.exerciseId)) {
          continue;
        }
        await this.plans.updateLoads(coachId, {
          planId: copy.id,
          items: [{ exerciseId: rule.exerciseId, weightKg: start }],
        });
      }
    }
  }

  /**
   *
   */
  private async requireOwned(
    coachId: string,
    recurringBookingId: string,
  ): Promise<RecurringBookingEntity> {
    const booking = await this.bookings.findById(recurringBookingId);
    if (!booking) {
      throw new NotFoundException('Recurring booking not found');
    }
    if (booking.coachId !== coachId) {
      throw new ForbiddenException('Not the series owner');
    }

    return booking;
  }

  /**
   *
   */
  private assertDays(
    days: UpsertWorkoutProgramParams['days'],
    seriesWeekdays: WeekdayNumber[],
  ): void {
    const allowed = new Set(seriesWeekdays);
    if (days.length === 0) {
      throw new BadRequestException('Program days must not be empty');
    }
    for (const day of days) {
      if (!allowed.has(day.weekday)) {
        throw new BadRequestException('Weekday is not in the series');
      }
      if (day.items.length === 0) {
        throw new BadRequestException('Each included day needs a workout');
      }
    }
  }

  /**
   *
   */
  private assertHorizon(horizonWeeks: number): void {
    if (horizonWeeks < 1 || horizonWeeks > 8) {
      throw new BadRequestException('horizonWeeks must be 1..8');
    }
  }
}

/**
 *
 */
function parseWeight(value: string | number | null | undefined): number | null {
  if (value === null || value === undefined || value === '') {
    return null;
  }
  const parsed = typeof value === 'number' ? value : Number(value);

  return Number.isFinite(parsed) ? parsed : null;
}

/**
 *
 */
function maxWeightByExercise(
  rows: Array<{ exerciseId: string; weightKg: string | number | null }>,
): Map<string, number> {
  const result = new Map<string, number>();
  for (const row of rows) {
    const weight = parseWeight(row.weightKg);
    if (weight === null) {
      continue;
    }
    const current = result.get(row.exerciseId);
    if (current === undefined || weight > current) {
      result.set(row.exerciseId, weight);
    }
  }

  return result;
}

/**
 *
 */
function maxCopyWeight(
  copies: Map<string, TrainingPlanReturns>,
  exerciseId: string,
): number | null {
  let max: number | null = null;
  for (const copy of copies.values()) {
    for (const exercise of copy.exercises) {
      if (exercise.exerciseId !== exerciseId) {
        continue;
      }
      for (const set of exercise.sets) {
        if (set.weightKg === null) {
          continue;
        }
        if (max === null || set.weightKg > max) {
          max = set.weightKg;
        }
      }
    }
  }

  return max;
}

/**
 *
 */
function uniqueExerciseIds(
  program: WorkoutProgramEntity,
  copies: Map<string, TrainingPlanReturns>,
): string[] {
  const ids = new Set<string>();
  for (const day of program.days ?? []) {
    for (const item of day.items ?? []) {
      const copy = copies.get(item.studentPlanId);
      for (const exercise of copy?.exercises ?? []) {
        ids.add(exercise.exerciseId);
      }
    }
  }

  return [...ids];
}
