import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { TagEntity } from './tag.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'user_tags' })
@Unique('UQ_user_tags_pair', ['userId', 'tagId'])
export class UserTagEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_user_tags_user_id')
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;

  @Index('IDX_user_tags_tag_id')
  @Column({ name: 'tag_id', type: 'uuid' })
  tagId!: string;

  @ManyToOne(() => TagEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tag_id' })
  tag!: TagEntity;

  @Column({ name: 'assigned_by', type: 'uuid' })
  assignedBy!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'assigned_by' })
  assigner!: UserEntity;

  @CreateDateColumn({ name: 'assigned_at', type: 'timestamptz' })
  assignedAt!: Date;
}
