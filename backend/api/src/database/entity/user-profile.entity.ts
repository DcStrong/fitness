import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import type {
  PreferredContactChannel,
  TrainingMode,
} from '../../social/interface';
import { UserEntity } from './user.entity';

@Entity({ name: 'user_profiles' })
export class UserProfileEntity {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @OneToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;

  @Column({ name: 'display_name', type: 'varchar', length: 80, nullable: true })
  displayName!: string | null;

  @Column({ name: 'avatar_url', type: 'varchar', length: 2048, nullable: true })
  avatarUrl!: string | null;

  @Column({ type: 'varchar', length: 1000, nullable: true })
  bio!: string | null;

  @Column({ type: 'varchar', length: 120, nullable: true })
  city!: string | null;

  @Column({ type: 'varchar', array: true, default: '{}' })
  specialties!: string[];

  @Column({ name: 'training_modes', type: 'varchar', array: true, default: '{}' })
  trainingModes!: TrainingMode[];

  @Column({ name: 'is_discoverable', type: 'boolean', default: false })
  isDiscoverable!: boolean;

  @Column({ name: 'show_rating', type: 'boolean', default: true })
  showRating!: boolean;

  @Column({ name: 'show_reviews', type: 'boolean', default: true })
  showReviews!: boolean;

  @Column({ name: 'show_reviewer_name', type: 'boolean', default: false })
  showReviewerName!: boolean;

  @Column({ type: 'varchar', length: 20, nullable: true })
  phone!: string | null;

  @Column({
    name: 'telegram_username',
    type: 'varchar',
    length: 32,
    nullable: true,
  })
  telegramUsername!: string | null;

  @Column({
    name: 'preferred_contact_channels',
    type: 'varchar',
    array: true,
    default: '{}',
  })
  preferredContactChannels!: PreferredContactChannel[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
