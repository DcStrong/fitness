import { applySessionPackageDebit } from './apply-session-package-debit';
import { SessionPackageEntity } from '../database/entity/session-package.entity';
import { SessionPackageDebitEntity } from '../database/entity/session-package-debit.entity';

describe('applySessionPackageDebit', () => {
  const base = {
    coachId: 'coach-1',
    studentId: 'student-1',
    sessionId: 'session-1',
  };

  function mockManager(opts: {
    pkg?: SessionPackageEntity | null;
    existingDebit?: SessionPackageDebitEntity | null;
  }) {
    const saved: unknown[] = [];
    return {
      manager: {
        findOne: jest.fn(async (entity: unknown, _options: { where: Record<string, unknown> }) => {
          if (entity === SessionPackageEntity) {
            return opts.pkg ?? null;
          }
          if (entity === SessionPackageDebitEntity) {
            return opts.existingDebit ?? null;
          }
          return null;
        }),
        save: jest.fn(async (entity: unknown) => {
          saved.push(entity);
          return entity;
        }),
        create: jest.fn(
          (_entity: unknown, data: Record<string, unknown>) => data,
        ),
      },
      saved,
    };
  }

  it('не списывает при cancel', async () => {
    const { manager, saved } = mockManager({
      pkg: {
        id: 'pkg-1',
        remainingSessions: 3,
        status: 'active',
        expiresAt: null,
      } as SessionPackageEntity,
    });

    const result = await applySessionPackageDebit(manager as never, {
      ...base,
      toStatus: 'cancelled',
    });

    expect(result).toEqual({ packageExhausted: false, debited: false });
    expect(saved).toHaveLength(0);
  });

  it('списывает 1 при completed', async () => {
    const pkg = {
      id: 'pkg-1',
      remainingSessions: 3,
      status: 'active',
      expiresAt: null,
    } as SessionPackageEntity;
    const { manager } = mockManager({ pkg });

    const result = await applySessionPackageDebit(manager as never, {
      ...base,
      toStatus: 'completed',
    });

    expect(result).toEqual({ packageExhausted: false, debited: true });
    expect(pkg.remainingSessions).toBe(2);
    expect(pkg.status).toBe('active');
  });

  it('исчерпывает пакет на последнем completed', async () => {
    const pkg = {
      id: 'pkg-1',
      remainingSessions: 1,
      status: 'active',
      expiresAt: null,
    } as SessionPackageEntity;
    const { manager } = mockManager({ pkg });

    const result = await applySessionPackageDebit(manager as never, {
      ...base,
      toStatus: 'completed',
    });

    expect(result).toEqual({ packageExhausted: true, debited: true });
    expect(pkg.remainingSessions).toBe(0);
    expect(pkg.status).toBe('exhausted');
  });

  it('списывает при chargeable no_show', async () => {
    const pkg = {
      id: 'pkg-1',
      remainingSessions: 2,
      status: 'active',
      expiresAt: null,
    } as SessionPackageEntity;
    const { manager } = mockManager({ pkg });

    const result = await applySessionPackageDebit(manager as never, {
      ...base,
      toStatus: 'no_show',
      chargeNoShow: true,
    });

    expect(result.debited).toBe(true);
    expect(pkg.remainingSessions).toBe(1);
  });

  it('не списывает при non-chargeable no_show', async () => {
    const pkg = {
      id: 'pkg-1',
      remainingSessions: 2,
      status: 'active',
      expiresAt: null,
    } as SessionPackageEntity;
    const { manager } = mockManager({ pkg });

    const result = await applySessionPackageDebit(manager as never, {
      ...base,
      toStatus: 'no_show',
      chargeNoShow: false,
    });

    expect(result.debited).toBe(false);
    expect(pkg.remainingSessions).toBe(2);
  });

  it('идемпотентен при повторном debit той же session', async () => {
    const pkg = {
      id: 'pkg-1',
      remainingSessions: 2,
      status: 'active',
      expiresAt: null,
    } as SessionPackageEntity;
    const { manager } = mockManager({
      pkg,
      existingDebit: { id: 'debit-1' } as SessionPackageDebitEntity,
    });

    const result = await applySessionPackageDebit(manager as never, {
      ...base,
      toStatus: 'completed',
    });

    expect(result.debited).toBe(false);
    expect(pkg.remainingSessions).toBe(2);
  });

  it('no-op без пакета', async () => {
    const { manager } = mockManager({ pkg: null });

    const result = await applySessionPackageDebit(manager as never, {
      ...base,
      toStatus: 'completed',
    });

    expect(result).toEqual({ packageExhausted: false, debited: false });
  });

  it('не списывает истёкший пакет и помечает expired', async () => {
    const pkg = {
      id: 'pkg-1',
      remainingSessions: 3,
      status: 'active',
      expiresAt: new Date('2020-01-01T00:00:00.000Z'),
    } as SessionPackageEntity;
    const { manager } = mockManager({ pkg });

    const result = await applySessionPackageDebit(manager as never, {
      ...base,
      toStatus: 'completed',
    });

    expect(result.debited).toBe(false);
    expect(pkg.status).toBe('expired');
  });
});
