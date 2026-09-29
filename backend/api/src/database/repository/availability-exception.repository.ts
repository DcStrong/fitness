import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type {
  AvailabilityExceptionType,
  AvailabilityExceptionWindowModel,
} from '../../schedules/interface/availability.types';
import { AvailabilityExceptionEntity } from '../entity/availability-exception.entity';

export interface SaveExceptionRow {
  localDate: string;
  type: AvailabilityExceptionType;
  windows: AvailabilityExceptionWindowModel[] | null;
}

@Injectable()
export class AvailabilityExceptionRepository {
  constructor(
    @InjectRepository(AvailabilityExceptionEntity)
    private readonly exceptions: Repository<AvailabilityExceptionEntity>,
  ) {}

  /**
   *
   */
  async findBySeriesId(
    seriesId: string,
  ): Promise<AvailabilityExceptionEntity[]> {
    return this.exceptions.find({
      where: { seriesId },
      order: { localDate: 'ASC' },
    });
  }

  /**
   *
   */
  async replaceForSeries(
    seriesId: string,
    rows: SaveExceptionRow[],
  ): Promise<AvailabilityExceptionEntity[]> {
    await this.exceptions.delete({ seriesId });
    if (rows.length === 0) {
      return [];
    }
    const entities = rows.map(row =>
      this.exceptions.create({
        seriesId,
        localDate: row.localDate,
        type: row.type,
        windows: row.windows,
      }));

    return this.exceptions.save(entities);
  }
}
