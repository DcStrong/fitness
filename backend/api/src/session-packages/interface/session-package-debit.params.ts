export interface ApplySessionPackageDebitParams {
  coachId: string;
  studentId: string;
  sessionId: string;
  toStatus: 'completed' | 'cancelled' | 'no_show';
  chargeNoShow?: boolean;
}

export interface ApplySessionPackageDebitReturns {
  packageExhausted: boolean;
  debited: boolean;
}
