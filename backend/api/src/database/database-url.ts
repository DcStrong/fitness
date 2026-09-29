/**
 * Normalize DATABASE_URL for node-pg/TypeORM (strip Prisma-only ?schema=).
 */
export function resolveDatabaseUrl(): string {
  const raw = process.env['DATABASE_URL'];
  if (raw && raw.trim().length > 0) {
    return raw
      .replace(/([?&])schema=[^&]*/g, '$1')
      .replace(/[?&]$/, '')
      .replace(/\?&/, '?');
  }

  const host = process.env['DB_HOST'] ?? 'localhost';
  const port = process.env['DB_PORT'] ?? '5432';
  const name = process.env['DB_NAME'] ?? 'fitness_yoda';
  const user = process.env['DB_USERNAME'] ?? 'postgres';
  const password = process.env['DB_PASSWORD'] ?? '';

  return `postgresql://${encodeURIComponent(user)}:${encodeURIComponent(password)}@${host}:${port}/${name}`;
}
