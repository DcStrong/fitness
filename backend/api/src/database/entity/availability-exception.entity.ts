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
import type {
  AvailabilityExceptionType,
  AvailabilityExceptionWindowModel,
} from '../../schedules/interface/availability.types';
import { ScheduleSeriesEntity } from './schedule-series.entity';

@Entity({ name: 'availability_exceptions' })
@Index('UQ_availability_exceptions_series_date', ['seriesId', 'localDate'], {
  unique: true,
})
export class AvailabilityExceptionEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'series_id', type: 'uuid' })
  seriesId!: string;

  @ManyToOne(() => ScheduleSeriesEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'series_id' })
  series!: ScheduleSeriesEntity;

  /** Local calendar date YYYY-MM-DD in coach timezone */
  @Column({ name: 'local_date', type: 'date' })
  localDate!: string;

  @Column({ type: 'varchar', length: 16 })
  type!: AvailabilityExceptionType;

  /** Required when type = custom_hours; null when closed */
  @Column({ type: 'jsonb', nullable: true })
  windows!: AvailabilityExceptionWindowModel[] | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
