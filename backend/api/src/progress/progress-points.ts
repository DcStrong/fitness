import type {
  ProgressLogRow,
  ProgressPointReturns,
} from './interface/progress.types';

/**
 *
 */
export function aggregateProgressPoints(
  rows: ProgressLogRow[],
): ProgressPointReturns[] {
  const bySession = new Map<
    string,
    {
      coachId: string;
      completedAt: Date;
      weightKg: number | null;
      volume: number;
    }
  >();
  for (const row of rows) {
    const weight =
      row.weightKg === null || row.weightKg === undefined
        ? null
        : Number(row.weightKg);
    const numericWeight = weight !== null && Number.isFinite(weight) ? weight : 0;
    const volume = (row.reps ?? 0) * numericWeight;
    const existing = bySession.get(row.sessionId);
    if (!existing) {
      bySession.set(row.sessionId, {
        coachId: row.coachId,
        completedAt: row.completedAt,
        weightKg: weight !== null && Number.isFinite(weight) ? weight : null,
        volume,
      });
      continue;
    }
    existing.volume += volume;
    if (weight !== null && Number.isFinite(weight)) {
      existing.weightKg =
        existing.weightKg === null
          ? weight
          : Math.max(existing.weightKg, weight);
    }
  }

  return [...bySession.entries()]
    .sort(
      (left, right) =>
        left[1].completedAt.getTime() - right[1].completedAt.getTime(),
    )
    .map(([sessionId, point]) => ({
      sessionId,
      coachId: point.coachId,
      completedAt: point.completedAt.toISOString(),
      weightKg: point.weightKg,
      volume: point.volume,
    }));
}
