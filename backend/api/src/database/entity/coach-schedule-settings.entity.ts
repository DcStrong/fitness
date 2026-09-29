import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';
import { UserEntity } from './user.entity';

@Entity({ name: 'coach_schedule_settings' })
export class CoachScheduleSettingsEntity {
  @PrimaryColumn({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @OneToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Column({ type: 'varchar', length: 64, default: 'Europe/Moscow' })
  timezone!: string;

  @Column({ name: 'default_duration_minutes', type: 'int', default: 60 })
  defaultDurationMinutes!: number;

  @Column({ name: 'break_minutes', type: 'int', default: 0 })
  breakMinutes!: number;

  @Column({ name: 'horizon_weeks', type: 'int', default: 8 })
  horizonWeeks!: number;

  @Column({
    name: 'online_duration_minutes',
    type: 'int',
    nullable: true,
  })
  onlineDurationMinutes!: number | null;

  @Column({
    name: 'offline_duration_minutes',
    type: 'int',
    nullable: true,
  })
  offlineDurationMinutes!: number | null;

  @Column({ name: 'default_mode', type: 'varchar', length: 16, default: 'offline' })
  defaultMode!: ScheduleSlotMode;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
