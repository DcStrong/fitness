import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type { SessionStatus } from '../../sessions/interface/session.types';
import { SessionEntity } from './session.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'session_history_events' })
export class SessionHistoryEventEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_session_history_session_created')
  @Column({ name: 'session_id', type: 'uuid' })
  sessionId!: string;

  @ManyToOne(() => SessionEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'session_id' })
  session!: SessionEntity;

  @Column({ name: 'actor_user_id', type: 'uuid' })
  actorUserId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'actor_user_id' })
  actor!: UserEntity;

  @Column({ name: 'from_status', type: 'varchar', length: 16 })
  fromStatus!: SessionStatus;

  @Column({ name: 'to_status', type: 'varchar', length: 16 })
  toStatus!: SessionStatus;

  @Column({ type: 'varchar', length: 500, nullable: true })
  note!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
