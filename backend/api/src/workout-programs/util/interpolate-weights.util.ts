/**
 * Linear progression across n occurrences: first = start, last = start+delta.
 */
export function interpolateWeights(params: {
  startWeightKg: number;
  deltaKg: number;
  incrementKg: number;
  occurrenceCount: number;
}): number[] {
  const n = params.occurrenceCount;
  if (n <= 0) {
    return [];
  }
  const increment =
    params.incrementKg > 0 ? params.incrementKg : 2.5;
  const target = params.startWeightKg + params.deltaKg;
  if (n === 1) {
    return [roundToIncrement(target, increment)];
  }
  const result: number[] = [];
  for (let i = 0; i < n; i += 1) {
    if (i === n - 1) {
      result.push(roundToIncrement(target, increment));
      continue;
    }
    const raw =
      params.startWeightKg + params.deltaKg * (i / (n - 1));
    result.push(roundToIncrement(raw, increment));
  }

  return result;
}

/**
 *
 */
export function roundToIncrement(value: number, increment: number): number {
  if (increment <= 0) {
    return value;
  }

  return Math.round(value / increment) * increment;
}
