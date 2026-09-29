import { canTransition } from './session-lifecycle.rules';

describe('canTransition', () => {
  it('allows booked → completed/cancelled/no_show', () => {
    expect(canTransition('booked', 'completed')).toBe(true);
    expect(canTransition('booked', 'cancelled')).toBe(true);
    expect(canTransition('booked', 'no_show')).toBe(true);
  });

  it('rejects reverse and terminal hops', () => {
    expect(canTransition('completed', 'booked')).toBe(false);
    expect(canTransition('cancelled', 'completed')).toBe(false);
    expect(canTransition('booked', 'booked')).toBe(false);
    expect(canTransition('no_show', 'cancelled')).toBe(false);
  });
});
