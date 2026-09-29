import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CalendarBookingService } from '../calendar/calendar-booking.service';
import { SessionRepository } from '../database/repository/session.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import { PlansService } from '../plans/plans.service';
import { SessionWorkoutItemRepository } from '../database/repository/session-workout-item.repository';
import type {
  BookSessionActor,
  BookSessionParams,
} from './interface/book-session.params';
import type {
  FindSessionsForUserParams,
  ListSessionsQuery,
} from './interface/list-sessions.params';
import type {
  GetSessionParams,
  PatchSessionPlanParams,
  PatchSessionWorkoutLoadsParams,
} from './interface/patch-session-plan.params';
import type { SessionModel } from './interface/session.model';
import type { SessionReturns } from './interface/session.returns';
import type { SessionStatus } from './interface/session.types';
import { toSessionReturns } from './session-public.mapper';
import { toSessionWorkouts } from './session-workout.mapper';
import { snapshotFromPlan, snapshotFromStoredItem } from './session-workout.snapshot';
import { BookingRequestsService } from '../booking-requests/booking-requests.service';

const ALLOWED_STATUSES: SessionStatus[] = [
  'booked',
  'completed',
  'cancelled',
  'no_show',
];

@Injectable()
export class SessionsService {
  constructor(
    private readonly booking: CalendarBookingService,
    private readonly sessions: SessionRepository,
    private readonly bookingRequests: BookingRequestsService,
    private readonly profiles: UserProfileRepository,
    private readonly plans: PlansService,
    private readonly workoutItems: SessionWorkoutItemRepository,
  ) {}

  /**
   *
   */
  async book(
    actor: BookSessionActor,
    params: BookSessionParams,
  ): Promise<SessionReturns> {
    await this.bookingRequests.expireDue(new Date());
    this.assertBookXor(params);
    const canBookSelf = actor.permissions.includes('sessions:book_self');
    const canBookForStudent = actor.permissions.includes(
      'sessions:book_for_student',
    );
    if (actor.roles?.includes('student')) {
      throw new ForbiddenException(
        'Direct student booking is disabled; create a booking request instead',
      );
    }

    if (
      canBookForStudent &&
      params.studentId &&
      params.studentId !== actor.id
    ) {
      return this.bookForStudent(actor, params);
    }

    if (canBookSelf) {
      return this.bookSelf(actor, params);
    }

    throw new ForbiddenException('Missing booking permission');
  }

  /**
   *
   */
  async listOwn(
    userId: string,
    query: ListSessionsQuery,
  ): Promise<SessionReturns[]> {
    const options: FindSessionsForUserParams = {};
    if (query.from) {
      options.from = this.parseDate(query.from);
    }
    if (query.to) {
      options.to = this.parseDate(query.to);
    }
    if (query.status) {
      options.statuses = this.parseStatuses(query.status);
    }
    if (query.studentId) {
      options.studentId = query.studentId;
    }
    const items = await this.sessions.findForUser(userId, options);

    return this.toPublicMany(items);
  }

  /**
   *
   */
  async getById(params: GetSessionParams): Promise<SessionReturns> {
    const session = await this.sessions.findByIdWithPeople(params.sessionId);
    if (!session) {
      throw new NotFoundException('Session not found');
    }
    if (
      session.coachId !== params.actorId &&
      session.studentId !== params.actorId
    ) {
      throw new ForbiddenException('Not a participant of this session');
    }
    const mapped = await this.toPublicOne(session);
    if (!session.studentPlanId) {
      return mapped;
    }
    try {
      const plan = await this.plans.getById(
        params.actorId,
        session.studentPlanId,
      );

      return { ...mapped, plan };
    } catch {
      return mapped;
    }
  }

  /**
   *
   */
  async patchStudentPlan(
    params: PatchSessionPlanParams,
  ): Promise<SessionReturns> {
    if (!params.permissions.includes('sessions:book_for_student')) {
      throw new ForbiddenException(
        'Missing sessions:book_for_student permission',
      );
    }
    const session = await this.sessions.findByIdWithPeople(params.sessionId);
    if (!session) {
      throw new NotFoundException('Session not found');
    }
    if (session.coachId !== params.actorId) {
      throw new ForbiddenException('Only the session coach may attach a plan');
    }
    const planIds = resolvePatchPlanIds(params);
    if (planIds === undefined) {
      return this.getById({
        actorId: params.actorId,
        sessionId: session.id,
      });
    }
    if (planIds.length === 0) {
      await this.workoutItems.replaceForSession(session.id, []);

      return this.getById({
        actorId: params.actorId,
        sessionId: session.id,
      });
    }
    const snapshots: ReturnType<typeof snapshotFromPlan>[] = [];
    for (const planId of planIds) {
      const plan = await this.plans.getById(params.actorId, planId);
      if (
        plan.kind !== 'student_copy' ||
        plan.assignedStudentId !== session.studentId ||
        plan.ownerCoachId !== session.coachId
      ) {
        throw new BadRequestException(
          'Plan must be a student copy for this session student',
        );
      }
      snapshots.push(
        snapshotFromPlan(plan, {
          source: 'manual',
          overrideAt: new Date(),
        }),
      );
    }
    await this.workoutItems.replaceForSession(session.id, snapshots);

    return this.getById({
      actorId: params.actorId,
      sessionId: session.id,
    });
  }

  /**
   *
   */
  async patchWorkoutLoads(
    params: PatchSessionWorkoutLoadsParams,
  ): Promise<SessionReturns> {
    if (!params.permissions.includes('sessions:book_for_student')) {
      throw new ForbiddenException(
        'Missing sessions:book_for_student permission',
      );
    }
    const session = await this.sessions.findByIdWithPeople(params.sessionId);
    if (!session) {
      throw new NotFoundException('Session not found');
    }
    if (session.coachId !== params.actorId) {
      throw new ForbiddenException('Only the session coach may attach a plan');
    }
    const items = await this.workoutItems.findBySessionId(session.id);
    if (!items.some(item => item.studentPlanId === params.studentPlanId)) {
      throw new BadRequestException('Workout is not attached to this session');
    }
    const weightByExercise = new Map(
      params.items.map(item => [item.exerciseId, item.weightKg]),
    );
    const snapshots = items.map(item =>
      snapshotFromStoredItem(item, {
        ...(item.studentPlanId === params.studentPlanId
          ? { overrideAt: new Date(), weightByExercise }
          : {}),
      }),
    );
    await this.workoutItems.replaceForSession(session.id, snapshots);

    return this.getById({
      actorId: params.actorId,
      sessionId: session.id,
    });
  }

  private async bookForStudent(
    actor: BookSessionActor,
    params: BookSessionParams,
  ): Promise<SessionReturns> {
    const studentId = params.studentId ?? actor.id;
    const session =
      params.scheduleSlotId != null
        ? await this.booking.book({
            scheduleSlotId: params.scheduleSlotId,
            studentId,
            actorId: actor.id,
            createdBy: 'coach',
            ...params.priceMinor !== undefined
              ? { priceMinor: params.priceMinor }
              : {},
          })
        : await this.booking.bookAtTime({
            coachId: actor.id,
            studentId,
            actorId: actor.id,
            createdBy: 'coach',
            startsAt: new Date(params.startsAt!),
            endsAt: new Date(params.endsAt!),
            mode: params.mode ?? 'offline',
            ...params.priceMinor !== undefined
              ? { priceMinor: params.priceMinor }
              : {},
          });

    return this.toPublicOne(
      (await this.sessions.findByIdWithPeople(session.id)) ?? session,
    );
  }

  private async bookSelf(
    actor: BookSessionActor,
    params: BookSessionParams,
  ): Promise<SessionReturns> {
    if (params.priceMinor !== undefined) {
      throw new ForbiddenException('Students cannot override session price');
    }
    if (params.studentId && params.studentId !== actor.id) {
      throw new ForbiddenException('Cannot book for another user');
    }
    if (params.scheduleSlotId == null) {
      throw new BadRequestException(
        'scheduleSlotId is required for self booking',
      );
    }
    const session = await this.booking.book({
      scheduleSlotId: params.scheduleSlotId,
      studentId: actor.id,
      actorId: actor.id,
      createdBy: 'student',
    });

    return this.toPublicOne(
      (await this.sessions.findByIdWithPeople(session.id)) ?? session,
    );
  }

  private assertBookXor(params: BookSessionParams): void {
    const hasSlot = params.scheduleSlotId != null;
    const hasStart = params.startsAt != null;
    const hasEnd = params.endsAt != null;
    const hasRange = hasStart || hasEnd;

    if (hasSlot && hasRange) {
      throw new BadRequestException(
        'Provide either scheduleSlotId or startsAt/endsAt, not both',
      );
    }
    if (!hasSlot && !(hasStart && hasEnd)) {
      throw new BadRequestException(
        'Provide scheduleSlotId or both startsAt and endsAt',
      );
    }
    if (!hasSlot && !params.studentId) {
      throw new BadRequestException(
        'studentId is required when booking at a time range',
      );
    }
    if (!hasSlot) {
      const startsAt = new Date(params.startsAt!);
      const endsAt = new Date(params.endsAt!);
      if (Number.isNaN(startsAt.getTime()) || Number.isNaN(endsAt.getTime())) {
        throw new BadRequestException('Invalid startsAt/endsAt datetime');
      }
      if (!(endsAt > startsAt)) {
        throw new BadRequestException('endsAt must be after startsAt');
      }
    }
  }

  /**
   *
   */
  private parseStatuses(raw: string): SessionStatus[] {
    const parts = raw
      .split(',')
      .map(part => part.trim())
      .filter(part => part.length > 0);
    if (parts.length === 0) {
      throw new BadRequestException('Invalid status filter');
    }
    for (const part of parts) {
      if (!ALLOWED_STATUSES.includes(part as SessionStatus)) {
        throw new BadRequestException(`Invalid status: ${part}`);
      }
    }

    return parts as SessionStatus[];
  }

  /**
   *
   */
  private parseDate(value: string): Date {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw new BadRequestException('Invalid from/to datetime');
    }

    return date;
  }

  private async toPublicOne(session: SessionModel): Promise<SessionReturns> {
    const [mapped] = await this.toPublicMany([session]);
    return mapped!;
  }

  private async toPublicMany(
    sessions: SessionModel[],
  ): Promise<SessionReturns[]> {
    const ids = [
      ...new Set(
        sessions.flatMap(session => [session.coachId, session.studentId]),
      ),
    ];
    const profiles = await this.profiles.findByUserIds(ids);
    const nameById = new Map(
      profiles.map(profile => [profile.userId, profile.displayName]),
    );
    const withWorkouts = await this.attachWorkouts(sessions);

    return withWorkouts.map(session => toSessionReturns(session, nameById));
  }

  /**
   *
   */
  private async attachWorkouts(
    sessions: SessionModel[],
  ): Promise<SessionModel[]> {
    const items = await this.workoutItems.findBySessionIds(
      sessions.map(session => session.id),
    );
    const bySession = new Map<string, typeof items>();
    for (const item of items) {
      const list = bySession.get(item.sessionId) ?? [];
      list.push(item);
      bySession.set(item.sessionId, list);
    }

    return sessions.map(session => ({
      ...session,
      workouts: toSessionWorkouts(bySession.get(session.id) ?? []),
    }));
  }
}

/**
 *
 */
function resolvePatchPlanIds(
  params: PatchSessionPlanParams,
): string[] | undefined {
  if (params.workoutPlanIds !== undefined) {
    return params.workoutPlanIds;
  }
  if (params.studentPlanId === undefined) {
    return undefined;
  }
  if (params.studentPlanId === null) {
    return [];
  }

  return [params.studentPlanId];
}
