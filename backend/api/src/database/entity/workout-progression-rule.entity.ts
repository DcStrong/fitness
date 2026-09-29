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
import { WorkoutProgramEntity } from './workout-program.entity';

@Entity({ name: 'workout_progression_rules' })
@Unique('UQ_workout_progression_rules_exercise', ['programId', 'exerciseId'])
export class WorkoutProgressionRuleEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_workout_progression_rules_program_id')
  @Column({ name: 'program_id', type: 'uuid' })
  programId!: string;

  @ManyToOne(() => WorkoutProgramEntity, program => program.rules, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'program_id' })
  program!: WorkoutProgramEntity;

  @Column({ name: 'exercise_id', type: 'uuid' })
  exerciseId!: string;

  @ManyToOne(() => ExerciseEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'exercise_id' })
  exercise!: ExerciseEntity;

  @Column({
    name: 'start_weight_kg',
    type: 'numeric',
    precision: 6,
    scale: 2,
    nullable: true,
  })
  startWeightKg!: string | null;

  @Column({
    name: 'delta_kg',
    type: 'numeric',
    precision: 6,
    scale: 2,
    default: '0.00',
  })
  deltaKg!: string;

  @Column({
    name: 'increment_kg',
    type: 'numeric',
    precision: 6,
    scale: 2,
    default: '2.50',
  })
  incrementKg!: string;

  @Column({ name: 'hold_on_miss', type: 'boolean', default: true })
  holdOnMiss!: boolean;

  @Column({
    name: 'held_weight_kg',
    type: 'numeric',
    precision: 6,
    scale: 2,
    nullable: true,
  })
  heldWeightKg!: string | null;
}
