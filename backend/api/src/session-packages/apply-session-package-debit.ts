import type { EntityManager } from 'typeorm';
import { SessionPackageDebitEntity } from '../database/entity/session-package-debit.entity';
import { SessionPackageEntity } from '../database/entity/session-package.entity';
import type {
  ApplySessionPackageDebitParams,
  ApplySessionPackageDebitReturns,
} from './interface';
import { shouldDebitSessionPackage } from './session-package-debit.policy';
import type { SessionPackageStatus } from './interface/session-package.types';

/**
 * Applies package debit inside an existing transaction (lifecycle).
 * Lazy-expires active packages past expiresAt before debiting.
 */
export async function applySessionPackageDebit(
  manager: EntityManager,
  params: ApplySessionPackageDebitParams,
): Promise<ApplySessionPackageDebitReturns> {
  const reason = shouldDebitSessionPackage(
    params.toStatus,
    params.chargeNoShow,
  );
  if (!reason) {
    return { packageExhausted: false, debited: false };
  }

  const pkg = await manager.findOne(SessionPackageEntity, {
    where: {
      coachId: params.coachId,
      studentId: params.studentId,
      status: 'active' satisfies SessionPackageStatus,
    },
    lock: { mode: 'pessimistic_write' },
  });

  if (!pkg) {
    return { packageExhausted: false, debited: false };
  }

  const now = new Date();
  if (pkg.expiresAt !== null && pkg.expiresAt.getTime() < now.getTime()) {
    pkg.status = 'expired';
    await manager.save(pkg);
    return { packageExhausted: false, debited: false };
  }

  if (pkg.remainingSessions <= 0) {
    pkg.status = 'exhausted';
    await manager.save(pkg);
    return { packageExhausted: true, debited: false };
  }

  const existing = await manager.findOne(SessionPackageDebitEntity, {
    where: { packageId: pkg.id, sessionId: params.sessionId },
  });
  if (existing) {
    return {
      packageExhausted: pkg.status === 'exhausted',
      debited: false,
    };
  }

  pkg.remainingSessions -= 1;
  if (pkg.remainingSessions === 0) {
    pkg.status = 'exhausted';
  }

  await manager.save(pkg);
  await manager.save(
    manager.create(SessionPackageDebitEntity, {
      packageId: pkg.id,
      sessionId: params.sessionId,
      delta: -1,
      reason,
    }),
  );

  return {
    packageExhausted: pkg.status === 'exhausted',
    debited: true,
  };
}
