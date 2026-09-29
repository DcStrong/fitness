import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { ScheduleSeriesKind } from '../../schedules/interface/availability.types';
import { ScheduleSeriesEntity } from '../entity/schedule-series.entity';

@Injectable()
export class ScheduleSeriesRepository {
  constructor(
    @InjectRepository(ScheduleSeriesEntity)
    private readonly series: Repository<ScheduleSeriesEntity>,
  ) {}

  /**
   *
   */
  async findWeeklyByCoachId(
    coachId: string,
  ): Promise<ScheduleSeriesEntity | null> {
    return this.series.findOne({
      where: {
        coachId,
        kind: 'weekly_availability' satisfies ScheduleSeriesKind,
      },
    });
  }

  /**
   *
   */
  create(data: Partial<ScheduleSeriesEntity>): ScheduleSeriesEntity {
    return this.series.create(data);
  }

  /**
   *
   */
  async save(entity: ScheduleSeriesEntity): Promise<ScheduleSeriesEntity> {
    return this.series.save(entity);
  }
}
