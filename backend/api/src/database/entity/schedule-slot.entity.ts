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
  ScheduleSlotMode,
  ScheduleSlotStatus,
} from '../../schedules/interface/schedule-slot.types';
import { UserEntity } from './user.entity';

@Entity({ name: 'schedule_slots' })
export class ScheduleSlotEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_schedule_slots_coach_starts')
  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Column({ name: 'starts_at', type: 'timestamptz' })
  startsAt!: Date;

  @Column({ name: 'ends_at', type: 'timestamptz' })
  endsAt!: Date;

  @Column({ type: 'varchar', length: 16, default: 'offline' })
  mode!: ScheduleSlotMode;

  @Column({ type: 'varchar', length: 16, default: 'open' })
  status!: ScheduleSlotStatus;

  /** Future: ScheduleSeries */
  @Column({ name: 'series_id', type: 'uuid', nullable: true })
  seriesId!: string | null;

  /** Future: Gym */
  @Column({ name: 'gym_id', type: 'uuid', nullable: true })
  gymId!: string | null;

  @Column({ type: 'int', default: 1 })
  capacity!: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
