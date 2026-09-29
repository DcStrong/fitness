import { aggregateProgressPoints } from './progress-points';

describe('Агрегация точек прогресса', () => {
  it('считает max вес и volume по сессии и сортирует по времени', () => {
    const points = aggregateProgressPoints([
      {
        sessionId: 's2',
        coachId: 'c1',
        completedAt: new Date('2026-08-02T10:00:00.000Z'),
        reps: 8,
        weightKg: '50.00',
      },
      {
        sessionId: 's1',
        coachId: 'c1',
        completedAt: new Date('2026-08-01T10:00:00.000Z'),
        reps: 10,
        weightKg: '40.00',
      },
      {
        sessionId: 's1',
        coachId: 'c1',
        completedAt: new Date('2026-08-01T10:00:00.000Z'),
        reps: 8,
        weightKg: '42.50',
      },
    ]);

    expect(points).toHaveLength(2);
    expect(points[0]).toMatchObject({
      sessionId: 's1',
      weightKg: 42.5,
      volume: 10 * 40 + 8 * 42.5,
    });
    expect(points[1]).toMatchObject({
      sessionId: 's2',
      weightKg: 50,
      volume: 8 * 50,
    });
  });
});
