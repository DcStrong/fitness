import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { ExerciseEntity } from './exercise.entity';
import { SessionEntity } from './session.entity';

@Entity({ name: 'session_set_logs' })
@Unique('UQ_session_set_logs_triple', ['sessionId', 'exerciseId', 'sortOrder'])
export class SessionSetLogEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_session_set_logs_session_id')
  @Column({ name: 'session_id', type: 'uuid' })
  sessionId!: string;

  @ManyToOne(() => SessionEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'session_id' })
  session!: SessionEntity;

  @Index('IDX_session_set_logs_exercise_id')
  @Column({ name: 'exercise_id', type: 'uuid' })
  exerciseId!: string;

  @ManyToOne(() => ExerciseEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'exercise_id' })
  exercise!: ExerciseEntity;

  @Column({ name: 'sort_order', type: 'int' })
  sortOrder!: number;

  @Column({ type: 'int', nullable: true })
  reps!: number | null;

  @Column({
    name: 'weight_kg',
    type: 'numeric',
    precision: 6,
    scale: 2,
    nullable: true,
  })
  weightKg!: string | null;

  @Column({ name: 'duration_seconds', type: 'int', nullable: true })
  durationSeconds!: number | null;
}
