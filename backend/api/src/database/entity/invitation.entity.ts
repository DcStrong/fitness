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
import type { InvitationStatus } from '../../invitations/interface/invitation.types';
import { UserEntity } from './user.entity';

@Entity({ name: 'invitations' })
export class InvitationEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_invitations_coach_id')
  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Column({ name: 'token_hash', type: 'varchar', unique: true })
  tokenHash!: string;

  @Column({ type: 'varchar', length: 32, default: 'pending' })
  status!: InvitationStatus;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt!: Date;

  @Column({ name: 'accepted_by_user_id', type: 'uuid', nullable: true })
  acceptedByUserId!: string | null;

  @ManyToOne(() => UserEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'accepted_by_user_id' })
  acceptedByUser!: UserEntity | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
