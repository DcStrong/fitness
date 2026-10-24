import {
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
} from 'typeorm';
import { GymEntity } from './gym.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'trainer_gyms' })
@Index('IDX_trainer_gyms_gym', ['gymId'])
export class TrainerGymEntity {
  @PrimaryColumn({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @PrimaryColumn({ name: 'gym_id', type: 'uuid' })
  gymId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @ManyToOne(() => GymEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'gym_id' })
  gym!: GymEntity;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
