import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SessionHistoryEventEntity } from '../entity/session-history-event.entity';

@Injectable()
export class SessionHistoryEventRepository {
  constructor(
    @InjectRepository(SessionHistoryEventEntity)
    private readonly events: Repository<SessionHistoryEventEntity>,
  ) {}

  /**
   *
   */
  create(
    data: Partial<SessionHistoryEventEntity>,
  ): SessionHistoryEventEntity {
    return this.events.create(data);
  }

  /**
   *
   */
  async save(
    entity: SessionHistoryEventEntity,
  ): Promise<SessionHistoryEventEntity> {
    return this.events.save(entity);
  }

  /**
   *
   */
  async findBySessionId(sessionId: string): Promise<SessionHistoryEventEntity[]> {
    return this.events.find({
      where: { sessionId },
      relations: { actor: true },
      order: { createdAt: 'ASC' },
    });
  }
}
