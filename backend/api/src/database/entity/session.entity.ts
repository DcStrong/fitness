import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type {
  SessionCreatedBy,
  SessionMode,
  SessionStatus,
} from '../../sessions/interface/session.types';
import { SessionChargeEntity } from './session-charge.entity';
import { ScheduleSlotEntity } from './schedule-slot.entity';
import { TrainingPlanEntity } from './training-plan.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'sessions' })
export class SessionEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_sessions_coach_starts')
  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Index('IDX_sessions_student_id')
  @Column({ name: 'student_id', type: 'uuid' })
  studentId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'student_id' })
  student!: UserEntity;

  @Column({ name: 'schedule_slot_id', type: 'uuid', unique: true, nullable: true })
  scheduleSlotId!: string | null;

  @ManyToOne(() => ScheduleSlotEntity, { onDelete: 'RESTRICT', nullable: true })
  @JoinColumn({ name: 'schedule_slot_id' })
  scheduleSlot!: ScheduleSlotEntity | null;

  @OneToOne(() => SessionChargeEntity, charge => charge.session)
  charge?: SessionChargeEntity | null;

  /** Snapshot from slot at booking time */
  @Column({ name: 'starts_at', type: 'timestamptz' })
  startsAt!: Date;

  @Column({ name: 'ends_at', type: 'timestamptz' })
  endsAt!: Date;

  @Column({ type: 'varchar', length: 16, default: 'offline' })
  mode!: SessionMode;

  @Column({ type: 'varchar', length: 16, default: 'booked' })
  status!: SessionStatus;

  @Column({ name: 'created_by', type: 'varchar', length: 16 })
  createdBy!: SessionCreatedBy;

  @Index('IDX_sessions_student_plan_id')
  @Column({ name: 'student_plan_id', type: 'uuid', nullable: true })
  studentPlanId!: string | null;

  @ManyToOne(() => TrainingPlanEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'student_plan_id' })
  studentPlan!: TrainingPlanEntity | null;

  @Index('IDX_sessions_recurring_booking')
  @Column({ name: 'recurring_booking_id', type: 'uuid', nullable: true })
  recurringBookingId!: string | null;

  @Column({ name: 'recurring_local_date', type: 'date', nullable: true })
  recurringLocalDate!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
