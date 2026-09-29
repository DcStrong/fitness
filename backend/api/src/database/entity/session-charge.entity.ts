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
  BillingCurrency,
  MoneyMinor,
  PaymentMethod,
  SessionChargeStatus,
} from '../../billing/interface/billing.types';
import { SessionEntity } from './session.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'session_charges' })
@Index('IDX_session_charges_coach_status_earned', [
  'coachId',
  'status',
  'earnedAt',
])
export class SessionChargeEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'session_id', type: 'uuid', unique: true })
  sessionId!: string;

  @OneToOne(() => SessionEntity, session => session.charge, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'session_id' })
  session!: SessionEntity;

  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Index('IDX_session_charges_student_id')
  @Column({ name: 'student_id', type: 'uuid' })
  studentId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'student_id' })
  student!: UserEntity;

  @Column({ name: 'amount_minor', type: 'bigint' })
  amountMinor!: MoneyMinor;

  @Column({ type: 'char', length: 3 })
  currency!: BillingCurrency;

  @Column({ type: 'varchar', length: 16, default: 'pending' })
  status!: SessionChargeStatus;

  @Column({ name: 'earned_at', type: 'timestamptz', nullable: true })
  earnedAt!: Date | null;

  @Column({ name: 'paid_at', type: 'timestamptz', nullable: true })
  paidAt!: Date | null;

  @Column({
    name: 'payment_method',
    type: 'varchar',
    length: 16,
    nullable: true,
  })
  paymentMethod!: PaymentMethod | null;

  @Column({ name: 'cancelled_at', type: 'timestamptz', nullable: true })
  cancelledAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
