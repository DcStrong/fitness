import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { SaveFinanceSettingsParams } from '../../billing/interface';
import { CoachFinanceSettingsEntity } from '../entity/coach-finance-settings.entity';

@Injectable()
export class CoachFinanceSettingsRepository {
  constructor(
    @InjectRepository(CoachFinanceSettingsEntity)
    private readonly settings: Repository<CoachFinanceSettingsEntity>,
  ) {}

  /**
   *
   */
  async findByCoachId(coachId: string): Promise<CoachFinanceSettingsEntity | null> {
    return this.settings.findOne({ where: { coachId } });
  }

  /**
   *
   */
  async save(
    params: SaveFinanceSettingsParams,
  ): Promise<CoachFinanceSettingsEntity> {
    const entity = this.settings.create(params);

    return this.settings.save(entity);
  }
}
