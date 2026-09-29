import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import type { SessionWorkoutSource } from '../../workout-programs/interface';
import { SessionEntity } from './session.entity';
import { SessionPrescriptionSetEntity } from './session-prescription-set.entity';
import { TrainingPlanEntity } from './training-plan.entity';

@Entity({ name: 'session_workout_items' })
@Unique('UQ_session_workout_items_order', ['sessionId', 'sortOrder'])
export class SessionWorkoutItemEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_session_workout_items_session_id')
  @Column({ name: 'session_id', type: 'uuid' })
  sessionId!: string;

  @ManyToOne(() => SessionEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'session_id' })
  session!: SessionEntity;

  @Column({ name: 'sort_order', type: 'int' })
  sortOrder!: number;

  @Column({ name: 'student_plan_id', type: 'uuid' })
  studentPlanId!: string;

  @ManyToOne(() => TrainingPlanEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'student_plan_id' })
  studentPlan!: TrainingPlanEntity;

  @Column({ type: 'varchar', length: 16 })
  source!: SessionWorkoutSource;

  @Column({ name: 'override_at', type: 'timestamptz', nullable: true })
  overrideAt!: Date | null;

  @OneToMany(() => SessionPrescriptionSetEntity, set => set.workoutItem)
  sets!: SessionPrescriptionSetEntity[];
}
