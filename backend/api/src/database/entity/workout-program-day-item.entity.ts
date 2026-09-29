import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { TrainingPlanEntity } from './training-plan.entity';
import { WorkoutProgramDayEntity } from './workout-program-day.entity';

@Entity({ name: 'workout_program_day_items' })
@Unique('UQ_workout_program_day_items_order', ['programDayId', 'sortOrder'])
export class WorkoutProgramDayItemEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_workout_program_day_items_day_id')
  @Column({ name: 'program_day_id', type: 'uuid' })
  programDayId!: string;

  @ManyToOne(() => WorkoutProgramDayEntity, day => day.items, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'program_day_id' })
  programDay!: WorkoutProgramDayEntity;

  @Column({ name: 'sort_order', type: 'int' })
  sortOrder!: number;

  @Column({ name: 'template_id', type: 'uuid' })
  templateId!: string;

  @ManyToOne(() => TrainingPlanEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'template_id' })
  template!: TrainingPlanEntity;

  @Column({ name: 'student_plan_id', type: 'uuid' })
  studentPlanId!: string;

  @ManyToOne(() => TrainingPlanEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'student_plan_id' })
  studentPlan!: TrainingPlanEntity;
}
