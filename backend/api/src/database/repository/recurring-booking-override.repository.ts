import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { RecurringBookingOverrideEntity } from '../entity/recurring-booking-override.entity';

@Injectable()
export class RecurringBookingOverrideRepository {
  constructor(
    @InjectRepository(RecurringBookingOverrideEntity)
    private readonly overrides: Repository<RecurringBookingOverrideEntity>,
  ) {}

  create(
    data: Partial<RecurringBookingOverrideEntity>,
  ): RecurringBookingOverrideEntity {
    return this.overrides.create(data);
  }

  async save(
    entity: RecurringBookingOverrideEntity,
  ): Promise<RecurringBookingOverrideEntity> {
    return this.overrides.save(entity);
  }

  async findByBookingId(
    recurringBookingId: string,
  ): Promise<RecurringBookingOverrideEntity[]> {
    return this.overrides.find({ where: { recurringBookingId } });
  }

  async findByBookingIds(
    recurringBookingIds: string[],
  ): Promise<RecurringBookingOverrideEntity[]> {
    if (!recurringBookingIds.length) {
      return [];
    }
    return this.overrides.find({
      where: { recurringBookingId: In(recurringBookingIds) },
    });
  }

  async findByBookingAndDate(
    recurringBookingId: string,
    localDate: string,
  ): Promise<RecurringBookingOverrideEntity | null> {
    return this.overrides.findOne({
      where: { recurringBookingId, localDate },
    });
  }

  async deleteByBookingId(recurringBookingId: string): Promise<void> {
    await this.overrides.delete({ recurringBookingId });
  }
}
