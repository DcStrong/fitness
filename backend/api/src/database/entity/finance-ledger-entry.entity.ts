import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type {
  BillingCurrency,
  FinanceLedgerEntryType,
  FinanceLedgerSourceType,
  MoneyMinor,
} from '../../billing/interface/billing.types';
import { UserEntity } from './user.entity';

@Entity({ name: 'finance_ledger_entries' })
@Index('IDX_finance_ledger_coach_occurred', ['coachId', 'occurredAt'])
export class FinanceLedgerEntryEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Column({ type: 'varchar', length: 16 })
  type!: FinanceLedgerEntryType;

  @Column({ name: 'amount_minor', type: 'bigint' })
  amountMinor!: MoneyMinor;

  @Column({ type: 'char', length: 3 })
  currency!: BillingCurrency;

  @Column({ name: 'source_type', type: 'varchar', length: 32 })
  sourceType!: FinanceLedgerSourceType;

  @Column({ name: 'source_id', type: 'uuid', nullable: true })
  sourceId!: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  category!: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  note!: string | null;

  @Column({ name: 'occurred_at', type: 'timestamptz' })
  occurredAt!: Date;

  @Column({ name: 'reverses_entry_id', type: 'uuid', nullable: true })
  reversesEntryId!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
