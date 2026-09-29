import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RecurringBookingEntity } from '../entity/recurring-booking.entity';
import type {
  RecurringBookingStatus,
  WeekdayNumber,
} from '../../recurring-bookings/interface/recurring-booking.types';
import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';

export interface RecurringBookingPatternParams {
  coachId: string;
  studentId: string;
  weekdays: WeekdayNumber[];
  startMinute: number;
  mode: ScheduleSlotMode;
  status: RecurringBookingStatus;
}

@Injectable()
export class RecurringBookingRepository {
  constructor(
    @InjectRepository(RecurringBookingEntity)
    private readonly bookings: Repository<RecurringBookingEntity>,
  ) {}

  create(data: Partial<RecurringBookingEntity>): RecurringBookingEntity {
    return this.bookings.create(data);
  }

  async save(
    entity: RecurringBookingEntity,
  ): Promise<RecurringBookingEntity> {
    return this.bookings.save(entity);
  }

  async findById(id: string): Promise<RecurringBookingEntity | null> {
    return this.bookings.findOne({ where: { id } });
  }

  async findByCoachId(coachId: string): Promise<RecurringBookingEntity[]> {
    return this.bookings.find({
      where: { coachId },
      order: { createdAt: 'DESC' },
    });
  }

  async findByCoachIdAndStatus(
    coachId: string,
    status: RecurringBookingStatus,
  ): Promise<RecurringBookingEntity[]> {
    return this.bookings.find({
      where: { coachId, status },
      order: { createdAt: 'DESC' },
    });
  }

  async findByIdForCoach(
    id: string,
    coachId: string,
  ): Promise<RecurringBookingEntity | null> {
    return this.bookings.findOne({ where: { id, coachId } });
  }

  async findActiveByCoach(
    coachId: string,
  ): Promise<RecurringBookingEntity[]> {
    return this.bookings.find({
      where: {
        coachId,
        status: 'active' satisfies RecurringBookingStatus,
      },
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Matches coach/student/startMinute/mode/status, then filters equal sorted weekdays in memory
   * (Postgres array equality via TypeORM is brittle across drivers).
   */
  async findByPattern(
    params: RecurringBookingPatternParams,
  ): Promise<RecurringBookingEntity[]> {
    const weekdaysKey = [...params.weekdays].sort((a, b) => a - b).join(',');
    const rows = await this.bookings.find({
      where: {
        coachId: params.coachId,
        studentId: params.studentId,
        startMinute: params.startMinute,
        mode: params.mode,
        status: params.status,
      },
      order: { createdAt: 'DESC' },
    });
    return rows.filter(
      row =>
        [...row.weekdays].sort((a, b) => a - b).join(',') === weekdaysKey,
    );
  }

  async remove(entity: RecurringBookingEntity): Promise<void> {
    await this.bookings.remove(entity);
  }
}
