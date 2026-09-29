import type {
  AvailabilityExceptionType,
  AvailabilityExceptionWindowModel,
  AvailabilitySlotCandidate,
  AvailabilityWindowModel,
  WeekdayNumber,
} from '../interface/availability.types';
import type { ScheduleSlotMode } from '../interface/schedule-slot.types';
import {
  addLocalDays,
  formatZonedDate,
  localDateWeekday,
  zonedLocalToUtc,
} from './zoned-time.util';

export interface FixedGridWindowInput {
  startMinute: number;
  endMinute: number;
  mode: ScheduleSlotMode | null;
}

export interface FixedGridSettingsInput {
  timezone: string;
  defaultDurationMinutes: number;
  breakMinutes: number;
  onlineDurationMinutes: number | null;
  offlineDurationMinutes: number | null;
  defaultMode: ScheduleSlotMode;
}

export interface FixedGridExceptionInput {
  localDate: string;
  type: AvailabilityExceptionType;
  windows: AvailabilityExceptionWindowModel[] | null;
}

export interface BuildFixedGridParams {
  settings: FixedGridSettingsInput;
  windows: AvailabilityWindowModel[];
  exceptions: FixedGridExceptionInput[];
  /** Inclusive local start date YYYY-MM-DD */
  fromLocalDate: string;
  /** Exclusive local end date YYYY-MM-DD */
  toLocalDateExclusive: string;
}

/**
 * Slice a single local window into fixed-grid slot candidates (UTC).
 */
export function sliceWindowToCandidates(params: {
  localDate: string;
  window: FixedGridWindowInput;
  settings: FixedGridSettingsInput;
}): AvailabilitySlotCandidate[] {
  const { localDate, window, settings } = params;
  const [year, month, day] = localDate.split('-').map(Number) as [
    number,
    number,
    number,
  ];
  const mode = window.mode ?? settings.defaultMode;
  const duration = resolveDurationMinutes(settings, mode);
  const step = duration + settings.breakMinutes;
  if (duration <= 0 || step <= 0) {
    return [];
  }

  const candidates: AvailabilitySlotCandidate[] = [];
  for (
    let startMinute = window.startMinute;
    startMinute + duration <= window.endMinute;
    startMinute += step
  ) {
    const startHour = Math.floor(startMinute / 60);
    const startMin = startMinute % 60;
    const endMinute = startMinute + duration;
    const endHour = Math.floor(endMinute / 60);
    const endMin = endMinute % 60;
    const startsAt = zonedLocalToUtc(
      { year, month, day, hour: startHour, minute: startMin },
      settings.timezone,
    );
    const endsAt = zonedLocalToUtc(
      { year, month, day, hour: endHour, minute: endMin },
      settings.timezone,
    );
    candidates.push({ startsAt, endsAt, mode });
  }

  return candidates;
}

/**
 * Expand weekly template + exceptions into fixed-grid UTC candidates.
 */
export function buildFixedGridCandidates(
  params: BuildFixedGridParams,
): AvailabilitySlotCandidate[] {
  const byDow = groupWindowsByDow(params.windows);
  const exceptionByDate = new Map(
    params.exceptions.map(item => [item.localDate, item]),
  );
  const result: AvailabilitySlotCandidate[] = [];

  for (
    let cursor = params.fromLocalDate;
    cursor < params.toLocalDateExclusive;
    cursor = addLocalDays(cursor, 1)
  ) {
    const dow = localDateWeekday(cursor);
    const dayWindows = resolveDayWindows(cursor, dow, byDow, exceptionByDate);
    for (const window of dayWindows) {
      result.push(
        ...sliceWindowToCandidates({
          localDate: cursor,
          window,
          settings: params.settings,
        }),
      );
    }
  }

  return result;
}

/**
 * Horizon end as exclusive local date from a UTC "now" and weeks count.
 */
export function horizonLocalRange(
  now: Date,
  timezone: string,
  horizonWeeks: number,
): { fromLocalDate: string; toLocalDateExclusive: string } {
  const fromLocalDate = formatZonedDate(now, timezone);
  const toLocalDateExclusive = addLocalDays(fromLocalDate, horizonWeeks * 7);

  return { fromLocalDate, toLocalDateExclusive };
}

function resolveDurationMinutes(
  settings: FixedGridSettingsInput,
  mode: ScheduleSlotMode,
): number {
  if (mode === 'online' && settings.onlineDurationMinutes != null) {
    return settings.onlineDurationMinutes;
  }
  if (mode === 'offline' && settings.offlineDurationMinutes != null) {
    return settings.offlineDurationMinutes;
  }

  return settings.defaultDurationMinutes;
}

function groupWindowsByDow(
  windows: AvailabilityWindowModel[],
): Map<WeekdayNumber, FixedGridWindowInput[]> {
  const map = new Map<WeekdayNumber, FixedGridWindowInput[]>();
  for (const window of windows) {
    const list = map.get(window.dayOfWeek) ?? [];
    list.push({
      startMinute: window.startMinute,
      endMinute: window.endMinute,
      mode: window.mode,
    });
    map.set(window.dayOfWeek, list);
  }

  return map;
}

function resolveDayWindows(
  localDate: string,
  dow: WeekdayNumber,
  byDow: Map<WeekdayNumber, FixedGridWindowInput[]>,
  exceptionByDate: Map<string, FixedGridExceptionInput>,
): FixedGridWindowInput[] {
  const exception = exceptionByDate.get(localDate);
  if (exception?.type === 'closed') {
    return [];
  }
  if (exception?.type === 'custom_hours') {
    return (exception.windows ?? []).map(window => ({
      startMinute: window.startMinute,
      endMinute: window.endMinute,
      mode: window.mode,
    }));
  }

  return byDow.get(dow) ?? [];
}
