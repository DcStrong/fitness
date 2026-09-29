import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BookingRequestEventEntity } from '../entity/booking-request-event.entity';

@Injectable()
export class BookingRequestEventRepository {
  constructor(
    @InjectRepository(BookingRequestEventEntity)
    private readonly events: Repository<BookingRequestEventEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<BookingRequestEventEntity>): BookingRequestEventEntity {
    return this.events.create(data);
  }

  /**
   *
   */
  async save(entity: BookingRequestEventEntity): Promise<BookingRequestEventEntity> {
    return this.events.save(entity);
  }
}
