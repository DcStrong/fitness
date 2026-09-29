import { rangesOverlap } from './schedule-slot.repository';

describe('rangesOverlap (half-open)', () => {
  /**
   *
   */
  const t = (iso: string) => new Date(iso);

  it('detects overlapping intervals', () => {
    expect(
      rangesOverlap(
        t('2026-07-18T10:00:00.000Z'),
        t('2026-07-18T11:00:00.000Z'),
        t('2026-07-18T10:30:00.000Z'),
        t('2026-07-18T11:30:00.000Z'),
      ),
    ).toBe(true);
  });

  it('allows adjacent half-open intervals', () => {
    expect(
      rangesOverlap(
        t('2026-07-18T10:00:00.000Z'),
        t('2026-07-18T11:00:00.000Z'),
        t('2026-07-18T11:00:00.000Z'),
        t('2026-07-18T12:00:00.000Z'),
      ),
    ).toBe(false);
  });
});
