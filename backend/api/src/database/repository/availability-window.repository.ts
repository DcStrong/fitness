import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import type { AvailabilityWindowModel } from '../../schedules/interface/availability.types';
import { AvailabilityWindowEntity } from '../entity/availability-window.entity';

@Injectable()
export class AvailabilityWindowRepository {
  constructor(
    @InjectRepository(AvailabilityWindowEntity)
    private readonly windows: Repository<AvailabilityWindowEntity>,
  ) {}

  /**
   *
   */
  async findBySeriesId(seriesId: string): Promise<AvailabilityWindowEntity[]> {
    return this.windows.find({
      where: { seriesId },
      order: { dayOfWeek: 'ASC', startMinute: 'ASC' },
    });
  }

  /**
   *
   */
  async replaceForSeries(
    seriesId: string,
    windows: AvailabilityWindowModel[],
  ): Promise<AvailabilityWindowEntity[]> {
    await this.windows.delete({ seriesId });
    if (windows.length === 0) {
      return [];
    }
    const entities = windows.map(window =>
      this.windows.create({
        seriesId,
        dayOfWeek: window.dayOfWeek,
        startMinute: window.startMinute,
        endMinute: window.endMinute,
        mode: window.mode,
      }));

    return this.windows.save(entities);
  }

  /**
   *
   */
  async deleteBySeriesIds(seriesIds: string[]): Promise<void> {
    if (seriesIds.length === 0) {
      return;
    }
    await this.windows.delete({ seriesId: In(seriesIds) });
  }
}
