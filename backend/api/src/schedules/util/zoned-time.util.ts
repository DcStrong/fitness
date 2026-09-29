export interface LocalDateTimeParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second?: number;
}

/**
 * Convert a wall-clock local datetime in `timeZone` to a UTC `Date`.
 * Uses Intl offset correction (DST-aware).
 */
export function zonedLocalToUtc(
  parts: LocalDateTimeParts,
  timeZone: string,
): Date {
  const second = parts.second ?? 0;
  const utcGuess = Date.UTC(
    parts.year,
    parts.month - 1,
    parts.day,
    parts.hour,
    parts.minute,
    second,
    0,
  );
  const offset = getTimeZoneOffsetMs(new Date(utcGuess), timeZone);

  return new Date(utcGuess - offset);
}

/**
 * Format a UTC instant as local calendar parts in `timeZone`.
 */
export function utcToZonedParts(
  instant: Date,
  timeZone: string,
): Required<LocalDateTimeParts> {
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  });
  const map = Object.fromEntries(
    dtf
      .formatToParts(instant)
      .filter(part => part.type !== 'literal')
      .map(part => [part.type, part.value]),
  ) as Record<string, string>;

  return {
    year: Number(map['year']),
    month: Number(map['month']),
    day: Number(map['day']),
    hour: Number(map['hour']),
    minute: Number(map['minute']),
    second: Number(map['second']),
  };
}

/**
 * Local YYYY-MM-DD for an instant in `timeZone`.
 */
export function formatZonedDate(instant: Date, timeZone: string): string {
  const parts = utcToZonedParts(instant, timeZone);
  const month = String(parts.month).padStart(2, '0');
  const day = String(parts.day).padStart(2, '0');

  return `${parts.year}-${month}-${day}`;
}

/**
 * ISO weekday 1=Mon … 7=Sun for a civil YYYY-MM-DD date (timezone-independent).
 */
export function localDateWeekday(localDate: string): 1 | 2 | 3 | 4 | 5 | 6 | 7 {
  const [year, month, day] = localDate.split('-').map(Number) as [
    number,
    number,
    number,
  ];
  const noon = new Date(Date.UTC(year, month - 1, day, 12, 0, 0));
  const jsDay = noon.getUTCDay(); // 0=Sun … 6=Sat

  return (jsDay === 0 ? 7 : jsDay) as 1 | 2 | 3 | 4 | 5 | 6 | 7;
}

/**
 * Add calendar days to a YYYY-MM-DD local date string.
 */
export function addLocalDays(localDate: string, days: number): string {
  const [y, m, d] = localDate.split('-').map(Number);
  const utc = Date.UTC(y!, m! - 1, d! + days);
  const date = new Date(utc);
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const day = String(date.getUTCDate()).padStart(2, '0');

  return `${date.getUTCFullYear()}-${month}-${day}`;
}

/**
 * Offset of `timeZone` relative to UTC at `instant` (ms to add to local→get UTC is -offset).
 * `formatToParts(instant)` in zone minus treating those parts as UTC = offset.
 */
function getTimeZoneOffsetMs(instant: Date, timeZone: string): number {
  const parts = utcToZonedParts(instant, timeZone);
  const asUtc = Date.UTC(
    parts.year,
    parts.month - 1,
    parts.day,
    parts.hour,
    parts.minute,
    parts.second,
    0,
  );

  return asUtc - instant.getTime();
}
