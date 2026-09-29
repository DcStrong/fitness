import {
  calculateNetMinor,
  parseFinancePeriod,
  reversalAmountMinor,
} from './billing-calculations';
import { getChargeLifecycleAction } from './session-charge-policy';

describe('финансовые вычисления', () => {
  it('считает net без потери точности minor units', () => {
    expect(
      calculateNetMinor(
        '900719925474099300',
        '100000000000000000',
        '-300',
      ),
    ).toBe('800719925474099000');
  });

  it('строит компенсирующую корректировку для каждого типа ledger', () => {
    expect(reversalAmountMinor('income', '150000')).toBe('-150000');
    expect(reversalAmountMinor('expense', '25000')).toBe('25000');
    expect(reversalAmountMinor('adjustment', '-700')).toBe('700');
  });

  it('принимает только возрастающие ISO-границы периода', () => {
    const period = parseFinancePeriod(
      '2026-07-01T00:00:00.000Z',
      '2026-08-01T00:00:00.000Z',
    );
    expect(period?.from.toISOString()).toBe('2026-07-01T00:00:00.000Z');
    expect(period?.to.toISOString()).toBe('2026-08-01T00:00:00.000Z');
    expect(
      parseFinancePeriod(
        '2026-08-01T00:00:00.000Z',
        '2026-08-01T00:00:00.000Z',
      ),
    ).toBeNull();
    expect(parseFinancePeriod('invalid', '2026-08-01T00:00:00.000Z')).toBeNull();
  });
});

describe('политика начисления lifecycle', () => {
  it('начисляет completed и платную неявку', () => {
    expect(getChargeLifecycleAction('completed')).toBe('earn');
    expect(getChargeLifecycleAction('no_show', true)).toBe('earn');
  });

  it('отменяет cancelled и бесплатную неявку', () => {
    expect(getChargeLifecycleAction('cancelled')).toBe('cancel');
    expect(getChargeLifecycleAction('no_show', false)).toBe('cancel');
  });
});
