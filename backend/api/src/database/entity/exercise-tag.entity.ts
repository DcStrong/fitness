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
import { TagEntity } from './tag.entity';

@Entity({ name: 'exercise_tags' })
@Unique('UQ_exercise_tags_pair', ['exerciseId', 'tagId'])
export class ExerciseTagEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_exercise_tags_exercise_id')
  @Column({ name: 'exercise_id', type: 'uuid' })
  exerciseId!: string;

  @ManyToOne(() => ExerciseEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'exercise_id' })
  exercise!: ExerciseEntity;

  @Index('IDX_exercise_tags_tag_id')
  @Column({ name: 'tag_id', type: 'uuid' })
  tagId!: string;

  @ManyToOne(() => TagEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tag_id' })
  tag!: TagEntity;
}
