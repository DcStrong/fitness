import type { SessionFinanceSummary } from '../billing/interface';
import type { SessionModel } from './interface/session.model';
import type { SessionReturns } from './interface/session.returns';

/**
 *
 */
export function sessionPlanTitle(session: SessionModel): string | null {
  return session.studentPlan?.title ?? session.plan?.title ?? null;
}

/**
 *
 */
export function toSessionReturns(
  session: SessionModel,
  nameById: Map<string, string | null>,
  options: { packageExhausted?: boolean; } = {},
): SessionReturns {
  const mapped: SessionReturns = {
    id: session.id,
    coachId: session.coachId,
    studentId: session.studentId,
    scheduleSlotId: session.scheduleSlotId,
    startsAt: session.startsAt.toISOString(),
    endsAt: session.endsAt.toISOString(),
    mode: session.mode,
    status: session.status,
    createdBy: session.createdBy,
    coachEmail: session.coach?.email ?? null,
    studentEmail: session.student?.email ?? null,
    coachDisplayName: nameById.get(session.coachId) ?? null,
    studentDisplayName: nameById.get(session.studentId) ?? null,
    createdAt: session.createdAt.toISOString(),
    finance: toSessionFinance(session),
    studentPlanId: session.studentPlanId ?? null,
    planTitle: sessionPlanTitle(session),
    workouts: session.workouts ?? [],
    recurringBookingId: session.recurringBookingId ?? null,
  };
  if (options.packageExhausted === true) {
    mapped.packageExhausted = true;
  }

  return mapped;
}

/**
 *
 */
function toSessionFinance(session: SessionModel): SessionFinanceSummary {
  const charge = session.charge;
  if (!charge) {
    return { status: 'not_tracked' };
  }

  return {
    chargeId: charge.id,
    status: charge.status,
    amountMinor: charge.amountMinor,
    currency: charge.currency,
    earnedAt: charge.earnedAt?.toISOString() ?? null,
    paidAt: charge.paidAt?.toISOString() ?? null,
    paymentMethod: charge.paymentMethod,
  };
}
