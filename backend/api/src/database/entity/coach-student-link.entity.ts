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
import { UserEntity } from './user.entity';
import { InvitationEntity } from './invitation.entity';

@Entity({ name: 'coach_student_links' })
@Unique('UQ_coach_student_links_pair', ['coachId', 'studentId'])
export class CoachStudentLinkEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index('IDX_coach_student_links_coach_id')
  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Index('IDX_coach_student_links_student_id')
  @Column({ name: 'student_id', type: 'uuid' })
  studentId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'student_id' })
  student!: UserEntity;

  @Column({ name: 'source_invitation_id', type: 'uuid', nullable: true })
  sourceInvitationId!: string | null;

  @ManyToOne(() => InvitationEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'source_invitation_id' })
  sourceInvitation!: InvitationEntity | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
