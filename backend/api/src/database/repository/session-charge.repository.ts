import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type {
  ChargeAggregateRow,
  CreateSessionChargeParams,
  DebtReturns,
  OutstandingAggregateRow,
} from '../../billing/interface';
import { SessionChargeEntity } from '../entity/session-charge.entity';

@Injectable()
export class SessionChargeRepository {
  constructor(
    @InjectRepository(SessionChargeEntity)
    private readonly charges: Repository<SessionChargeEntity>,
  ) {}

  /**
   *
   */
  create(params: CreateSessionChargeParams): SessionChargeEntity {
    return this.charges.create({
      ...params,
      status: 'pending',
      earnedAt: null,
      paidAt: null,
      paymentMethod: null,
      cancelledAt: null,
    });
  }

  /**
   *
   */
  async save(entity: SessionChargeEntity): Promise<SessionChargeEntity> {
    return this.charges.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<SessionChargeEntity | null> {
    return this.charges.findOne({ where: { id } });
  }

  /**
   *
   */
  async findBySessionId(sessionId: string): Promise<SessionChargeEntity | null> {
    return this.charges.findOne({ where: { sessionId } });
  }

  /**
   *
   */
  async aggregateAccrued(
    coachId: string,
    from: Date,
    to: Date,
  ): Promise<ChargeAggregateRow> {
    return this.charges
      .createQueryBuilder('charge')
      .innerJoin('charge.session', 'session')
      .select(
        `COALESCE(SUM(charge.amount_minor), 0)::text`,
        'accruedMinor',
      )
      .addSelect(
        `COUNT(*) FILTER (WHERE session.status = 'completed')::text`,
        'completedCount',
      )
      .addSelect(
        `COUNT(*) FILTER (WHERE session.status = 'no_show')::text`,
        'noShowChargeableCount',
      )
      .where('charge.coach_id = :coachId', { coachId })
      .andWhere('charge.earned_at >= :from', { from })
      .andWhere('charge.earned_at < :to', { to })
      .andWhere('charge.status <> :cancelled', { cancelled: 'cancelled' })
      .getRawOne<ChargeAggregateRow>()
      .then(
        row =>
          row ?? {
            accruedMinor: '0',
            completedCount: '0',
            noShowChargeableCount: '0',
          },
      );
  }

  /**
   *
   */
  async aggregateOutstanding(
    coachId: string,
  ): Promise<OutstandingAggregateRow> {
    return this.charges
      .createQueryBuilder('charge')
      .select(
        `COALESCE(SUM(charge.amount_minor), 0)::text`,
        'outstandingMinor',
      )
      .addSelect('COUNT(*)::text', 'outstandingCount')
      .where('charge.coach_id = :coachId', { coachId })
      .andWhere('charge.status = :pending', { pending: 'pending' })
      .andWhere('charge.earned_at IS NOT NULL')
      .getRawOne<OutstandingAggregateRow>()
      .then(
        row => row ?? { outstandingMinor: '0', outstandingCount: '0' },
      );
  }

  /**
   *
   */
  async findDebts(
    coachId: string,
    studentId?: string,
  ): Promise<DebtReturns[]> {
    const qb = this.charges
      .createQueryBuilder('charge')
      .leftJoin('charge.student', 'student')
      .leftJoin(
        'user_profiles',
        'profile',
        'profile.user_id = charge.student_id',
      )
      .select('charge.id', 'chargeId')
      .addSelect('charge.session_id', 'sessionId')
      .addSelect('charge.student_id', 'studentId')
      .addSelect('student.email', 'studentEmail')
      .addSelect('profile.display_name', 'studentDisplayName')
      .addSelect('charge.amount_minor::text', 'amountMinor')
      .addSelect('charge.currency', 'currency')
      .addSelect('charge.earned_at', 'earnedAt')
      .where('charge.coach_id = :coachId', { coachId })
      .andWhere('charge.status = :pending', { pending: 'pending' })
      .andWhere('charge.earned_at IS NOT NULL')
      .orderBy('charge.earned_at', 'ASC');

    if (studentId) {
      qb.andWhere('charge.student_id = :studentId', { studentId });
    }

    const rows = await qb.getRawMany<{
      chargeId: string;
      sessionId: string;
      studentId: string;
      studentEmail: string | null;
      studentDisplayName: string | null;
      amountMinor: string;
      currency: 'RUB';
      earnedAt: Date;
    }>();

    return rows.map(row => ({
      ...row,
      earnedAt: row.earnedAt.toISOString(),
    }));
  }
}
