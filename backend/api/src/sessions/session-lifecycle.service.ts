import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { SessionEntity } from '../database/entity/session.entity';
import { SessionHistoryEventEntity } from '../database/entity/session-history-event.entity';
import { SessionChargeEntity } from '../database/entity/session-charge.entity';
import { ScheduleSlotEntity } from '../database/entity/schedule-slot.entity';
import { SessionHistoryEventRepository } from '../database/repository/session-history-event.repository';
import { SessionRepository } from '../database/repository/session.repository';
import { SessionSetLogRepository } from '../database/repository/session-set-log.repository';
import { SessionWorkoutItemRepository } from '../database/repository/session-workout-item.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import type {
  ApplyTransitionParams,
  MarkNoShowParams,
  SessionHistoryEventReturns,
  TransitionSessionActor,
  TransitionSessionParams,
} from './interface/lifecycle.params';
import type { SessionModel } from './interface/session.model';
import type { SessionReturns } from './interface/session.returns';
import type { SessionStatus } from './interface/session.types';
import { canTransition } from './session-lifecycle.rules';
import { persistCompleteLogs } from './persist-complete-logs';
import { toSessionReturns } from './session-public.mapper';
import { toSessionWorkouts } from './session-workout.mapper';
import { getChargeLifecycleAction } from '../billing/session-charge-policy';
import { applySessionPackageDebit } from '../session-packages/apply-session-package-debit';
import { WorkoutProgramsService } from '../workout-programs/workout-programs.service';
import {
  type ChatDelivery,
  ChatSystemMessageService,
} from '../chat/chat-system-message.service';

@Injectable()
export class SessionLifecycleService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly sessions: SessionRepository,
    private readonly history: SessionHistoryEventRepository,
    private readonly profiles: UserProfileRepository,
    private readonly setLogs: SessionSetLogRepository,
    private readonly workoutItems: SessionWorkoutItemRepository,
    @Optional() private readonly programs?: WorkoutProgramsService,
    @Optional() private readonly chat?: ChatSystemMessageService,
  ) {}

  /**
   *
   */
  async complete(
    actor: TransitionSessionActor,
    params: TransitionSessionParams,
  ): Promise<SessionReturns> {
    if (!actor.permissions.includes('sessions:complete')) {
      throw new ForbiddenException('Missing sessions:complete permission');
    }

    return this.applyTransition({
      sessionId: params.sessionId,
      actorId: actor.id,
      toStatus: 'completed',
      requireRole: 'coach',
      ...params.note !== undefined ? { note: params.note } : {},
      ...params.logs !== undefined ? { logs: params.logs } : {},
    });
  }

  /**
   *
   */
  async cancel(
    actor: TransitionSessionActor,
    params: TransitionSessionParams,
  ): Promise<SessionReturns> {
    if (!actor.permissions.includes('sessions:cancel')) {
      throw new ForbiddenException('Missing sessions:cancel permission');
    }

    return this.applyTransition({
      sessionId: params.sessionId,
      actorId: actor.id,
      toStatus: 'cancelled',
      requireRole: 'participant',
      // Cancel frees the calendar slot by default (trainer can rebook the hour).
      releaseSlot: params.releaseSlot ?? true,
      ...params.note !== undefined ? { note: params.note } : {},
      ...params.silentChat !== undefined
        ? { silentChat: params.silentChat }
        : {},
    });
  }

  /**
   *
   */
  async markNoShow(
    actor: TransitionSessionActor,
    params: MarkNoShowParams,
  ): Promise<SessionReturns> {
    if (!actor.permissions.includes('sessions:mark_no_show')) {
      throw new ForbiddenException('Missing sessions:mark_no_show permission');
    }

    return this.applyTransition({
      sessionId: params.sessionId,
      actorId: actor.id,
      toStatus: 'no_show',
      requireRole: 'coach',
      chargeNoShow: params.charge,
      ...params.note !== undefined ? { note: params.note } : {},
    });
  }

  /**
   *
   */
  async listHistory(
    actorId: string,
    sessionId: string,
  ): Promise<SessionHistoryEventReturns[]> {
    const session = await this.sessions.findByIdWithPeople(sessionId);
    if (!session) {
      throw new NotFoundException('Session not found');
    }
    if (session.coachId !== actorId && session.studentId !== actorId) {
      throw new ForbiddenException('Not a participant of this session');
    }

    const events = await this.history.findBySessionId(sessionId);

    return events.map(event => ({
      id: event.id,
      sessionId: event.sessionId,
      actorUserId: event.actorUserId,
      actorEmail: event.actor?.email ?? null,
      fromStatus: event.fromStatus,
      toStatus: event.toStatus,
      note: event.note,
      createdAt: event.createdAt.toISOString(),
    }));
  }

  /**
   * By default cancel frees ScheduleSlot (`releaseSlot` defaults true on cancel):
   * reopen slot and detach the session so the hour can be rebooked.
   */
  private async applyTransition(
    params: ApplyTransitionParams,
  ): Promise<SessionReturns> {
    const deliveries: ChatDelivery[] = [];
    const { saved, packageExhausted } = await this.dataSource.transaction(
      async manager => {
        const session = await manager.findOne(SessionEntity, {
          where: { id: params.sessionId },
          lock: { mode: 'pessimistic_write' },
        });

        if (!session) {
          throw new NotFoundException('Session not found');
        }

        if (params.requireRole === 'coach') {
          if (session.coachId !== params.actorId) {
            throw new ForbiddenException('Only the session coach may do this');
          }
        } else if (
          session.coachId !== params.actorId &&
          session.studentId !== params.actorId
        ) {
          throw new ForbiddenException('Not a participant of this session');
        }

        if (!canTransition(session.status, params.toStatus)) {
          throw new ConflictException(
            `Cannot transition from status ${session.status} to ${params.toStatus}`,
          );
        }

        const fromStatus: SessionStatus = session.status;
        const transitionAt = new Date();
        const charge = await manager.findOne(SessionChargeEntity, {
          where: { sessionId: session.id },
          lock: { mode: 'pessimistic_write' },
        });
        if (charge) {
          if (charge.status !== 'pending') {
            throw new ConflictException(
              'Finalized session charge cannot follow lifecycle transition',
            );
          }
          const action = getChargeLifecycleAction(
            params.toStatus,
            params.chargeNoShow,
          );
          if (action === 'earn') {
            charge.earnedAt = transitionAt;
          } else {
            charge.status = 'cancelled';
            charge.cancelledAt = transitionAt;
          }
          await manager.save(charge);
        }

        session.status = params.toStatus;

        if (
          params.toStatus === 'cancelled' &&
          params.releaseSlot === true &&
          session.scheduleSlotId
        ) {
          const slotId = session.scheduleSlotId;
          const slot = await manager.findOne(ScheduleSlotEntity, {
            where: { id: slotId },
            lock: { mode: 'pessimistic_write' },
          });
          if (slot && slot.status === 'booked') {
            slot.status = 'open';
            await manager.save(slot);
          }
          session.scheduleSlotId = null;
        }

        const updated = await manager.save(session);

        if (params.toStatus === 'completed') {
          await persistCompleteLogs(manager, this.setLogs, {
            sessionId: session.id,
            studentPlanId: session.studentPlanId,
            ...params.logs !== undefined ? { logs: params.logs } : {},
          });
        }

        const event = manager.create(SessionHistoryEventEntity, {
          sessionId: session.id,
          actorUserId: params.actorId,
          fromStatus,
          toStatus: params.toStatus,
          note: params.note ?? null,
        });
        await manager.save(event);

        if (
          params.toStatus === 'cancelled' &&
          params.silentChat !== true &&
          this.chat
        ) {
          deliveries.push(
            await this.chat.post({
              manager,
              coachId: session.coachId,
              studentId: session.studentId,
              type: 'session_cancelled',
              payload: {
                sessionId: session.id,
                startsAt: session.startsAt.toISOString(),
                endsAt: session.endsAt.toISOString(),
                note: params.note ?? null,
              },
            }),
          );
        }

        const debit = await applySessionPackageDebit(manager, {
          coachId: session.coachId,
          studentId: session.studentId,
          sessionId: session.id,
          toStatus: params.toStatus,
          ...params.chargeNoShow !== undefined
            ? { chargeNoShow: params.chargeNoShow }
            : {},
        });

        return {
          saved: updated,
          packageExhausted: debit.packageExhausted,
        };
      },
    );

    this.chat?.publish(deliveries);
    const withPeople =
      await this.sessions.findByIdWithPeople(saved.id) ?? saved;
    if (saved.status === 'completed') {
      await this.programs?.onSessionCompleted(saved.id);
    }

    return this.toPublic(withPeople, packageExhausted);
  }

  /**
   *
   */
  private async toPublic(
    session: SessionModel,
    packageExhausted = false,
  ): Promise<SessionReturns> {
    const profiles = await this.profiles.findByUserIds([
      session.coachId,
      session.studentId,
    ]);
    const items = await this.workoutItems.findBySessionId(session.id);
    const nameById = new Map(
      profiles.map(profile => [profile.userId, profile.displayName]),
    );

    return toSessionReturns(
      { ...session, workouts: toSessionWorkouts(items) },
      nameById,
      { packageExhausted },
    );
  }
}
