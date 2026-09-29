import type { SessionStatus } from './interface/session.types';

const TERMINAL: ReadonlySet<SessionStatus> = new Set([
  'completed',
  'cancelled',
  'no_show',
]);

/** MVP matrix: only booked → completed | cancelled | no_show. */
export function canTransition(
  from: SessionStatus,
  to: SessionStatus,
): boolean {
  return from === 'booked' && TERMINAL.has(to);
}
