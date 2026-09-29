import {
  Column,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';
import type {
  BillingCurrency,
  MoneyMinor,
} from '../../billing/interface/billing.types';
import { UserEntity } from './user.entity';

@Entity({ name: 'coach_finance_settings' })
export class CoachFinanceSettingsEntity {
  @PrimaryColumn({ name: 'coach_id', type: 'uuid' })
  coachId!: string;

  @OneToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'coach_id' })
  coach!: UserEntity;

  @Column({ name: 'default_session_price_minor', type: 'bigint' })
  defaultSessionPriceMinor!: MoneyMinor;

  @Column({ type: 'char', length: 3, default: 'RUB' })
  currency!: BillingCurrency;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
