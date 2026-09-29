import {
  buildFixedGridCandidates,
  sliceWindowToCandidates,
} from './fixed-grid.util';
import { zonedLocalToUtc } from './zoned-time.util';

describe('fixed-grid.util', () => {
  const baseSettings = {
    timezone: 'Europe/Moscow',
    defaultDurationMinutes: 60,
    breakMinutes: 15,
    onlineDurationMinutes: null,
    offlineDurationMinutes: null,
    defaultMode: 'offline' as const,
  };

  /**
   *
   */
  it('slices 09:00–13:00 with 60+15 into three slots', () => {
    const candidates = sliceWindowToCandidates({
      localDate: '2026-07-20',
      window: { startMinute: 9 * 60, endMinute: 13 * 60, mode: null },
      settings: baseSettings,
    });
    expect(candidates).toHaveLength(3);
    expect(candidates.map(c => [c.startsAt.toISOString(), c.endsAt.toISOString()])).toEqual([
      [
        zonedLocalToUtc(
          { year: 2026, month: 7, day: 20, hour: 9, minute: 0 },
          'Europe/Moscow',
        ).toISOString(),
        zonedLocalToUtc(
          { year: 2026, month: 7, day: 20, hour: 10, minute: 0 },
          'Europe/Moscow',
        ).toISOString(),
      ],
      [
        zonedLocalToUtc(
          { year: 2026, month: 7, day: 20, hour: 10, minute: 15 },
          'Europe/Moscow',
        ).toISOString(),
        zonedLocalToUtc(
          { year: 2026, month: 7, day: 20, hour: 11, minute: 15 },
          'Europe/Moscow',
        ).toISOString(),
      ],
      [
        zonedLocalToUtc(
          { year: 2026, month: 7, day: 20, hour: 11, minute: 30 },
          'Europe/Moscow',
        ).toISOString(),
        zonedLocalToUtc(
          { year: 2026, month: 7, day: 20, hour: 12, minute: 30 },
          'Europe/Moscow',
        ).toISOString(),
      ],
    ]);
  });

  /**
   *
   */
  it('skips window shorter than one duration', () => {
    const candidates = sliceWindowToCandidates({
      localDate: '2026-07-20',
      window: { startMinute: 9 * 60, endMinute: 9 * 60 + 45, mode: null },
      settings: baseSettings,
    });
    expect(candidates).toHaveLength(0);
  });

  /**
   *
   */
  it('expands multi-window Monday and skips Sunday by default', () => {
    // 2026-07-20 = Monday, 2026-07-21 = Tuesday, 2026-07-26 = Sunday
    const candidates = buildFixedGridCandidates({
      settings: baseSettings,
      windows: [
        {
          dayOfWeek: 1,
          startMinute: 9 * 60,
          endMinute: 11 * 60,
          mode: null,
        },
        {
          dayOfWeek: 1,
          startMinute: 14 * 60,
          endMinute: 15 * 60,
          mode: null,
        },
      ],
      exceptions: [],
      fromLocalDate: '2026-07-20',
      toLocalDateExclusive: '2026-07-27',
    });
    // Mon morning 09–11: only 09–10 fits (10:15–11:15 overflows);
    // Mon afternoon 14–15: one slot → 2 total
    expect(candidates).toHaveLength(2);
    const mondayStarts = candidates.map(c => c.startsAt.toISOString());
    expect(mondayStarts.every(iso => iso.startsWith('2026-07-20'))).toBe(true);
  });

  /**
   *
   */
  it('honors closed and custom_hours exceptions', () => {
    const candidates = buildFixedGridCandidates({
      settings: { ...baseSettings, breakMinutes: 0 },
      windows: [
        {
          dayOfWeek: 1,
          startMinute: 9 * 60,
          endMinute: 11 * 60,
          mode: null,
        },
      ],
      exceptions: [
        { localDate: '2026-07-20', type: 'closed', windows: null },
        {
          localDate: '2026-07-27',
          type: 'custom_hours',
          windows: [
            { startMinute: 10 * 60, endMinute: 11 * 60, mode: null },
          ],
        },
      ],
      fromLocalDate: '2026-07-20',
      toLocalDateExclusive: '2026-07-28',
    });
    expect(candidates).toHaveLength(1);
    expect(candidates[0]!.startsAt).toEqual(
      zonedLocalToUtc(
        { year: 2026, month: 7, day: 27, hour: 10, minute: 0 },
        'Europe/Moscow',
      ),
    );
  });

  /**
   *
   */
  it('handles America/New_York DST spring-forward (2026-03-08)', () => {
    // Local 01:30 EST exists; 02:30 does not (clocks jump 02→03).
    // Window 01:00–04:00, duration 60, break 0 →
    // 01:00–02:00 EST, then next start 02:00 becomes 03:00 EDT after jump when converted.
    const settings = {
      ...baseSettings,
      timezone: 'America/New_York',
      breakMinutes: 0,
    };
    const candidates = sliceWindowToCandidates({
      localDate: '2026-03-08',
      window: { startMinute: 1 * 60, endMinute: 4 * 60, mode: null },
      settings,
    });
    expect(candidates.length).toBeGreaterThanOrEqual(2);
    // First slot starts at 01:00 EST = 06:00 UTC
    expect(candidates[0]!.startsAt.toISOString()).toBe('2026-03-08T06:00:00.000Z');
    // 02:00 local wall time on spring-forward maps to 07:00 UTC (03:00 EDT)
    expect(candidates[1]!.startsAt.toISOString()).toBe('2026-03-08T07:00:00.000Z');
  });

  /**
   *
   */
  it('handles America/New_York DST fall-back (2026-11-01)', () => {
    const settings = {
      ...baseSettings,
      timezone: 'America/New_York',
      breakMinutes: 0,
    };
    const candidates = sliceWindowToCandidates({
      localDate: '2026-11-01',
      window: { startMinute: 0 * 60, endMinute: 3 * 60, mode: null },
      settings,
    });
    expect(candidates).toHaveLength(3);
    // 00:00 EDT = 04:00 UTC
    expect(candidates[0]!.startsAt.toISOString()).toBe('2026-11-01T04:00:00.000Z');
    // 01:00 first occurrence EDT = 05:00 UTC (ambiguous hour — Intl picks standard mapping)
    expect(candidates[1]!.startsAt.toISOString()).toMatch(
      /^2026-11-01T0[56]:00:00\.000Z$/,
    );
  });
});
