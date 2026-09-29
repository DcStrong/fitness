import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { FindSessionsForUserParams } from '../../sessions/interface/list-sessions.params';
import { SessionEntity } from '../entity/session.entity';

@Injectable()
export class SessionRepository {
  constructor(
    @InjectRepository(SessionEntity)
    private readonly sessions: Repository<SessionEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<SessionEntity>): SessionEntity {
    return this.sessions.create(data);
  }

  /**
   *
   */
  async save(entity: SessionEntity): Promise<SessionEntity> {
    return this.sessions.save(entity);
  }

  /**
   *
   */
  async findForUser(
    userId: string,
    options: FindSessionsForUserParams = {},
  ): Promise<SessionEntity[]> {
    const qb = this.sessions
      .createQueryBuilder('session')
      .leftJoinAndSelect('session.coach', 'coach')
      .leftJoinAndSelect('session.student', 'student')
      .leftJoinAndSelect('session.charge', 'charge')
      .leftJoinAndSelect('session.studentPlan', 'studentPlan')
      .where(
        '(session.coach_id = :userId OR session.student_id = :userId)',
        { userId },
      )
      .orderBy('session.starts_at', 'ASC');

    if (options.from) {
      qb.andWhere('session.ends_at > :from', { from: options.from });
    }
    if (options.to) {
      qb.andWhere('session.starts_at < :to', { to: options.to });
    }
    if (options.statuses && options.statuses.length > 0) {
      qb.andWhere('session.status IN (:...statuses)', {
        statuses: options.statuses,
      });
    }
    if (options.studentId) {
      qb.andWhere('session.student_id = :studentId', {
        studentId: options.studentId,
      });
    }

    return qb.getMany();
  }

  /**
   *
   */
  async updateStudentPlanId(
    id: string,
    studentPlanId: string | null,
  ): Promise<void> {
    await this.sessions.update({ id }, { studentPlanId });
  }

  /**
   *
   */
  async findByIdWithPeople(id: string): Promise<SessionEntity | null> {
    return this.sessions.findOne({
      where: { id },
      relations: { coach: true, student: true, charge: true, studentPlan: true },
    });
  }

  /**
   *
   */
  async findById(id: string): Promise<SessionEntity | null> {
    return this.sessions.findOne({ where: { id } });
  }

  async findByRecurringOccurrence(
    recurringBookingId: string,
    recurringLocalDate: string,
  ): Promise<SessionEntity | null> {
    return this.sessions
      .createQueryBuilder('session')
      .where('session.recurring_booking_id = :recurringBookingId', {
        recurringBookingId,
      })
      .andWhere('session.recurring_local_date = :recurringLocalDate', {
        recurringLocalDate,
      })
      .andWhere('session.status != :cancelled', { cancelled: 'cancelled' })
      .getOne();
  }

  async findActiveBookedBySlotId(
    scheduleSlotId: string,
  ): Promise<SessionEntity | null> {
    return this.sessions.findOne({
      where: { scheduleSlotId, status: 'booked' },
    });
  }

  async findFutureBookedByRecurring(
    recurringBookingId: string,
    now: Date,
  ): Promise<SessionEntity[]> {
    return this.sessions
      .createQueryBuilder('session')
      .where('session.recurring_booking_id = :recurringBookingId', {
        recurringBookingId,
      })
      .andWhere('session.status = :status', { status: 'booked' })
      .andWhere('session.starts_at > :now', { now })
      .orderBy('session.starts_at', 'ASC')
      .getMany();
  }

  /**
   *
   */
  async findBookedByRecurringInRange(
    recurringBookingId: string,
    from: Date,
    to: Date,
  ): Promise<SessionEntity[]> {
    return this.sessions
      .createQueryBuilder('session')
      .where('session.recurring_booking_id = :recurringBookingId', {
        recurringBookingId,
      })
      .andWhere('session.status = :status', { status: 'booked' })
      .andWhere('session.starts_at >= :from', { from })
      .andWhere('session.starts_at < :to', { to })
      .orderBy('session.starts_at', 'ASC')
      .getMany();
  }
}
