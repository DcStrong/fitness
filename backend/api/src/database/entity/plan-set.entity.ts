import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { PlanExerciseEntity } from './plan-exercise.entity';

@Entity({ name: 'plan_sets' })
export class PlanSetEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_plan_sets_plan_exercise_id')
  @Column({ name: 'plan_exercise_id', type: 'uuid' })
  planExerciseId!: string;

  @ManyToOne(() => PlanExerciseEntity, row => row.sets, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'plan_exercise_id' })
  planExercise!: PlanExerciseEntity;

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
