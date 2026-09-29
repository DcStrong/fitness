import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { SessionPackagesService } from './session-packages.service';
import type { SessionPackageEntity } from '../database/entity/session-package.entity';

describe('SessionPackagesService', () => {
  const coachId = 'coach-1';
  const studentId = 'student-1';

  function buildPackage(
    overrides: Partial<SessionPackageEntity> = {},
  ): SessionPackageEntity {
    return {
      id: 'pkg-1',
      coachId,
      studentId,
      totalSessions: 8,
      remainingSessions: 8,
      expiresAt: null,
      status: 'active',
      archivedAt: null,
      createdAt: new Date('2026-08-01T00:00:00.000Z'),
      updatedAt: new Date('2026-08-01T00:00:00.000Z'),
      coach: { email: 'coach@example.com' } as never,
      student: { email: 'student@example.com' } as never,
      ...overrides,
    } as SessionPackageEntity;
  }

  function buildService(overrides: {
    findByPair?: jest.Mock;
    findActiveByPair?: jest.Mock;
    findById?: jest.Mock;
    findByParticipant?: jest.Mock;
    save?: jest.Mock;
    create?: jest.Mock;
    transaction?: jest.Mock;
  } = {}) {
    const packages = {
      findActiveByPair:
        overrides.findActiveByPair ?? jest.fn(async () => null),
      findById: overrides.findById ?? jest.fn(async () => buildPackage()),
      findByParticipant:
        overrides.findByParticipant ?? jest.fn(async () => []),
      save:
        overrides.save ??
        jest.fn(async (entity: SessionPackageEntity) => entity),
      create:
        overrides.create ??
        jest.fn((data: Partial<SessionPackageEntity>) =>
          buildPackage({ ...data }),
        ),
      findByCoachId: jest.fn(),
      findByStudentId: jest.fn(),
    };
    const links = {
      findByPair:
        overrides.findByPair ?? jest.fn(async () => ({ id: 'link-1' })),
    };
    const dataSource = {
      transaction:
        overrides.transaction ??
        jest.fn(async (fn: (m: unknown) => Promise<unknown>) =>
          fn({
            findOne: jest.fn(),
            save: jest.fn(async (e: unknown) => e),
          }),
        ),
    };
    const service = new SessionPackagesService(
      dataSource as never,
      packages as never,
      links as never,
    );
    return { service, packages, links, dataSource };
  }

  it('создаёт пакет для связанного ученика', async () => {
    const { service, packages } = buildService({
      findById: jest.fn(async () =>
        buildPackage({ totalSessions: 8, remainingSessions: 8 }),
      ),
    });

    const result = await service.create({
      coachId,
      studentId,
      totalSessions: 8,
    });

    expect(result.remainingSessions).toBe(8);
    expect(result.status).toBe('active');
    expect(packages.save).toHaveBeenCalled();
  });

  it('отклоняет создание без связи', async () => {
    const { service } = buildService({
      findByPair: jest.fn(async () => null),
    });

    await expect(
      service.create({ coachId, studentId, totalSessions: 4 }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('отклоняет второй active пакет', async () => {
    const { service } = buildService({
      findActiveByPair: jest.fn(async () => buildPackage()),
    });

    await expect(
      service.create({ coachId, studentId, totalSessions: 4 }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('архивирует пакет', async () => {
    const { service, packages } = buildService({
      findById: jest.fn(async () => buildPackage()),
      save: jest.fn(async (entity: SessionPackageEntity) => entity),
    });

    const result = await service.archive({ coachId, packageId: 'pkg-1' });
    expect(result.status).toBe('archived');
    expect(result.archivedAt).toBeTruthy();
    expect(packages.save).toHaveBeenCalled();
  });

  it('отклоняет get чужого пакета', async () => {
    const { service } = buildService({
      findById: jest.fn(async () => buildPackage()),
    });

    await expect(
      service.get({ actorId: 'stranger', packageId: 'pkg-1' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('лениво помечает истёкший пакет при чтении', async () => {
    const expired = buildPackage({
      expiresAt: new Date('2020-01-01T00:00:00.000Z'),
      status: 'active',
    });
    const { service, packages } = buildService({
      findById: jest.fn(async () => expired),
      save: jest.fn(async (entity: SessionPackageEntity) => entity),
    });

    const result = await service.get({ actorId: coachId, packageId: 'pkg-1' });
    expect(result.status).toBe('expired');
    expect(packages.save).toHaveBeenCalled();
  });

  it('продлевает exhausted пакет и реактивирует', async () => {
    const exhausted = buildPackage({
      status: 'exhausted',
      remainingSessions: 0,
      totalSessions: 8,
    });
    const reloaded = buildPackage({
      status: 'active',
      remainingSessions: 4,
      totalSessions: 12,
    });
    const { service } = buildService({
      findById: jest.fn(async () => reloaded),
      transaction: jest.fn(async (fn: (m: unknown) => Promise<unknown>) =>
        fn({
          findOne: jest.fn(async () => exhausted),
          save: jest.fn(async (e: SessionPackageEntity) => e),
        }),
      ),
    });

    const result = await service.extend({
      coachId,
      packageId: 'pkg-1',
      addSessions: 4,
    });

    expect(result.status).toBe('active');
    expect(result.remainingSessions).toBe(4);
    expect(result.totalSessions).toBe(12);
  });

  it('не находит пакет другого тренера при archive', async () => {
    const { service } = buildService({
      findById: jest.fn(async () => buildPackage({ coachId: 'other' })),
    });

    await expect(
      service.archive({ coachId, packageId: 'pkg-1' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
