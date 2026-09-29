import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { UpsertScheduleSettingsParams } from '../../schedules/interface/upsert-schedule-settings.params';
import { CoachScheduleSettingsEntity } from '../entity/coach-schedule-settings.entity';

@Injectable()
export class CoachScheduleSettingsRepository {
  constructor(
    @InjectRepository(CoachScheduleSettingsEntity)
    private readonly settings: Repository<CoachScheduleSettingsEntity>,
  ) {}

  /**
   *
   */
  async findByCoachId(
    coachId: string,
  ): Promise<CoachScheduleSettingsEntity | null> {
    return this.settings.findOne({ where: { coachId } });
  }

  /**
   *
   */
  async save(
    params: UpsertScheduleSettingsParams,
  ): Promise<CoachScheduleSettingsEntity> {
    const entity = this.settings.create(params);

    return this.settings.save(entity);
  }
}
