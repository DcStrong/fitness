import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import type { ExerciseKind } from '../../exercises/interface';
import { ExerciseEntity } from './exercise.entity';
import { SessionWorkoutItemEntity } from './session-workout-item.entity';

@Entity({ name: 'session_prescription_sets' })
@Unique('UQ_session_prescription_sets_triple', [
  'sessionWorkoutItemId',
  'exerciseId',
  'sortOrder',
])
export class SessionPrescriptionSetEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_session_prescription_sets_item_id')
  @Column({ name: 'session_workout_item_id', type: 'uuid' })
  sessionWorkoutItemId!: string;

  @ManyToOne(() => SessionWorkoutItemEntity, item => item.sets, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'session_workout_item_id' })
  workoutItem!: SessionWorkoutItemEntity;

  @Column({ name: 'exercise_id', type: 'uuid' })
  exerciseId!: string;

  @ManyToOne(() => ExerciseEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'exercise_id' })
  exercise!: ExerciseEntity;

  @Column({ name: 'exercise_name', type: 'varchar', length: 120 })
  exerciseName!: string;

  @Column({ name: 'exercise_kind', type: 'varchar', length: 32 })
  exerciseKind!: ExerciseKind;

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
