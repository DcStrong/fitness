import type {
  DesiredOccurrence,
  RecurringOverrideType,
  WeekdayNumber,
} from '../interface/recurring-booking.types';
import {
  addLocalDays,
  localDateWeekday,
  zonedLocalToUtc,
} from '../../schedules/util/zoned-time.util';

export interface OccurrenceOverrideInput {
  localDate: string;
  type: RecurringOverrideType;
  newStartMinute: number | null;
  newLocalDate: string | null;
}

export interface ExpandOccurrencesParams {
  weekdays: WeekdayNumber[];
  startMinute: number;
  fromLocalDate: string;
  toLocalDateExclusive: string;
  overrides: OccurrenceOverrideInput[];
}

/**
 * Expand weekdays across a local-date horizon and apply skip/reschedule overrides.
 */
export function expandDesiredOccurrences(
  params: ExpandOccurrencesParams,
): DesiredOccurrence[] {
  const weekdaySet = new Set(params.weekdays);
  const bySource = new Map(
    params.overrides.map(item => [item.localDate, item] as const),
  );
  const result: DesiredOccurrence[] = [];

  for (
    let cursor = params.fromLocalDate;
    cursor < params.toLocalDateExclusive;
    cursor = addLocalDays(cursor, 1)
  ) {
    const dow = localDateWeekday(cursor);
    if (!weekdaySet.has(dow)) {
      continue;
    }
    const override = bySource.get(cursor);
    if (override?.type === 'skip') {
      continue;
    }
    if (override?.type === 'reschedule') {
      result.push({
        sourceLocalDate: cursor,
        localDate: override.newLocalDate ?? cursor,
        startMinute: override.newStartMinute ?? params.startMinute,
      });
      continue;
    }
    result.push({
      sourceLocalDate: cursor,
      localDate: cursor,
      startMinute: params.startMinute,
    });
  }

  return result;
}

/**
 * Convert local civil date + start minute + duration to UTC interval.
 */
export function occurrenceToUtcRange(params: {
  localDate: string;
  startMinute: number;
  durationMinutes: number;
  timezone: string;
}): { startsAt: Date; endsAt: Date } {
  const [year, month, day] = params.localDate.split('-').map(Number) as [
    number,
    number,
    number,
  ];
  const startHour = Math.floor(params.startMinute / 60);
  const startMin = params.startMinute % 60;
  const endMinute = params.startMinute + params.durationMinutes;
  const endHour = Math.floor(endMinute / 60);
  const endMin = endMinute % 60;
  const startsAt = zonedLocalToUtc(
    { year, month, day, hour: startHour, minute: startMin },
    params.timezone,
  );
  let endsAt: Date;
  if (endMinute >= 1440) {
    const next = addLocalDays(params.localDate, Math.floor(endMinute / 1440));
    const [ny, nm, nd] = next.split('-').map(Number) as [number, number, number];
    endsAt = zonedLocalToUtc(
      {
        year: ny,
        month: nm,
        day: nd,
        hour: Math.floor((endMinute % 1440) / 60),
        minute: endMinute % 60,
      },
      params.timezone,
    );
  } else {
    endsAt = zonedLocalToUtc(
      { year, month, day, hour: endHour, minute: endMin },
      params.timezone,
    );
  }

  return { startsAt, endsAt };
}
