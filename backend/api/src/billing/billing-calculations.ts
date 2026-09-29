import type { MoneyMinor, ParsedFinancePeriod } from './interface';

/**
 *
 */
export function calculateNetMinor(
  receivedMinor: MoneyMinor,
  expensesMinor: MoneyMinor,
  adjustmentsMinor: MoneyMinor,
): MoneyMinor {
  return (
    BigInt(receivedMinor) -
    BigInt(expensesMinor) +
    BigInt(adjustmentsMinor)
  ).toString();
}

/**
 *
 */
export function reversalAmountMinor(
  type: 'income' | 'expense' | 'adjustment',
  amountMinor: MoneyMinor,
): MoneyMinor {
  const amount = BigInt(amountMinor);
  if (type === 'expense') {
    return amount.toString();
  }

  return (-amount).toString();
}

/**
 *
 */
export function parseFinancePeriod(
  fromValue: string,
  toValue: string,
): ParsedFinancePeriod | null {
  const from = new Date(fromValue);
  const to = new Date(toValue);
  if (
    Number.isNaN(from.getTime()) ||
    Number.isNaN(to.getTime()) ||
    to.getTime() <= from.getTime()
  ) {
    return null;
  }

  return { from, to };
}
