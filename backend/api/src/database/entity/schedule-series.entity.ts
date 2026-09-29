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
import type { ScheduleSeriesKind } from '../../schedules/interface/availability.types';
import { UserEntity } from './user.entity';

@Entity({ name: 'schedule_series' })
@Index('UQ_schedule_series_coach_weekly', ['coachId', 'kind'], { unique: true })
export class ScheduleSeriesEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Column({ type: 'varchar', length: 32, default: 'weekly_availability' })
  kind!: ScheduleSeriesKind;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
