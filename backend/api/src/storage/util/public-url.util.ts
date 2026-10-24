/**
 * Базовый публичный URL хранилища без завершающего слэша; `null`, если не задан.
 */
export function readStoragePublicBase(): string | null {
  const raw = process.env['S3_PUBLIC_URL']?.trim();

  return raw ? raw.replace(/\/+$/u, '') : null;
}

/**
 * Начинается ли `url` с публичного адреса хранилища.
 */
export function isUrlUnderBase(url: string, base: string | null): boolean {
  return base !== null && url.startsWith(`${base}/`);
}
