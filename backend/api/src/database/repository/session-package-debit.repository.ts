import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SessionPackageDebitEntity } from '../entity/session-package-debit.entity';

@Injectable()
export class SessionPackageDebitRepository {
  constructor(
    @InjectRepository(SessionPackageDebitEntity)
    private readonly debits: Repository<SessionPackageDebitEntity>,
  ) {}

  create(data: Partial<SessionPackageDebitEntity>): SessionPackageDebitEntity {
    return this.debits.create(data);
  }

  async save(
    entity: SessionPackageDebitEntity,
  ): Promise<SessionPackageDebitEntity> {
    return this.debits.save(entity);
  }

  async findByPackageAndSession(
    packageId: string,
    sessionId: string,
  ): Promise<SessionPackageDebitEntity | null> {
    return this.debits.findOne({ where: { packageId, sessionId } });
  }
}
