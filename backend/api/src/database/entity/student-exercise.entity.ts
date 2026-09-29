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
import { ExerciseEntity } from './exercise.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'student_exercises' })
@Unique('UQ_student_exercises_triple', ['coachId', 'studentId', 'exerciseId'])
export class StudentExerciseEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_student_exercises_coach_id')
  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Index('IDX_student_exercises_student_id')
  @Column({ name: 'student_id', type: 'uuid' })
  studentId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'student_id' })
  student!: UserEntity;

  @Index('IDX_student_exercises_exercise_id')
  @Column({ name: 'exercise_id', type: 'uuid' })
  exerciseId!: string;

  @ManyToOne(() => ExerciseEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'exercise_id' })
  exercise!: ExerciseEntity;

  @CreateDateColumn({ name: 'assigned_at', type: 'timestamptz' })
  assignedAt!: Date;
}
