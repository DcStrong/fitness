import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PlanSetEntity } from '../entity/plan-set.entity';

@Injectable()
export class PlanSetRepository {
  constructor(
    @InjectRepository(PlanSetEntity)
    private readonly planSets: Repository<PlanSetEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<PlanSetEntity>): PlanSetEntity {
    return this.planSets.create(data);
  }

  /**
   *
   */
  async save(entity: PlanSetEntity): Promise<PlanSetEntity> {
    return this.planSets.save(entity);
  }
}
