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
import type { RecurringOverrideType } from '../../recurring-bookings/interface/recurring-booking.types';
import { RecurringBookingEntity } from './recurring-booking.entity';

@Entity({ name: 'recurring_booking_overrides' })
@Index('UQ_recurring_override_booking_date', ['recurringBookingId', 'localDate'], {
  unique: true,
})
export class RecurringBookingOverrideEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'recurring_booking_id', type: 'uuid' })
  recurringBookingId!: string;

  @ManyToOne(() => RecurringBookingEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'recurring_booking_id' })
  recurringBooking!: RecurringBookingEntity;

  @Column({ name: 'local_date', type: 'date' })
  localDate!: string;

  @Column({ type: 'varchar', length: 16 })
  type!: RecurringOverrideType;

  @Column({ name: 'new_start_minute', type: 'int', nullable: true })
  newStartMinute!: number | null;

  @Column({ name: 'new_local_date', type: 'date', nullable: true })
  newLocalDate!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
