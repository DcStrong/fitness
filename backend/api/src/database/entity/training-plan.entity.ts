import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { PlanGoal, PlanKind } from '../../plans/interface';
import { UserEntity } from './user.entity';
import { PlanExerciseEntity } from './plan-exercise.entity';

@Entity({ name: 'training_plans' })
export class TrainingPlanEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_training_plans_owner_coach_id')
  @Column({ name: 'owner_coach_id', type: 'uuid' })
  ownerCoachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'owner_coach_id' })
  ownerCoach!: UserEntity;

  @Column({ type: 'varchar', length: 200 })
  title!: string;

  @Column({ type: 'text', default: '' })
  body!: string;

  @Index('IDX_training_plans_kind')
  @Column({ type: 'varchar', length: 32, default: 'template' })
  kind!: PlanKind;

  @Column({ type: 'varchar', length: 32, default: 'general' })
  goal!: PlanGoal;

  @Column({ name: 'parent_template_id', type: 'uuid', nullable: true })
  parentTemplateId!: string | null;

  @ManyToOne(() => TrainingPlanEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'parent_template_id' })
  parentTemplate!: TrainingPlanEntity | null;

  @Column({ name: 'assigned_student_id', type: 'uuid', nullable: true })
  assignedStudentId!: string | null;

  @ManyToOne(() => UserEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assigned_student_id' })
  assignedStudent!: UserEntity | null;

  @OneToMany(() => PlanExerciseEntity, row => row.plan)
  planExercises!: PlanExerciseEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
