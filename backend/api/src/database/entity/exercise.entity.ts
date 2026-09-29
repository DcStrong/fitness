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
import type { ExerciseKind } from '../../exercises/interface';
import { UserEntity } from './user.entity';

@Entity({ name: 'exercises' })
export class ExerciseEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 120 })
  name!: string;

  @Column({ type: 'varchar', length: 32 })
  kind!: ExerciseKind;

  @Index('IDX_exercises_owner_coach_id')
  @Column({ name: 'owner_coach_id', type: 'uuid', nullable: true })
  ownerCoachId!: string | null;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'owner_coach_id' })
  ownerCoach!: UserEntity | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
