/**
 * Pure helper: a plan is visible to a student when there is at least one shared tag id.
 * Link check is applied separately in the repository/query.
 */
export function hasTagIntersection(
  studentTagIds: ReadonlySet<string>,
  planTagIds: readonly string[],
): boolean {
  if (planTagIds.length === 0) {
return false;
}

  return planTagIds.some(id => studentTagIds.has(id));
}
