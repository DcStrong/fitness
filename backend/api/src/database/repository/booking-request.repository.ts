import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, type EntityManager } from 'typeorm';
import type {
  BookingRequestPageParams,
  BookingRequestStatus,
} from '../../booking-requests/interface';
import { BookingRequestEntity } from '../entity/booking-request.entity';

@Injectable()
export class BookingRequestRepository {
  constructor(
    @InjectRepository(BookingRequestEntity)
    private readonly requests: Repository<BookingRequestEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<BookingRequestEntity>): BookingRequestEntity {
    return this.requests.create(data);
  }

  /**
   *
   */
  async save(entity: BookingRequestEntity): Promise<BookingRequestEntity> {
    return this.requests.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<BookingRequestEntity | null> {
    return this.requests.findOne({
      where: { id },
      relations: {
        coach: true,
        student: true,
        scheduleSlot: true,
        resolvedScheduleSlot: true,
      },
    });
  }

  /**
   *
   */
  async findByIdForUpdate(
    manager: EntityManager,
    id: string,
  ): Promise<BookingRequestEntity | null> {
    return manager.findOne(BookingRequestEntity, {
      where: { id },
      lock: { mode: 'pessimistic_write' },
    });
  }

  /**
   *
   */
  async findForStudent(
    studentId: string,
    params: BookingRequestPageParams,
  ): Promise<[BookingRequestEntity[], number]> {
    return this.ownerQuery('student_id', studentId, params, false);
  }

  /**
   *
   */
  async findForCoach(
    coachId: string,
    params: BookingRequestPageParams,
  ): Promise<[BookingRequestEntity[], number]> {
    return this.ownerQuery('coach_id', coachId, params, true);
  }

  /**
   *
   */
  async countPendingForCoach(coachId: string, now: Date): Promise<number> {
    return this.requests
      .createQueryBuilder('request')
      .where('request.coach_id = :coachId', { coachId })
      .andWhere('request.status = :status', {
        status: 'pending' satisfies BookingRequestStatus,
      })
      .andWhere('request.expires_at > :now', { now })
      .getCount();
  }

  /**
   *
   */
  async hasActiveHold(scheduleSlotId: string, now: Date): Promise<boolean> {
    return this.requests
      .createQueryBuilder('request')
      .where('request.schedule_slot_id = :scheduleSlotId', { scheduleSlotId })
      .andWhere('request.status = \'pending\'')
      .andWhere('request.expires_at > :now', { now })
      .getExists();
  }

  async hasAnyForSlot(scheduleSlotId: string): Promise<boolean> {
    return this.requests.exist({ where: { scheduleSlotId } });
  }

  /**
   *
   */
  async expireDue(
    manager: EntityManager,
    now: Date,
  ): Promise<BookingRequestEntity[]> {
    const rows = await manager
      .createQueryBuilder()
      .update(BookingRequestEntity)
      .set({ status: 'expired', resolvedAt: now })
      .where('status = \'pending\'')
      .andWhere('expires_at <= :now', { now })
      .returning('*')
      .execute();

    return rows.raw as BookingRequestEntity[];
  }

  /**
   *
   */
  private async ownerQuery(
    column: 'student_id' | 'coach_id',
    ownerId: string,
    params: BookingRequestPageParams,
    urgentPendingFirst: boolean,
  ): Promise<[BookingRequestEntity[], number]> {
    const qb = this.requests
      .createQueryBuilder('request')
      .leftJoinAndSelect('request.coach', 'coach')
      .leftJoinAndSelect('request.student', 'student')
      .leftJoinAndSelect('request.scheduleSlot', 'scheduleSlot')
      .leftJoinAndSelect('request.resolvedScheduleSlot', 'resolvedScheduleSlot')
      .where(`request.${column} = :ownerId`, { ownerId });
    if (params.status) {
      qb.andWhere('request.status = :status', { status: params.status });
    }
    if (urgentPendingFirst) {
      qb.orderBy('CASE WHEN request.status = \'pending\' THEN 0 ELSE 1 END', 'ASC')
        .addOrderBy(
          'CASE WHEN request.status = \'pending\' THEN request.expires_at END',
          'ASC',
        )
        .addOrderBy('request.created_at', 'DESC');
    } else {
      qb.orderBy('request.created_at', 'DESC');
    }

    const total = await qb.getCount();
    const items = await qb
      .offset((params.page - 1) * params.limit)
      .limit(params.limit)
      .getMany();

    return [items, total];
  }
}
