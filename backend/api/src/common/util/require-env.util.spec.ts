import { requireEnv } from './require-env.util';

describe('requireEnv', () => {
  it('возвращает значение без пробелов по краям', () => {
    process.env['REQUIRE_ENV_TEST'] = ' value ';

    expect(requireEnv('REQUIRE_ENV_TEST')).toBe('value');
    delete process.env['REQUIRE_ENV_TEST'];
  });

  it('бросает ошибку, если переменная пуста или не задана', () => {
    expect(() => requireEnv('REQUIRE_ENV_MISSING')).toThrow('REQUIRE_ENV_MISSING');
  });
});
