import type {
  BillingCurrency,
  FinanceLedgerEntryType,
  FinanceLedgerSourceType,
  MoneyMinor,
  PaymentMethod,
} from './billing.types';

/**
 *
 */
export interface FinanceActor {
  id: string;
  permissions: string[];
}

/**
 *
 */
export interface UpdateFinanceSettingsParams {
  defaultSessionPriceMinor: MoneyMinor;
  currency: BillingCurrency;
}

/**
 *
 */
export interface MarkChargePaidParams {
  chargeId: string;
  paymentMethod: PaymentMethod;
  paidAt?: string;
}

/**
 *
 */
export interface RecordExpenseParams {
  amountMinor: MoneyMinor;
  category?: string;
  note?: string;
  occurredAt?: string;
}

/**
 *
 */
export interface ReverseLedgerEntryParams {
  entryId: string;
  note?: string;
  occurredAt?: string;
}

/**
 *
 */
export interface FinancePeriodParams {
  from: string;
  to: string;
}

/**
 *
 */
export interface ListLedgerParams extends FinancePeriodParams {
  type?: FinanceLedgerEntryType;
  studentId?: string;
}

/**
 *
 */
export interface ListDebtsParams {
  studentId?: string;
}

/**
 *
 */
export interface ParsedFinancePeriod {
  from: Date;
  to: Date;
}

/**
 *
 */
export interface CreateSessionChargeParams {
  sessionId: string;
  coachId: string;
  studentId: string;
  amountMinor: MoneyMinor;
  currency: BillingCurrency;
}

/**
 *
 */
export interface SaveFinanceSettingsParams {
  coachId: string;
  defaultSessionPriceMinor: MoneyMinor;
  currency: BillingCurrency;
}

/**
 *
 */
export interface CreateLedgerEntryParams {
  coachId: string;
  type: FinanceLedgerEntryType;
  amountMinor: MoneyMinor;
  currency: BillingCurrency;
  sourceType: FinanceLedgerSourceType;
  sourceId: string | null;
  category: string | null;
  note: string | null;
  occurredAt: Date;
  reversesEntryId: string | null;
}

/**
 *
 */
export interface FindLedgerEntriesParams {
  coachId: string;
  from: Date;
  to: Date;
  type?: FinanceLedgerEntryType;
  studentId?: string;
}
