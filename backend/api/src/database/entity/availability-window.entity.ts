import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { WeekdayNumber } from '../../schedules/interface/availability.types';
import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';
import { ScheduleSeriesEntity } from './schedule-series.entity';

@Entity({ name: 'availability_windows' })
@Index('IDX_availability_windows_series_dow', ['seriesId', 'dayOfWeek'])
export class AvailabilityWindowEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'series_id', type: 'uuid' })
  seriesId!: string;

  @ManyToOne(() => ScheduleSeriesEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'series_id' })
  series!: ScheduleSeriesEntity;

  /** 1 = Monday … 7 = Sunday */
  @Column({ name: 'day_of_week', type: 'smallint' })
  dayOfWeek!: WeekdayNumber;

  @Column({ name: 'start_minute', type: 'int' })
  startMinute!: number;

  @Column({ name: 'end_minute', type: 'int' })
  endMinute!: number;

  @Column({ type: 'varchar', length: 16, nullable: true })
  mode!: ScheduleSlotMode | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
