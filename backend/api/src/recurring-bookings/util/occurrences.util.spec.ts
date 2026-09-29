import {
  expandDesiredOccurrences,
  occurrenceToUtcRange,
} from './occurrences.util';

describe('expandDesiredOccurrences', () => {
  it('разворачивает Пн/Ср/Пт в горизонте с понедельника', () => {
    const result = expandDesiredOccurrences({
      weekdays: [1, 3, 5],
      startMinute: 18 * 60,
      fromLocalDate: '2026-08-03', // Mon
      toLocalDateExclusive: '2026-08-17',
      overrides: [],
    });
    expect(result.map(item => item.localDate)).toEqual([
      '2026-08-03',
      '2026-08-05',
      '2026-08-07',
      '2026-08-10',
      '2026-08-12',
      '2026-08-14',
    ]);
    expect(result.every(item => item.startMinute === 18 * 60)).toBe(true);
  });

  it('пропускает дату с override skip', () => {
    const result = expandDesiredOccurrences({
      weekdays: [1, 3],
      startMinute: 18 * 60,
      fromLocalDate: '2026-08-03',
      toLocalDateExclusive: '2026-08-10',
      overrides: [
        {
          localDate: '2026-08-05',
          type: 'skip',
          newStartMinute: null,
          newLocalDate: null,
        },
      ],
    });
    expect(result.map(item => item.localDate)).toEqual([
      '2026-08-03',
    ]);
  });

  it('применяет reschedule на другое время', () => {
    const result = expandDesiredOccurrences({
      weekdays: [1],
      startMinute: 18 * 60,
      fromLocalDate: '2026-08-03',
      toLocalDateExclusive: '2026-08-10',
      overrides: [
        {
          localDate: '2026-08-03',
          type: 'reschedule',
          newStartMinute: 19 * 60,
          newLocalDate: null,
        },
      ],
    });
    expect(result).toEqual([
      {
        sourceLocalDate: '2026-08-03',
        localDate: '2026-08-03',
        startMinute: 19 * 60,
      },
    ]);
  });
});

describe('occurrenceToUtcRange', () => {
  it('конвертирует Europe/Moscow без DST-сдвига зимой', () => {
    const { startsAt, endsAt } = occurrenceToUtcRange({
      localDate: '2026-01-12',
      startMinute: 18 * 60,
      durationMinutes: 60,
      timezone: 'Europe/Moscow',
    });
    // Moscow is UTC+3 in January
    expect(startsAt.toISOString()).toBe('2026-01-12T15:00:00.000Z');
    expect(endsAt.toISOString()).toBe('2026-01-12T16:00:00.000Z');
  });

  it('учитывает DST spring-forward в America/New_York', () => {
    // 2026-03-08 is DST start in US; 02:00 local does not exist — 02:30 maps after jump
    const before = occurrenceToUtcRange({
      localDate: '2026-03-07',
      startMinute: 1 * 60 + 30,
      durationMinutes: 60,
      timezone: 'America/New_York',
    });
    const after = occurrenceToUtcRange({
      localDate: '2026-03-09',
      startMinute: 1 * 60 + 30,
      durationMinutes: 60,
      timezone: 'America/New_York',
    });
    // Offset difference across DST should be 1 hour for same local wall time
    const beforeOffset =
      Date.UTC(2026, 2, 7, 1, 30) - before.startsAt.getTime();
    const afterOffset =
      Date.UTC(2026, 2, 9, 1, 30) - after.startsAt.getTime();
    expect(Math.abs(beforeOffset - afterOffset)).toBe(60 * 60 * 1000);
  });

  it('учитывает DST fall-back в America/New_York', () => {
    const before = occurrenceToUtcRange({
      localDate: '2026-10-31',
      startMinute: 1 * 60 + 30,
      durationMinutes: 60,
      timezone: 'America/New_York',
    });
    const after = occurrenceToUtcRange({
      localDate: '2026-11-02',
      startMinute: 1 * 60 + 30,
      durationMinutes: 60,
      timezone: 'America/New_York',
    });
    const beforeOffset =
      Date.UTC(2026, 9, 31, 1, 30) - before.startsAt.getTime();
    const afterOffset =
      Date.UTC(2026, 10, 2, 1, 30) - after.startsAt.getTime();
    expect(Math.abs(beforeOffset - afterOffset)).toBe(60 * 60 * 1000);
  });
});
