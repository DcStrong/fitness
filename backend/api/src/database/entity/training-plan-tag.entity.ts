import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { TagEntity } from './tag.entity';
import { TrainingPlanEntity } from './training-plan.entity';

@Entity({ name: 'training_plan_tags' })
@Unique('UQ_training_plan_tags_pair', ['planId', 'tagId'])
export class TrainingPlanTagEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_training_plan_tags_plan_id')
  @Column({ name: 'plan_id', type: 'uuid' })
  planId!: string;

  @ManyToOne(() => TrainingPlanEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'plan_id' })
  plan!: TrainingPlanEntity;

  @Index('IDX_training_plan_tags_tag_id')
  @Column({ name: 'tag_id', type: 'uuid' })
  tagId!: string;

  @ManyToOne(() => TagEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tag_id' })
  tag!: TagEntity;
}
