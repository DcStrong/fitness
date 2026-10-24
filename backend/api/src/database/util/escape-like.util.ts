/**
 * Экранирует спецсимволы LIKE (`\`, `%`, `_`), чтобы ввод искался буквально.
 */
export function escapeLike(value: string): string {
  return value.replace(/[\\%_]/gu, match => `\\${match}`);
}
