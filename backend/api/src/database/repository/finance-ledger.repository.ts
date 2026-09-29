import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type {
  CreateLedgerEntryParams,
  FindLedgerEntriesParams,
  LedgerAggregateRow,
} from '../../billing/interface';
import { FinanceLedgerEntryEntity } from '../entity/finance-ledger-entry.entity';

@Injectable()
export class FinanceLedgerRepository {
  constructor(
    @InjectRepository(FinanceLedgerEntryEntity)
    private readonly entries: Repository<FinanceLedgerEntryEntity>,
  ) {}

  /**
   *
   */
  create(params: CreateLedgerEntryParams): FinanceLedgerEntryEntity {
    return this.entries.create(params);
  }

  /**
   *
   */
  async save(entity: FinanceLedgerEntryEntity): Promise<FinanceLedgerEntryEntity> {
    return this.entries.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<FinanceLedgerEntryEntity | null> {
    return this.entries.findOne({ where: { id } });
  }

  /**
   *
   */
  async aggregatePeriod(
    coachId: string,
    from: Date,
    to: Date,
  ): Promise<LedgerAggregateRow> {
    return this.entries
      .createQueryBuilder('entry')
      .select(
        `COALESCE(SUM(entry.amount_minor) FILTER (WHERE entry.type = 'income'), 0)::text`,
        'receivedMinor',
      )
      .addSelect(
        `COALESCE(SUM(entry.amount_minor) FILTER (WHERE entry.type = 'expense'), 0)::text`,
        'expensesMinor',
      )
      .addSelect(
        `COALESCE(SUM(entry.amount_minor) FILTER (WHERE entry.type = 'adjustment'), 0)::text`,
        'adjustmentsMinor',
      )
      .addSelect(
        `COUNT(*) FILTER (WHERE entry.type = 'income')::text`,
        'paidCount',
      )
      .where('entry.coach_id = :coachId', { coachId })
      .andWhere('entry.occurred_at >= :from', { from })
      .andWhere('entry.occurred_at < :to', { to })
      .getRawOne<LedgerAggregateRow>()
      .then(
        row =>
          row ?? {
            receivedMinor: '0',
            expensesMinor: '0',
            adjustmentsMinor: '0',
            paidCount: '0',
          },
      );
  }

  /**
   *
   */
  async findForCoach(
    params: FindLedgerEntriesParams,
  ): Promise<FinanceLedgerEntryEntity[]> {
    const qb = this.entries
      .createQueryBuilder('entry')
      .where('entry.coach_id = :coachId', { coachId: params.coachId })
      .andWhere('entry.occurred_at >= :from', { from: params.from })
      .andWhere('entry.occurred_at < :to', { to: params.to })
      .orderBy('entry.occurred_at', 'DESC')
      .addOrderBy('entry.created_at', 'DESC');

    if (params.type) {
      qb.andWhere('entry.type = :type', { type: params.type });
    }
    if (params.studentId) {
      qb.innerJoin(
        'session_charges',
        'charge',
        `entry.source_type = 'session_charge' AND entry.source_id = charge.id`,
      ).andWhere('charge.student_id = :studentId', {
        studentId: params.studentId,
      });
    }

    return qb.getMany();
  }
}
