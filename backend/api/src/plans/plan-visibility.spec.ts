import { hasTagIntersection } from './plan-visibility';

describe('hasTagIntersection', () => {
  it('requires non-empty shared tags', () => {
    expect(hasTagIntersection(new Set(['a']), ['a', 'b'])).toBe(true);
    expect(hasTagIntersection(new Set(['a']), ['b'])).toBe(false);
    expect(hasTagIntersection(new Set(['a']), [])).toBe(false);
  });
});
