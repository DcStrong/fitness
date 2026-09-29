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
import { RecurringBookingEntity } from './recurring-booking.entity';
import { UserEntity } from './user.entity';
import { WorkoutProgramDayEntity } from './workout-program-day.entity';
import { WorkoutProgressionRuleEntity } from './workout-progression-rule.entity';

@Entity({ name: 'workout_programs' })
export class WorkoutProgramEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('UQ_workout_programs_recurring', { unique: true })
  @Column({ name: 'recurring_booking_id', type: 'uuid' })
  recurringBookingId!: string;

  @ManyToOne(() => RecurringBookingEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'recurring_booking_id' })
  recurringBooking!: RecurringBookingEntity;

  @Column({ name: 'owner_coach_id', type: 'uuid' })
  ownerCoachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'owner_coach_id' })
  ownerCoach!: UserEntity;

  @Column({ name: 'student_id', type: 'uuid' })
  studentId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'student_id' })
  student!: UserEntity;

  @Column({ name: 'horizon_weeks', type: 'int', default: 2 })
  horizonWeeks!: number;

  @OneToMany(() => WorkoutProgramDayEntity, day => day.program)
  days!: WorkoutProgramDayEntity[];

  @OneToMany(() => WorkoutProgressionRuleEntity, rule => rule.program)
  rules!: WorkoutProgressionRuleEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
