import type { ChargeLifecycleAction } from './interface';

/**
 *
 */
export function getChargeLifecycleAction(
  target: 'completed' | 'cancelled' | 'no_show',
  chargeNoShow?: boolean,
): ChargeLifecycleAction {
  if (target === 'completed') {
return 'earn';
}
  if (target === 'cancelled') {
return 'cancel';
}
  if (chargeNoShow === true) {
return 'earn';
}

  return 'cancel';
}
