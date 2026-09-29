import type { SessionPackageDebitReason } from './interface/session-package.types';

/**
 * Mirrors finance chargeable no_show: package debit only when the session
 * was "conducted" (completed) or explicitly chargeable no_show.
 */
export function shouldDebitSessionPackage(
  toStatus: 'completed' | 'cancelled' | 'no_show',
  chargeNoShow?: boolean,
): SessionPackageDebitReason | null {
  if (toStatus === 'completed') {
    return 'completed';
  }
  if (toStatus === 'no_show' && chargeNoShow === true) {
    return 'no_show_chargeable';
  }
  return null;
}
