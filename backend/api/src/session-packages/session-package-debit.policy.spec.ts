import { shouldDebitSessionPackage } from './session-package-debit.policy';

describe('shouldDebitSessionPackage', () => {
  it('списывает при completed', () => {
    expect(shouldDebitSessionPackage('completed')).toBe('completed');
  });

  it('не списывает при cancelled', () => {
    expect(shouldDebitSessionPackage('cancelled')).toBeNull();
  });

  it('списывает при chargeable no_show', () => {
    expect(shouldDebitSessionPackage('no_show', true)).toBe(
      'no_show_chargeable',
    );
  });

  it('не списывает при non-chargeable no_show', () => {
    expect(shouldDebitSessionPackage('no_show', false)).toBeNull();
    expect(shouldDebitSessionPackage('no_show')).toBeNull();
  });
});
