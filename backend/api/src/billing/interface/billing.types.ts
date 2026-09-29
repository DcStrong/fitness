/**
 *
 */
export type MoneyMinor = string;

/**
 *
 */
export type BillingCurrency = 'RUB';

/**
 *
 */
export type SessionChargeStatus = 'pending' | 'paid' | 'cancelled';

/**
 *
 */
export type PaymentMethod = 'cash' | 'transfer' | 'card' | 'other';

/**
 *
 */
export type FinanceLedgerEntryType = 'income' | 'expense' | 'adjustment';

/**
 *
 */
export type FinanceLedgerSourceType = 'session_charge' | 'manual';

/**
 *
 */
export type ChargeLifecycleAction = 'earn' | 'cancel';

/**
 *
 */
export interface Money {
  amountMinor: MoneyMinor;
  currency: BillingCurrency;
}

/**
 *
 */
export interface SessionFinanceTracked extends Money {
  chargeId: string;
  status: SessionChargeStatus;
  earnedAt: string | null;
  paidAt: string | null;
  paymentMethod: PaymentMethod | null;
}

/**
 *
 */
export interface SessionFinanceNotTracked {
  status: 'not_tracked';
}

/**
 *
 */
export type SessionFinanceSummary =
  | SessionFinanceTracked
  | SessionFinanceNotTracked;

/**
 *
 */
export interface SessionChargeModel {
  id: string;
  sessionId: string;
  coachId: string;
  studentId: string;
  amountMinor: MoneyMinor;
  currency: BillingCurrency;
  status: SessionChargeStatus;
  earnedAt: Date | null;
  paidAt: Date | null;
  paymentMethod: PaymentMethod | null;
  cancelledAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

/**
 *
 */
export interface FinanceLedgerEntryModel {
  id: string;
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
  createdAt: Date;
}
