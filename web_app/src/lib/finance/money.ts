import type { Currency } from '../api/types';

export function formatMoney(
  amountMinor: string,
  currency: Currency = 'RUB',
): string {
  try {
    const amount = BigInt(amountMinor);
    const hundred = BigInt(100);
    const negative = amount < BigInt(0);
    const absolute = negative ? -amount : amount;
    const major = absolute / hundred;
    const minor = (absolute % hundred).toString().padStart(2, '0');
    const grouped = major.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '\u00a0');
    const symbol = currency === 'RUB' ? '₽' : currency;
    return `${negative ? '−' : ''}${grouped},${minor}\u00a0${symbol}`;
  } catch {
    return `${amountMinor}\u00a0${currency}`;
  }
}

export function rublesToMinor(value: string): string | null {
  const normalized = value.trim().replace(',', '.');
  const match = /^(\d+)(?:\.(\d{1,2}))?$/.exec(normalized);
  if (!match) return null;

  const major = match[1].replace(/^0+(?=\d)/, '');
  const minor = (match[2] ?? '').padEnd(2, '0');
  return (
    BigInt(major) * BigInt(100) +
    BigInt(minor || '0')
  ).toString();
}

export function minorToRubles(value: string): string {
  try {
    const amount = BigInt(value);
    const hundred = BigInt(100);
    return `${amount / hundred}.${(amount % hundred)
      .toString()
      .padStart(2, '0')}`;
  } catch {
    return '';
  }
}
