export type SessionPackageStatus =
  | 'active'
  | 'exhausted'
  | 'expired'
  | 'archived';

export type SessionPackageDebitReason = 'completed' | 'no_show_chargeable';
