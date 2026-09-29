import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type { BookingRequestEventType } from '../../booking-requests/interface';
import { BookingRequestEntity } from './booking-request.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'booking_request_events' })
export class BookingRequestEventEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'booking_request_id', type: 'uuid' })
  bookingRequestId!: string;

  @ManyToOne(() => BookingRequestEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'booking_request_id' })
  bookingRequest!: BookingRequestEntity;

  @Column({ name: 'event_type', type: 'varchar', length: 16 })
  eventType!: BookingRequestEventType;

  @Column({ name: 'actor_id', type: 'uuid', nullable: true })
  actorId!: string | null;

  @ManyToOne(() => UserEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'actor_id' })
  actor!: UserEntity | null;

  @Column({ type: 'jsonb', default: {} })
  metadata!: Record<string, unknown>;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
