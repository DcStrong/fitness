import { interpolateWeights, roundToIncrement } from './interpolate-weights.util';

describe('Интерполяция весов прогрессии', () => {
  it('якорит последнюю точку на start+delta', () => {
    expect(
      interpolateWeights({
        startWeightKg: 80,
        deltaKg: 5,
        incrementKg: 2.5,
        occurrenceCount: 4,
      }),
    ).toEqual([80, 82.5, 82.5, 85]);
  });

  it('при одном вхождении ставит целевой вес', () => {
    expect(
      interpolateWeights({
        startWeightKg: 80,
        deltaKg: 5,
        incrementKg: 2.5,
        occurrenceCount: 1,
      }),
    ).toEqual([85]);
  });

  it('округляет к шагу 2.5', () => {
    expect(roundToIncrement(81.2, 2.5)).toBe(80);
    expect(roundToIncrement(81.3, 2.5)).toBe(82.5);
  });
});
