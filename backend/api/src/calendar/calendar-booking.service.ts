import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { DataSource, type EntityManager } from 'typeorm';
import { ScheduleSlotEntity } from '../database/entity/schedule-slot.entity';
import { SessionEntity } from '../database/entity/session.entity';
import { CoachFinanceSettingsEntity } from '../database/entity/coach-finance-settings.entity';
import { SessionChargeEntity } from '../database/entity/session-charge.entity';
import { BookingRequestEntity } from '../database/entity/booking-request.entity';
import { UserEntity } from '../database/entity/user.entity';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import type { BookAtTimeParams } from './interface/book-at-time.params';
import type { BookSlotParams } from './interface/book-slot.params';
import { OCCUPIED_SLOT_STATUSES } from './util/occupied-slot-statuses.util';
import {
  type ChatDelivery,
  ChatSystemMessageService,
} from '../chat/chat-system-message.service';

@Injectable()
export class CalendarBookingService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly links: CoachStudentLinkRepository,
    @Optional() private readonly chat?: ChatSystemMessageService,
  ) {}

  /**
   * Book an existing open ScheduleSlot for a linked student.
   */
  async book(input: BookSlotParams): Promise<SessionEntity> {
    const deliveries: ChatDelivery[] = [];
    // eslint-disable-next-line complexity -- atomic booking checks belong together.
    const session = await this.dataSource.transaction(async manager => {
      const initialSlot = await manager.findOne(ScheduleSlotEntity, {
        where: { id: input.scheduleSlotId },
      });

      if (!initialSlot) {
        throw new NotFoundException('Slot not found');
      }
      await manager.findOneOrFail(UserEntity, {
        where: { id: initialSlot.coachId },
        lock: { mode: 'pessimistic_write' },
      });
      const slot = await manager.findOneOrFail(ScheduleSlotEntity, {
        where: { id: input.scheduleSlotId },
        lock: { mode: 'pessimistic_write' },
      });

      if (input.createdBy === 'student') {
        if (input.actorId !== input.studentId) {
          throw new ForbiddenException('Students can only book themselves');
        }
      } else if (slot.coachId !== input.actorId) {
        throw new ForbiddenException('Slot does not belong to coach');
      }

      await this.assertLinked(slot.coachId, input.studentId);

      await this.healOrphanBookedSlot(manager, slot);
      if (slot.status !== 'open') {
        throw new ConflictException('Slot is not open for booking');
      }
      await this.assertNotHeld(manager, slot.id);

      const booked = await this.createSessionChargeAndBookSlot(
        manager,
        slot,
        input,
      );
      await this.postBooked(manager, booked, input.notifyChat, deliveries);

      return booked;
    });
    this.chat?.publish(deliveries);

    return session;
  }

  /**
   * Create a one-off ScheduleSlot and book it atomically (no open exposure).
   */
  async bookAtTime(input: BookAtTimeParams): Promise<SessionEntity> {
    if (!(input.endsAt > input.startsAt)) {
      throw new BadRequestException('endsAt must be after startsAt');
    }
    if (input.createdBy === 'student') {
      throw new ForbiddenException('Students cannot book at an arbitrary time');
    }
    if (input.coachId !== input.actorId) {
      throw new ForbiddenException('Coach can only book on own calendar');
    }

    const deliveries: ChatDelivery[] = [];
    const session = await this.dataSource.transaction(async manager => {
      await manager.findOneOrFail(UserEntity, {
        where: { id: input.coachId },
        lock: { mode: 'pessimistic_write' },
      });

      await this.assertLinked(input.coachId, input.studentId);

      const overlapping = await manager
        .createQueryBuilder(ScheduleSlotEntity, 'slot')
        .where('slot.coach_id = :coachId', { coachId: input.coachId })
        .andWhere('slot.status IN (:...statuses)', {
          statuses: OCCUPIED_SLOT_STATUSES,
        })
        .andWhere('slot.starts_at < :endsAt AND slot.ends_at > :startsAt', {
          startsAt: input.startsAt,
          endsAt: input.endsAt,
        })
        .setLock('pessimistic_write')
        .getMany();

      for (const slot of overlapping) {
        await this.healOrphanBookedSlot(manager, slot);
      }

      const exact = overlapping.find(
        slot =>
          slot.startsAt.getTime() === input.startsAt.getTime() &&
          slot.endsAt.getTime() === input.endsAt.getTime(),
      );
      if (exact) {
        if (exact.status === 'open') {
          if (exact.mode !== input.mode) {
            throw new ConflictException('Slot mode does not match');
          }
          await this.assertNotHeld(manager, exact.id);
          const booked = await this.createSessionChargeAndBookSlot(manager, exact, {
            scheduleSlotId: exact.id,
            studentId: input.studentId,
            actorId: input.actorId,
            createdBy: input.createdBy,
            ...input.priceMinor !== undefined
              ? { priceMinor: input.priceMinor }
              : {},
            ...input.recurringBookingId !== undefined
              ? { recurringBookingId: input.recurringBookingId }
              : {},
            ...input.recurringLocalDate !== undefined
              ? { recurringLocalDate: input.recurringLocalDate }
              : {},
          });
          await this.postBooked(manager, booked, input.notifyChat, deliveries);

          return booked;
        }
        throw new ConflictException(
          'Interval overlaps an existing open, booked, or blocked slot',
        );
      }

      const remainingOverlap = overlapping.some(
        slot =>
          slot.status === 'open' ||
          slot.status === 'booked' ||
          slot.status === 'blocked',
      );
      if (remainingOverlap) {
        throw new ConflictException(
          'Interval overlaps an existing open, booked, or blocked slot',
        );
      }

      const slot = await manager.save(
        manager.create(ScheduleSlotEntity, {
          coachId: input.coachId,
          startsAt: input.startsAt,
          endsAt: input.endsAt,
          mode: input.mode,
          status: 'open',
          seriesId: null,
          gymId: null,
          capacity: 1,
        }),
      );

      const booked = await this.createSessionChargeAndBookSlot(manager, slot, {
        scheduleSlotId: slot.id,
        studentId: input.studentId,
        actorId: input.actorId,
        createdBy: input.createdBy,
        ...input.priceMinor !== undefined ? { priceMinor: input.priceMinor } : {},
        ...input.recurringBookingId !== undefined
          ? { recurringBookingId: input.recurringBookingId }
          : {},
        ...input.recurringLocalDate !== undefined
          ? { recurringLocalDate: input.recurringLocalDate }
          : {},
      });
      await this.postBooked(manager, booked, input.notifyChat, deliveries);

      return booked;
    });
    this.chat?.publish(deliveries);

    return session;
  }

  /**
   *
   */
  private async postBooked(
    manager: EntityManager,
    session: SessionEntity,
    notifyChat: boolean | undefined,
    deliveries: ChatDelivery[],
  ): Promise<void> {
    if (notifyChat !== true || !this.chat) {
      return;
    }
    deliveries.push(
      await this.chat.post({
        manager,
        coachId: session.coachId,
        studentId: session.studentId,
        type: 'session_booked',
        payload: {
          sessionId: session.id,
          startsAt: session.startsAt.toISOString(),
          endsAt: session.endsAt.toISOString(),
        },
      }),
    );
  }

  private async assertLinked(coachId: string, studentId: string): Promise<void> {
    const link = await this.links.findByPair(coachId, studentId);
    if (!link) {
      throw new ForbiddenException('Coach and student are not linked');
    }
  }

  private async assertNotHeld(
    manager: EntityManager,
    slotId: string,
  ): Promise<void> {
    const held = await manager
      .createQueryBuilder(BookingRequestEntity, 'request')
      .where('request.schedule_slot_id = :slotId', { slotId })
      .andWhere('request.status = \'pending\'')
      .andWhere('request.expires_at > :now', { now: new Date() })
      .getExists();
    if (held) {
      throw new ConflictException('Slot is held by a booking request');
    }
  }

  /**
   * Public heal for recurring classify / sync paths outside a booking tx.
   */
  async healOrphanBookedSlotEntity(
    slot: ScheduleSlotEntity,
  ): Promise<ScheduleSlotEntity> {
    return this.dataSource.transaction(async manager => {
      const locked = await manager.findOne(ScheduleSlotEntity, {
        where: { id: slot.id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!locked) {
        return slot;
      }
      await this.healOrphanBookedSlot(manager, locked);
      return locked;
    });
  }

  /**
   * If a slot is `booked` but has no active booked session, reopen it and detach
   * terminal sessions so the unique slot FK can be reused.
   */
  private async healOrphanBookedSlot(
    manager: EntityManager,
    slot: ScheduleSlotEntity,
  ): Promise<void> {
    if (slot.status !== 'booked') {
      return;
    }

    const active = await manager
      .createQueryBuilder(SessionEntity, 'session')
      .where('session.schedule_slot_id = :slotId', { slotId: slot.id })
      .andWhere('session.status = :status', { status: 'booked' })
      .getExists();

    if (active) {
      return;
    }

    slot.status = 'open';
    await manager.save(slot);

    await manager
      .createQueryBuilder()
      .update(SessionEntity)
      .set({ scheduleSlotId: null })
      .where('schedule_slot_id = :slotId', { slotId: slot.id })
      .andWhere('status != :booked', { booked: 'booked' })
      .execute();
  }

  private async createSessionChargeAndBookSlot(
    manager: EntityManager,
    slot: ScheduleSlotEntity,
    input: BookSlotParams,
  ): Promise<SessionEntity> {
    const settings = await manager.findOne(CoachFinanceSettingsEntity, {
      where: { coachId: slot.coachId },
    });
    if (!settings) {
      throw new ConflictException(
        'Coach must configure a positive session price before booking',
      );
    }

    const session = manager.create(SessionEntity, {
      coachId: slot.coachId,
      studentId: input.studentId,
      scheduleSlotId: slot.id,
      startsAt: slot.startsAt,
      endsAt: slot.endsAt,
      mode: slot.mode,
      status: 'booked',
      createdBy: input.createdBy,
      recurringBookingId: input.recurringBookingId ?? null,
      recurringLocalDate: input.recurringLocalDate ?? null,
    });

    try {
      const saved = await manager.save(session);
      await manager.save(
        manager.create(SessionChargeEntity, {
          sessionId: saved.id,
          coachId: slot.coachId,
          studentId: input.studentId,
          amountMinor:
            input.createdBy === 'coach' && input.priceMinor
              ? input.priceMinor
              : settings.defaultSessionPriceMinor,
          currency: settings.currency,
          status: 'pending',
          earnedAt: null,
          paidAt: null,
          paymentMethod: null,
          cancelledAt: null,
        }),
      );
      slot.status = 'booked';
      await manager.save(slot);

      return saved;
    } catch {
      throw new ConflictException('Slot already booked');
    }
  }
}
