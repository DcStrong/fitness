import { earliestRequestableSlotStart } from '../booking-requests/booking-request.rules';
import { BookingRequestsService } from '../booking-requests/booking-requests.service';
import { OCCUPIED_SLOT_STATUSES } from '../calendar/util/occupied-slot-statuses.util';
import { DataSource } from 'typeorm';
import { UserEntity } from '../database/entity/user.entity';
import { ScheduleSlotEntity } from '../database/entity/schedule-slot.entity';
import { BookingRequestRepository } from '../database/repository/booking-request.repository';
import { ScheduleSlotRepository } from '../database/repository/schedule-slot.repository';
import { CoachFinanceSettingsRepository } from '../database/repository/coach-finance-settings.repository';
import type { Money } from '../billing/interface';
import type { CreateSlotParams } from './interface/create-slot.params';
import type { FindSlotsForCoachParams } from './interface/find-slots-for-coach.params';
import type { ListSlotsQuery } from './interface/list-slots.params';
import type { ScheduleSlotModel } from './interface/schedule-slot.model';
import type {
  DeleteSlotReturns,
  ScheduleSlotReturns,
} from './interface/schedule-slot.returns';
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

@Injectable()
export class SchedulesService {
  constructor(
    private readonly slots: ScheduleSlotRepository,
    private readonly financeSettings: CoachFinanceSettingsRepository,
    private readonly bookingRequests: BookingRequestRepository,
    private readonly dataSource: DataSource,
    private readonly bookingRequestLifecycle: BookingRequestsService,
  ) {}

  /**
   *
   */
  async createSlot(params: CreateSlotParams): Promise<ScheduleSlotReturns> {
    const startsAt = new Date(params.startsAt);
    const endsAt = new Date(params.endsAt);
    this.assertValidRange(startsAt, endsAt);

    const slot = await this.dataSource.transaction(async manager => {
      await manager.findOneOrFail(UserEntity, {
        where: { id: params.coachId },
        lock: { mode: 'pessimistic_write' },
      });
      const overlap = await manager
        .createQueryBuilder(ScheduleSlotEntity, 'slot')
        .where('slot.coach_id = :coachId', { coachId: params.coachId })
        .andWhere('slot.status IN (:...statuses)', {
          statuses: OCCUPIED_SLOT_STATUSES,
        })
        .andWhere('slot.starts_at < :endsAt AND slot.ends_at > :startsAt', {
          startsAt,
          endsAt,
        })
        .getExists();
      if (overlap) {
        throw new ConflictException(
          'Open slot overlaps an existing open, booked, or blocked slot',
        );
      }

      return manager.save(
        manager.create(ScheduleSlotEntity, {
          coachId: params.coachId,
          startsAt,
          endsAt,
          mode: params.mode ?? 'offline',
          status: 'open',
          seriesId: null,
          gymId: null,
          capacity: 1,
        }),
      );
    });

    return this.toPublic(slot, await this.getPrice(params.coachId), false);
  }

  /**
   *
   */
  async listOwn(
    coachId: string,
    query: ListSlotsQuery,
  ): Promise<ScheduleSlotReturns[]> {
    await this.bookingRequestLifecycle.expireDue(new Date());
    const options: FindSlotsForCoachParams = {};
    if (query.from) {
options.from = new Date(query.from);
}
    if (query.to) {
options.to = new Date(query.to);
}
    const items = (await this.slots.findForCoach(coachId, options)).filter(
      item => item.status !== 'blocked',
    );
    const price = await this.getPrice(coachId);
    const now = new Date();

    return Promise.all(
      items.map(async item =>
        this.toPublic(
          item,
          price,
          await this.bookingRequests.hasActiveHold(item.id, now),
        )),
    );
  }

  /**
   *
   */
  async listOpenForLinkedCoach(
    coachId: string,
    query: ListSlotsQuery,
  ): Promise<ScheduleSlotReturns[]> {
    const now = new Date();
    await this.bookingRequestLifecycle.expireDue(now);
    const cutoff = earliestRequestableSlotStart(now);
    const requestedFrom = query.from ? new Date(query.from) : cutoff;
    const options: FindSlotsForCoachParams = {
      status: 'open',
      from:
        requestedFrom.getTime() > cutoff.getTime() ? requestedFrom : cutoff,
    };
    if (query.to) {
options.to = new Date(query.to);
}
    const items = await this.slots.findRequestableForCoach(coachId, options);
    const price = await this.getPrice(coachId);

    return items.map(item => this.toPublic(item, price, false));
  }

  /**
   *
   */
  async deleteOwnOpen(
    coachId: string,
    slotId: string,
  ): Promise<DeleteSlotReturns> {
    await this.bookingRequestLifecycle.expireDue(new Date());
    const slot = await this.slots.findById(slotId);
    if (!slot || slot.coachId !== coachId) {
      throw new NotFoundException('Slot not found');
    }
    if (slot.status !== 'open') {
      throw new ConflictException('Only open slots can be deleted');
    }
    if (await this.bookingRequests.hasActiveHold(slot.id, new Date())) {
      throw new ConflictException('Held slot cannot be deleted');
    }
    if (await this.bookingRequests.hasAnyForSlot(slot.id)) {
      slot.status = 'blocked';
      await this.slots.save(slot);

      return { success: true };
    }
    await this.slots.remove(slot);

    return { success: true };
  }

  /**
   *
   */
  private assertValidRange(startsAt: Date, endsAt: Date): void {
    if (Number.isNaN(startsAt.getTime()) || Number.isNaN(endsAt.getTime())) {
      throw new BadRequestException('Invalid datetime');
    }
    if (endsAt.getTime() <= startsAt.getTime()) {
      throw new BadRequestException('endsAt must be after startsAt');
    }
  }

  /**
   *
   */
  private async getPrice(coachId: string): Promise<Money | null> {
    const settings = await this.financeSettings.findByCoachId(coachId);

    return settings? {
          amountMinor: settings.defaultSessionPriceMinor,
          currency: settings.currency,
        }: null;
  }

  /**
   *
   */
  private toPublic(
    slot: ScheduleSlotModel,
    price: Money | null,
    held: boolean,
  ): ScheduleSlotReturns {
    return {
      id: slot.id,
      coachId: slot.coachId,
      startsAt: slot.startsAt.toISOString(),
      endsAt: slot.endsAt.toISOString(),
      mode: slot.mode,
      status: slot.status,
      capacity: slot.capacity,
      seriesId: slot.seriesId,
      gymId: slot.gymId,
      createdAt: slot.createdAt.toISOString(),
      price,
      held,
    };
  }
}
