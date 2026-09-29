import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { FindSlotsForCoachParams } from '../../schedules/interface/find-slots-for-coach.params';
import type { ScheduleSlotStatus } from '../../schedules/interface/schedule-slot.types';
import { ScheduleSlotEntity } from '../entity/schedule-slot.entity';

/** Half-open interval overlap: [aStart, aEnd) overlaps [bStart, bEnd) */
export function rangesOverlap(
  aStart: Date,
  aEnd: Date,
  bStart: Date,
  bEnd: Date,
): boolean {
  return aStart.getTime() < bEnd.getTime() && aEnd.getTime() > bStart.getTime();
}

@Injectable()
export class ScheduleSlotRepository {
  constructor(
    @InjectRepository(ScheduleSlotEntity)
    private readonly slots: Repository<ScheduleSlotEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<ScheduleSlotEntity>): ScheduleSlotEntity {
    return this.slots.create(data);
  }

  /**
   *
   */
  async save(entity: ScheduleSlotEntity): Promise<ScheduleSlotEntity> {
    return this.slots.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<ScheduleSlotEntity | null> {
    return this.slots.findOne({ where: { id } });
  }

  /**
   *
   */
  async findOpenOverlapping(
    coachId: string,
    startsAt: Date,
    endsAt: Date,
    excludeId?: string,
  ): Promise<ScheduleSlotEntity[]> {
    const qb = this.slots
      .createQueryBuilder('slot')
      .where('slot.coach_id = :coachId', { coachId })
      .andWhere('slot.status = :status', {
        status: 'open' satisfies ScheduleSlotStatus,
      })
      .andWhere('slot.starts_at < :endsAt AND slot.ends_at > :startsAt', {
        startsAt,
        endsAt,
      });

    if (excludeId) {
      qb.andWhere('slot.id != :excludeId', { excludeId });
    }

    return qb.getMany();
  }

  /**
   *
   */
  async findForCoach(
    coachId: string,
    options: FindSlotsForCoachParams = {},
  ): Promise<ScheduleSlotEntity[]> {
    const qb = this.slots
      .createQueryBuilder('slot')
      .where('slot.coach_id = :coachId', { coachId })
      .orderBy('slot.starts_at', 'ASC');

    if (options.status) {
      qb.andWhere('slot.status = :status', { status: options.status });
    }
    if (options.from) {
      qb.andWhere('slot.ends_at > :from', { from: options.from });
    }
    if (options.to) {
      qb.andWhere('slot.starts_at < :to', { to: options.to });
    }

    return qb.getMany();
  }

  async findExactForCoach(params: {
    coachId: string;
    startsAt: Date;
    endsAt: Date;
  }): Promise<ScheduleSlotEntity | null> {
    return this.slots.findOne({
      where: {
        coachId: params.coachId,
        startsAt: params.startsAt,
        endsAt: params.endsAt,
      },
    });
  }

  async findOverlappingAnyStatus(
    coachId: string,
    startsAt: Date,
    endsAt: Date,
  ): Promise<ScheduleSlotEntity[]> {
    return this.slots
      .createQueryBuilder('slot')
      .where('slot.coach_id = :coachId', { coachId })
      .andWhere('slot.starts_at < :endsAt AND slot.ends_at > :startsAt', {
        startsAt,
        endsAt,
      })
      .getMany();
  }

  /**
   *
   */
  async findRequestableForCoach(
    coachId: string,
    options: FindSlotsForCoachParams = {},
    now = new Date(),
  ): Promise<ScheduleSlotEntity[]> {
    const qb = this.slots
      .createQueryBuilder('slot')
      .where('slot.coach_id = :coachId', { coachId })
      .andWhere('slot.status = \'open\'')
      .andWhere(
        `NOT EXISTS (
          SELECT 1 FROM booking_requests request
          WHERE request.schedule_slot_id = slot.id
            AND request.status = 'pending'
            AND request.expires_at > :now
        )`,
        { now },
      )
      .orderBy('slot.starts_at', 'ASC');
    if (options.from) {
      qb.andWhere('slot.starts_at > :from', { from: options.from });
    }
    if (options.to) {
      qb.andWhere('slot.starts_at < :to', { to: options.to });
    }

    return qb.getMany();
  }

  /**
   *
   */
  async remove(entity: ScheduleSlotEntity): Promise<ScheduleSlotEntity> {
    return this.slots.remove(entity);
  }
}
