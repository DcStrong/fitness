import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type { SessionPackageDebitReason } from '../../session-packages/interface/session-package.types';
import { SessionEntity } from './session.entity';
import { SessionPackageEntity } from './session-package.entity';

@Entity({ name: 'session_package_debits' })
@Index('UQ_session_package_debits_package_session', ['packageId', 'sessionId'], {
  unique: true,
})
export class SessionPackageDebitEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'package_id', type: 'uuid' })
  packageId!: string;

  @ManyToOne(() => SessionPackageEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'package_id' })
  package!: SessionPackageEntity;

  @Index('IDX_session_package_debits_session')
  @Column({ name: 'session_id', type: 'uuid' })
  sessionId!: string;

  @ManyToOne(() => SessionEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'session_id' })
  session!: SessionEntity;

  @Column({ type: 'int' })
  delta!: number;

  @Column({ type: 'varchar', length: 32 })
  reason!: SessionPackageDebitReason;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
