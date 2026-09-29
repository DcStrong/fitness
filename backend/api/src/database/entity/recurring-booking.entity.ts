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
import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';
import type {
  RecurringBookingStatus,
  WeekdayNumber,
} from '../../recurring-bookings/interface/recurring-booking.types';
import { UserEntity } from './user.entity';

@Entity({ name: 'recurring_bookings' })
export class RecurringBookingEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_recurring_bookings_coach')
  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Index('IDX_recurring_bookings_student')
  @Column({ name: 'student_id', type: 'uuid' })
  studentId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'student_id' })
  student!: UserEntity;

  @Column({ name: 'weekdays', type: 'smallint', array: true })
  weekdays!: WeekdayNumber[];

  @Column({ name: 'start_minute', type: 'int' })
  startMinute!: number;

  @Column({ type: 'varchar', length: 16 })
  mode!: ScheduleSlotMode;

  @Column({ type: 'varchar', length: 64 })
  timezone!: string;

  @Column({ type: 'varchar', length: 16, default: 'active' })
  status!: RecurringBookingStatus;

  @Column({ name: 'horizon_weeks_override', type: 'int', nullable: true })
  horizonWeeksOverride!: number | null;

  @Column({ name: 'cancelled_at', type: 'timestamptz', nullable: true })
  cancelledAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
