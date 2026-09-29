import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { ExerciseEntity } from './exercise.entity';
import { PlanSetEntity } from './plan-set.entity';
import { TrainingPlanEntity } from './training-plan.entity';

@Entity({ name: 'plan_exercises' })
export class PlanExerciseEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_plan_exercises_plan_id')
  @Column({ name: 'plan_id', type: 'uuid' })
  planId!: string;

  @ManyToOne(() => TrainingPlanEntity, plan => plan.planExercises, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'plan_id' })
  plan!: TrainingPlanEntity;

  @Index('IDX_plan_exercises_exercise_id')
  @Column({ name: 'exercise_id', type: 'uuid' })
  exerciseId!: string;

  @ManyToOne(() => ExerciseEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'exercise_id' })
  exercise!: ExerciseEntity;

  @Column({ name: 'sort_order', type: 'int' })
  sortOrder!: number;

  @Column({ name: 'rest_seconds', type: 'int', nullable: true })
  restSeconds!: number | null;

  @Column({ type: 'text', default: '' })
  notes!: string;

  @OneToMany(() => PlanSetEntity, set => set.planExercise)
  sets!: PlanSetEntity[];
}
