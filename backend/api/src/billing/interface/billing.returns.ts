import type {
  BillingCurrency,
  FinanceLedgerEntryType,
  FinanceLedgerSourceType,
  MoneyMinor,
  PaymentMethod,
  SessionChargeStatus,
} from './billing.types';

/**
 *
 */
export interface FinanceSettingsReturns {
  defaultSessionPriceMinor: MoneyMinor;
  currency: BillingCurrency;
  updatedAt: string;
}

/**
 *
 */
export interface SessionChargeReturns {
  id: string;
  sessionId: string;
  coachId: string;
  studentId: string;
  amountMinor: MoneyMinor;
  currency: BillingCurrency;
  status: SessionChargeStatus;
  earnedAt: string | null;
  paidAt: string | null;
  paymentMethod: PaymentMethod | null;
  cancelledAt: string | null;
}

/**
 *
 */
export interface FinanceLedgerEntryReturns {
  id: string;
  coachId: string;
  type: FinanceLedgerEntryType;
  amountMinor: MoneyMinor;
  currency: BillingCurrency;
  sourceType: FinanceLedgerSourceType;
  sourceId: string | null;
  category: string | null;
  note: string | null;
  occurredAt: string;
  reversesEntryId: string | null;
  createdAt: string;
}

/**
 *
 */
export interface FinanceSummaryCounts {
  completed: number;
  noShowChargeable: number;
  paid: number;
  outstanding: number;
}

/**
 *
 */
export interface FinanceSummaryReturns {
  from: string;
  to: string;
  currency: BillingCurrency;
  accruedMinor: MoneyMinor;
  receivedMinor: MoneyMinor;
  outstandingMinor: MoneyMinor;
  expensesMinor: MoneyMinor;
  adjustmentsMinor: MoneyMinor;
  netMinor: MoneyMinor;
  counts: FinanceSummaryCounts;
}

/**
 *
 */
export interface DebtReturns {
  chargeId: string;
  sessionId: string;
  studentId: string;
  studentEmail: string | null;
  studentDisplayName: string | null;
  amountMinor: MoneyMinor;
  currency: BillingCurrency;
  earnedAt: string;
}

/**
 *
 */
export interface ChargeAggregateRow {
  accruedMinor: string | null;
  completedCount: string;
  noShowChargeableCount: string;
}

/**
 *
 */
export interface OutstandingAggregateRow {
  outstandingMinor: string | null;
  outstandingCount: string;
}

/**
 *
 */
export interface LedgerAggregateRow {
  receivedMinor: string | null;
  expensesMinor: string | null;
  adjustmentsMinor: string | null;
  paidCount: string;
}
