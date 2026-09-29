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
import type { BillingCurrency, MoneyMinor } from '../../billing/interface';
import type {
  BookingRequestRejectionReason,
  BookingRequestResolution,
  BookingRequestStatus,
} from '../../booking-requests/interface';
import { ScheduleSlotEntity } from './schedule-slot.entity';
import { SessionEntity } from './session.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'booking_requests' })
@Index('IDX_booking_requests_coach_status_expiry', [
  'coachId',
  'status',
  'expiresAt',
])
export class BookingRequestEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Column({ name: 'student_id', type: 'uuid' })
  studentId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'student_id' })
  student!: UserEntity;

  @Column({ name: 'schedule_slot_id', type: 'uuid' })
  scheduleSlotId!: string;

  @ManyToOne(() => ScheduleSlotEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'schedule_slot_id' })
  scheduleSlot!: ScheduleSlotEntity;

  @Column({ type: 'varchar', length: 16 })
  status!: BookingRequestStatus;

  @Column({ name: 'quoted_price_minor', type: 'bigint' })
  quotedPriceMinor!: MoneyMinor;

  @Column({ name: 'quoted_currency', type: 'char', length: 3 })
  quotedCurrency!: BillingCurrency;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt!: Date;

  @Column({ name: 'resolved_by', type: 'uuid', nullable: true })
  resolvedBy!: string | null;

  @ManyToOne(() => UserEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'resolved_by' })
  resolver!: UserEntity | null;

  @Column({ name: 'resolved_at', type: 'timestamptz', nullable: true })
  resolvedAt!: Date | null;

  @Column({ name: 'rejection_reason', type: 'varchar', length: 32, nullable: true })
  rejectionReason!: BookingRequestRejectionReason | null;

  @Column({ name: 'rejection_comment', type: 'varchar', length: 500, nullable: true })
  rejectionComment!: string | null;

  @Column({ type: 'varchar', length: 24, nullable: true })
  resolution!: BookingRequestResolution | null;

  @Column({ name: 'resolved_schedule_slot_id', type: 'uuid', nullable: true })
  resolvedScheduleSlotId!: string | null;

  @ManyToOne(() => ScheduleSlotEntity, { onDelete: 'RESTRICT', nullable: true })
  @JoinColumn({ name: 'resolved_schedule_slot_id' })
  resolvedScheduleSlot!: ScheduleSlotEntity | null;

  @Column({ name: 'session_id', type: 'uuid', nullable: true, unique: true })
  sessionId!: string | null;

  @OneToOne(() => SessionEntity, { onDelete: 'RESTRICT', nullable: true })
  @JoinColumn({ name: 'session_id' })
  session!: SessionEntity | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
