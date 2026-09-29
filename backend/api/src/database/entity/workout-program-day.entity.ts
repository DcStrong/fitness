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
import type { WeekdayNumber } from '../../recurring-bookings/interface/recurring-booking.types';
import { WorkoutProgramEntity } from './workout-program.entity';
import { WorkoutProgramDayItemEntity } from './workout-program-day-item.entity';

@Entity({ name: 'workout_program_days' })
@Unique('UQ_workout_program_days_weekday', ['programId', 'weekday'])
export class WorkoutProgramDayEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_workout_program_days_program_id')
  @Column({ name: 'program_id', type: 'uuid' })
  programId!: string;

  @ManyToOne(() => WorkoutProgramEntity, program => program.days, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'program_id' })
  program!: WorkoutProgramEntity;

  @Column({ type: 'smallint' })
  weekday!: WeekdayNumber;

  @OneToMany(() => WorkoutProgramDayItemEntity, item => item.programDay)
  items!: WorkoutProgramDayItemEntity[];
}
