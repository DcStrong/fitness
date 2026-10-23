import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DataSource, QueryFailedError } from 'typeorm';
import { BookingRequestEntity } from '../database/entity/booking-request.entity';
import { BookingRequestEventEntity } from '../database/entity/booking-request-event.entity';
import { CoachFinanceSettingsEntity } from '../database/entity/coach-finance-settings.entity';
import { CoachStudentLinkEntity } from '../database/entity/coach-student-link.entity';
import { ScheduleSlotEntity } from '../database/entity/schedule-slot.entity';
import { SessionChargeEntity } from '../database/entity/session-charge.entity';
import { SessionEntity } from '../database/entity/session.entity';
import { UserEntity } from '../database/entity/user.entity';
import { BookingRequestRepository } from '../database/repository/booking-request.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import {
  type ChatDelivery,
  ChatSystemMessageService,
} from '../chat/chat-system-message.service';
import type { ChatSystemPayload, ChatSystemType } from '../chat/interface';
import {
  assertPendingBookingRequest,
  BOOKING_REQUEST_REJECTION_COMMENT_MAX_LENGTH,
  calculateBookingRequestExpiry,
} from './booking-request.rules';
import type {
  AlternateBookingRequestParams,
  BookingRequestModel,
  BookingRequestPage,
  BookingRequestPageParams,
  BookingRequestSlotSummary,
  CreateBookingRequestParams,
  ExpireDueReturns,
  PendingCountReturns,
  RejectBookingRequestParams,
} from './interface';

@Injectable()
export class BookingRequestsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly requests: BookingRequestRepository,
    private readonly profiles: UserProfileRepository,
    @Optional() private readonly chat?: ChatSystemMessageService,
  ) {}

  /**
   *
   */
  async create(params: CreateBookingRequestParams): Promise<BookingRequestModel> {
    await this.expireDue(new Date());
    try {
      const requestId = await this.dataSource.transaction(async manager => {
        const initialSlot = await manager.findOne(ScheduleSlotEntity, {
          where: { id: params.scheduleSlotId },
        });
        if (!initialSlot) {
throw new NotFoundException('Slot not found');
}
        await this.lockCoach(manager, initialSlot.coachId);
        const slot = await manager.findOneOrFail(ScheduleSlotEntity, {
          where: { id: params.scheduleSlotId },
          lock: { mode: 'pessimistic_write' },
        });
        if (slot.status !== 'open' || slot.startsAt <= new Date()) {
          throw new ConflictException('Slot is not requestable');
        }
        await this.requireLink(manager, slot.coachId, params.studentId);
        const settings = await manager.findOne(CoachFinanceSettingsEntity, {
          where: { coachId: slot.coachId },
        });
        if (
          !settings ||
          !/^[1-9]\d*$/u.test(settings.defaultSessionPriceMinor)
        ) {
          throw new ConflictException(
            'Coach must configure a positive session price before requests',
          );
        }
        const now = new Date();
        const request = manager.create(BookingRequestEntity, {
          coachId: slot.coachId,
          studentId: params.studentId,
          scheduleSlotId: slot.id,
          status: 'pending',
          quotedPriceMinor: settings.defaultSessionPriceMinor,
          quotedCurrency: settings.currency,
          expiresAt: calculateBookingRequestExpiry(now, slot.startsAt),
          resolvedBy: null,
          resolvedAt: null,
          rejectionReason: null,
          rejectionComment: null,
          resolution: null,
          resolvedScheduleSlotId: null,
          sessionId: null,
        });
        const saved = await manager.save(request);
        await this.saveEvent(manager, saved.id, 'created', params.studentId);

        return saved.id;
      });

      return this.getMapped(requestId, params.studentId);
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw new ConflictException(
          'Slot is held or student already has a pending request to this coach',
        );
      }
      throw error;
    }
  }

  /**
   *
   */
  async listMine(
    studentId: string,
    params: BookingRequestPageParams,
  ): Promise<BookingRequestPage> {
    await this.expireDue(new Date());
    const [items, total] = await this.requests.findForStudent(studentId, params);

    return this.page(items, params, total, studentId);
  }

  /**
   *
   */
  async inbox(
    coachId: string,
    params: BookingRequestPageParams,
  ): Promise<BookingRequestPage> {
    await this.expireDue(new Date());
    const [items, total] = await this.requests.findForCoach(coachId, params);

    return this.page(items, params, total, coachId);
  }

  /**
   *
   */
  async pendingCount(coachId: string): Promise<PendingCountReturns> {
    const now = new Date();
    await this.expireDue(now);

    return { count: await this.requests.countPendingForCoach(coachId, now) };
  }

  /**
   *
   */
  async withdraw(requestId: string, studentId: string): Promise<BookingRequestModel> {
    await this.expireDue(new Date());

    return this.transitionWithoutBooking(
      requestId,
      studentId,
      'student',
      'withdrawn',
    );
  }

  /**
   *
   */
  async reject(params: RejectBookingRequestParams): Promise<BookingRequestModel> {
    await this.expireDue(new Date());
    const comment = params.comment?.trim() || null;
    if (
      comment &&
      comment.length > BOOKING_REQUEST_REJECTION_COMMENT_MAX_LENGTH
    ) {
      throw new BadRequestException('Rejection comment is too long');
    }

    return this.transitionWithoutBooking(
      params.requestId,
      params.coachId,
      'coach',
      'rejected',
      params.reason,
      comment,
    );
  }

  /**
   *
   */
  async accept(requestId: string, coachId: string): Promise<BookingRequestModel> {
    await this.expireDue(new Date());
    const deliveries: ChatDelivery[] = [];
    const id = await this.dataSource.transaction(async manager => {
      const request = await this.lockPendingRequest(manager, requestId);
      if (request.coachId !== coachId) {
        throw new ForbiddenException('Booking request does not belong to coach');
      }
      await this.lockCoach(manager, coachId);
      // Accept may establish the coach–student link for first-time requesters.
      await this.ensureLink(manager, coachId, request.studentId);
      const slot = await manager.findOneOrFail(ScheduleSlotEntity, {
        where: { id: request.scheduleSlotId },
        lock: { mode: 'pessimistic_write' },
      });
      if (slot.status !== 'open') {
        throw new ConflictException('Requested slot is no longer open');
      }
      const session = await this.createSessionAndCharge(
        manager,
        request,
        slot,
      );
      slot.status = 'booked';
      await manager.save(slot);
      this.resolveAccepted(request, coachId, slot.id, session.id, 'requested_slot');
      await manager.save(request);
      await this.saveEvent(manager, request.id, 'accepted', coachId, {
        resolution: 'requested_slot',
        sessionId: session.id,
      });
      await this.postChat(manager, request, 'request_accepted', {
        bookingRequestId: request.id,
        sessionId: session.id,
        startsAt: session.startsAt.toISOString(),
        endsAt: session.endsAt.toISOString(),
      }, deliveries);

      return request.id;
    });
    this.chat?.publish(deliveries);

    return this.getMapped(id, coachId);
  }

  /**
   *
   */
  async alternate(
    params: AlternateBookingRequestParams,
  ): Promise<BookingRequestModel> {
    await this.expireDue(new Date());
    const startsAt = new Date(params.startsAt);
    if (Number.isNaN(startsAt.getTime()) || startsAt <= new Date()) {
      throw new BadRequestException('Alternate start must be a future datetime');
    }
    const deliveries: ChatDelivery[] = [];
    const id = await this.dataSource.transaction(async manager => {
      const request = await this.lockPendingRequest(manager, params.requestId);
      if (request.coachId !== params.coachId) {
        throw new ForbiddenException('Booking request does not belong to coach');
      }
      await this.lockCoach(manager, params.coachId);
      await this.ensureLink(manager, params.coachId, request.studentId);
      const original = await manager.findOneOrFail(ScheduleSlotEntity, {
        where: { id: request.scheduleSlotId },
      });
      const duration = original.endsAt.getTime() - original.startsAt.getTime();
      const endsAt = new Date(startsAt.getTime() + duration);
      const slotConflict = await manager
        .createQueryBuilder(ScheduleSlotEntity, 'slot')
        .where('slot.coach_id = :coachId', { coachId: params.coachId })
        .andWhere('slot.status IN (:...statuses)', {
          statuses: ['open', 'booked'],
        })
        .andWhere('slot.starts_at < :endsAt AND slot.ends_at > :startsAt', {
          startsAt,
          endsAt,
        })
        .getExists();
      const sessionConflict = await manager
        .createQueryBuilder(SessionEntity, 'session')
        .where('session.coach_id = :coachId', { coachId: params.coachId })
        .andWhere('session.status = \'booked\'')
        .andWhere(
          'session.starts_at < :endsAt AND session.ends_at > :startsAt',
          { startsAt, endsAt },
        )
        .getExists();
      if (slotConflict || sessionConflict) {
        throw new ConflictException('Alternate time overlaps coach calendar');
      }
      const slot = await manager.save(
        manager.create(ScheduleSlotEntity, {
          coachId: params.coachId,
          startsAt,
          endsAt,
          mode: original.mode,
          status: 'open',
          seriesId: null,
          gymId: original.gymId,
          capacity: original.capacity,
        }),
      );
      const session = await this.createSessionAndCharge(
        manager,
        request,
        slot,
      );
      slot.status = 'booked';
      await manager.save(slot);
      this.resolveAccepted(
        request,
        params.coachId,
        slot.id,
        session.id,
        'alternate_slot',
      );
      await manager.save(request);
      await this.saveEvent(manager, request.id, 'accepted', params.coachId, {
        resolution: 'alternate_slot',
        sessionId: session.id,
      });
      await this.postChat(manager, request, 'request_alternate', {
        bookingRequestId: request.id,
        sessionId: session.id,
        startsAt: session.startsAt.toISOString(),
        endsAt: session.endsAt.toISOString(),
        previousStartsAt: original.startsAt.toISOString(),
      }, deliveries);

      return request.id;
    });
    this.chat?.publish(deliveries);

    return this.getMapped(id, params.coachId);
  }

  /**
   *
   */
  @Cron(CronExpression.EVERY_MINUTE)
  async expireScheduled(): Promise<void> {
    await this.expireDue(new Date());
  }

  /**
   *
   */
  async expireDue(now: Date): Promise<ExpireDueReturns> {
    return this.dataSource.transaction(async manager => {
      const expired = await this.requests.expireDue(manager, now);
      for (const row of expired) {
        await this.saveEvent(manager, row.id, 'expired', null);
      }

      return { expiredCount: expired.length };
    });
  }

  /**
   *
   */
  private async transitionWithoutBooking(
    requestId: string,
    actorId: string,
    owner: 'student' | 'coach',
    status: 'withdrawn' | 'rejected',
    reason: RejectBookingRequestParams['reason'] | null = null,
    comment: string | null = null,
  ): Promise<BookingRequestModel> {
    const deliveries: ChatDelivery[] = [];
    const id = await this.dataSource.transaction(async manager => {
      const request = await this.lockPendingRequest(manager, requestId);
      const studentOwnershipMismatch =
        owner === 'student' && request.studentId !== actorId;
      const coachOwnershipMismatch =
        owner === 'coach' && request.coachId !== actorId;
      if (studentOwnershipMismatch || coachOwnershipMismatch) {
        throw new ForbiddenException('Booking request ownership mismatch');
      }
      // Reject/withdraw must work even when the pair is not linked yet.
      request.status = status;
      request.resolvedBy = actorId;
      request.resolvedAt = new Date();
      request.rejectionReason = reason;
      request.rejectionComment = comment;
      await manager.save(request);
      await this.saveEvent(manager, request.id, status, actorId, {
        ...reason ? { reason } : {},
        ...comment ? { comment } : {},
      });
      // Only linked pairs have a chat; a first-time requester gets no thread.
      const linked = await manager.exists(CoachStudentLinkEntity, {
        where: { coachId: request.coachId, studentId: request.studentId },
      });
      if (status === 'rejected' && linked) {
        const slot = await manager.findOne(ScheduleSlotEntity, {
          where: { id: request.scheduleSlotId },
        });
        await this.postChat(manager, request, 'request_rejected', {
          bookingRequestId: request.id,
          startsAt: slot?.startsAt.toISOString() ?? null,
          endsAt: slot?.endsAt.toISOString() ?? null,
          note: comment,
        }, deliveries);
      }

      return request.id;
    });
    this.chat?.publish(deliveries);

    return this.getMapped(id, actorId);
  }

  /**
   *
   */
  private async postChat(
    manager: import('typeorm').EntityManager,
    request: BookingRequestEntity,
    type: ChatSystemType,
    payload: ChatSystemPayload,
    deliveries: ChatDelivery[],
  ): Promise<void> {
    if (!this.chat) {
      return;
    }
    deliveries.push(
      await this.chat.post({
        manager,
        coachId: request.coachId,
        studentId: request.studentId,
        type,
        payload,
      }),
    );
  }

  /**
   *
   */
  private async lockPendingRequest(
    manager: import('typeorm').EntityManager,
    requestId: string,
  ): Promise<BookingRequestEntity> {
    const request = await this.requests.findByIdForUpdate(manager, requestId);
    if (!request) {
throw new NotFoundException('Booking request not found');
}
    assertPendingBookingRequest(request.status);
    if (request.expiresAt <= new Date()) {
      throw new ConflictException('Booking request has expired');
    }

    return request;
  }

  /**
   *
   */
  private async createSessionAndCharge(
    manager: import('typeorm').EntityManager,
    request: BookingRequestEntity,
    slot: ScheduleSlotEntity,
  ): Promise<SessionEntity> {
    const session = await manager.save(
      manager.create(SessionEntity, {
        coachId: request.coachId,
        studentId: request.studentId,
        scheduleSlotId: slot.id,
        startsAt: slot.startsAt,
        endsAt: slot.endsAt,
        mode: slot.mode,
        status: 'booked',
        createdBy: 'coach',
      }),
    );
    await manager.save(
      manager.create(SessionChargeEntity, {
        sessionId: session.id,
        coachId: request.coachId,
        studentId: request.studentId,
        amountMinor: request.quotedPriceMinor,
        currency: request.quotedCurrency,
        status: 'pending',
        earnedAt: null,
        paidAt: null,
        paymentMethod: null,
        cancelledAt: null,
      }),
    );

    return session;
  }

  /**
   *
   */
  private resolveAccepted(
    request: BookingRequestEntity,
    coachId: string,
    slotId: string,
    sessionId: string,
    resolution: 'requested_slot' | 'alternate_slot',
  ): void {
    request.status = 'accepted';
    request.resolvedBy = coachId;
    request.resolvedAt = new Date();
    request.resolution = resolution;
    request.resolvedScheduleSlotId = slotId;
    request.sessionId = sessionId;
  }

  /**
   *
   */
  private async getMapped(
    id: string,
    viewerId: string,
  ): Promise<BookingRequestModel> {
    const request = await this.requests.findById(id);
    if (!request) {
      throw new NotFoundException('Booking request not found');
    }

    const nameById = await this.loadDisplayNames([request]);
    return this.toModel(request, viewerId, nameById);
  }

  /**
   *
   */
  private async page(
    items: BookingRequestEntity[],
    params: BookingRequestPageParams,
    total: number,
    viewerId: string,
  ): Promise<BookingRequestPage> {
    const nameById = await this.loadDisplayNames(items);
    return {
      items: items.map(item => this.toModel(item, viewerId, nameById)),
      meta: {
        page: params.page,
        limit: params.limit,
        total,
        totalPages: Math.ceil(total / params.limit),
      },
    };
  }

  private async loadDisplayNames(
    items: BookingRequestEntity[],
  ): Promise<Map<string, string | null>> {
    const ids = [
      ...new Set(items.flatMap(item => [item.coachId, item.studentId])),
    ];
    const profiles = await this.profiles.findByUserIds(ids);
    return new Map(
      profiles.map(profile => [profile.userId, profile.displayName]),
    );
  }

  /**
   *
   */
  private toModel(
    request: BookingRequestEntity,
    viewerId: string,
    nameById: Map<string, string | null>,
  ): BookingRequestModel {
    const requested = request.scheduleSlot;
    const resolved = request.resolvedScheduleSlot;
    const counterpartId =
      viewerId === request.studentId ? request.coachId : request.studentId;
    const displayName = nameById.get(counterpartId)?.trim();
    const fallbackRole =
      viewerId === request.studentId ? 'Тренер' : 'Ученик';

    return {
      id: request.id,
      coachId: request.coachId,
      studentId: request.studentId,
      scheduleSlotId: request.scheduleSlotId,
      status: request.status,
      quotedPriceMinor: request.quotedPriceMinor,
      quotedCurrency: request.quotedCurrency,
      expiresAt: request.expiresAt.toISOString(),
      resolvedBy: request.resolvedBy,
      resolvedAt: request.resolvedAt?.toISOString() ?? null,
      rejectionReason: request.rejectionReason,
      rejectionComment: request.rejectionComment,
      resolution: request.resolution,
      resolvedScheduleSlotId: request.resolvedScheduleSlotId,
      sessionId: request.sessionId,
      requestedSlot: this.slotSummary(requested),
      resolvedSlot: resolved ? this.slotSummary(resolved) : null,
      counterpart: {
        id: counterpartId,
        label:
          displayName && displayName.length > 0 ? displayName : fallbackRole,
      },
      createdAt: request.createdAt.toISOString(),
      updatedAt: request.updatedAt.toISOString(),
    };
  }

  /**
   *
   */
  private slotSummary(slot: ScheduleSlotEntity): BookingRequestSlotSummary {
    return {
      id: slot.id,
      startsAt: slot.startsAt.toISOString(),
      endsAt: slot.endsAt.toISOString(),
      mode: slot.mode,
    };
  }

  /**
   *
   */
  private async requireLink(
    manager: import('typeorm').EntityManager,
    coachId: string,
    studentId: string,
  ): Promise<void> {
    const link = await manager.findOne(CoachStudentLinkEntity, {
      where: { coachId, studentId },
    });
    if (!link) {
      throw new ForbiddenException('Coach and student are not linked');
    }
  }

  /**
   * Ensures an active coach–student link exists (creates one on first accept).
   */
  private async ensureLink(
    manager: import('typeorm').EntityManager,
    coachId: string,
    studentId: string,
  ): Promise<void> {
    const link = await manager.findOne(CoachStudentLinkEntity, {
      where: { coachId, studentId },
    });
    if (link) {
      return;
    }
    await manager.save(
      manager.create(CoachStudentLinkEntity, {
        coachId,
        studentId,
        sourceInvitationId: null,
      }),
    );
  }

  /**
   *
   */
  private async lockCoach(
    manager: import('typeorm').EntityManager,
    coachId: string,
  ): Promise<void> {
    await manager.findOneOrFail(UserEntity, {
      where: { id: coachId },
      lock: { mode: 'pessimistic_write' },
    });
  }

  /**
   *
   */
  private async saveEvent(
    manager: import('typeorm').EntityManager,
    bookingRequestId: string,
    eventType: BookingRequestEventEntity['eventType'],
    actorId: string | null,
    metadata: Record<string, unknown> = {},
  ): Promise<void> {
    await manager.save(
      manager.create(BookingRequestEventEntity, {
        bookingRequestId,
        eventType,
        actorId,
        metadata,
      }),
    );
  }

  /**
   *
   */
  private isUniqueViolation(error: unknown): boolean {
    return (
      error instanceof QueryFailedError &&
      (error.driverError as { code?: string; }).code === '23505'
    );
  }
}
