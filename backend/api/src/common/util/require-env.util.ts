/**
 * Значение обязательной переменной окружения; бросает Error, если она не задана.
 */
export function requireEnv(name: string): string {
  const value = process.env[name];
  if (value === undefined || value.trim().length === 0) {
    throw new Error(`Environment variable ${name} is required`);
  }

  return value.trim();
}
