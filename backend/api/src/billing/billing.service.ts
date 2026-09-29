import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { FinanceLedgerEntryEntity } from '../database/entity/finance-ledger-entry.entity';
import { SessionChargeEntity } from '../database/entity/session-charge.entity';
import { CoachFinanceSettingsRepository } from '../database/repository/coach-finance-settings.repository';
import { FinanceLedgerRepository } from '../database/repository/finance-ledger.repository';
import { SessionChargeRepository } from '../database/repository/session-charge.repository';
import {
  calculateNetMinor,
  parseFinancePeriod,
  reversalAmountMinor,
} from './billing-calculations';
import type {
  DebtReturns,
  FinanceActor,
  FinanceLedgerEntryReturns,
  FinancePeriodParams,
  FinanceSettingsReturns,
  FinanceSummaryReturns,
  ListDebtsParams,
  ListLedgerParams,
  MarkChargePaidParams,
  ParsedFinancePeriod,
  RecordExpenseParams,
  ReverseLedgerEntryParams,
  SessionChargeReturns,
  UpdateFinanceSettingsParams,
} from './interface';

@Injectable()
export class BillingService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly settings: CoachFinanceSettingsRepository,
    private readonly charges: SessionChargeRepository,
    private readonly ledger: FinanceLedgerRepository,
  ) {}

  /**
   *
   */
  async getSettings(actor: FinanceActor): Promise<FinanceSettingsReturns> {
    this.requirePermission(actor, 'finance:manage_settings');
    const settings = await this.settings.findByCoachId(actor.id);
    if (!settings) {
      throw new NotFoundException('Finance settings are not configured');
    }

    return {
      defaultSessionPriceMinor: settings.defaultSessionPriceMinor,
      currency: settings.currency,
      updatedAt: settings.updatedAt.toISOString(),
    };
  }

  /**
   *
   */
  async updateSettings(
    actor: FinanceActor,
    params: UpdateFinanceSettingsParams,
  ): Promise<FinanceSettingsReturns> {
    this.requirePermission(actor, 'finance:manage_settings');
    const saved = await this.settings.save({
      coachId: actor.id,
      defaultSessionPriceMinor: params.defaultSessionPriceMinor,
      currency: params.currency,
    });

    return {
      defaultSessionPriceMinor: saved.defaultSessionPriceMinor,
      currency: saved.currency,
      updatedAt: saved.updatedAt.toISOString(),
    };
  }

  /**
   *
   */
  async markPaid(
    actor: FinanceActor,
    params: MarkChargePaidParams,
  ): Promise<SessionChargeReturns> {
    this.requirePermission(actor, 'finance:mark_paid');
    const paidAt = this.parseOptionalDate(params.paidAt) ?? new Date();

    const saved = await this.dataSource.transaction(async manager => {
      const charge = await manager.findOne(SessionChargeEntity, {
        where: { id: params.chargeId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!charge) {
        throw new NotFoundException('Session charge not found');
      }
      if (charge.coachId !== actor.id) {
        throw new ForbiddenException('Session charge does not belong to coach');
      }
      if (charge.status !== 'pending') {
        throw new ConflictException('Session charge is already finalized');
      }
      if (!charge.earnedAt) {
        throw new ConflictException('Unearned session charge cannot be paid');
      }

      charge.status = 'paid';
      charge.paidAt = paidAt;
      charge.paymentMethod = params.paymentMethod;
      const updated = await manager.save(charge);

      const income = manager.create(FinanceLedgerEntryEntity, {
        coachId: charge.coachId,
        type: 'income',
        amountMinor: charge.amountMinor,
        currency: charge.currency,
        sourceType: 'session_charge',
        sourceId: charge.id,
        category: null,
        note: null,
        occurredAt: paidAt,
        reversesEntryId: null,
      });
      await manager.save(income);

      return updated;
    });

    return this.toChargeReturns(saved);
  }

  /**
   *
   */
  async recordExpense(
    actor: FinanceActor,
    params: RecordExpenseParams,
  ): Promise<FinanceLedgerEntryReturns> {
    this.requirePermission(actor, 'finance:record_expense');
    const entry = this.ledger.create({
      coachId: actor.id,
      type: 'expense',
      amountMinor: params.amountMinor,
      currency: 'RUB',
      sourceType: 'manual',
      sourceId: null,
      category: params.category ?? null,
      note: params.note ?? null,
      occurredAt: this.parseOptionalDate(params.occurredAt) ?? new Date(),
      reversesEntryId: null,
    });

    return this.toLedgerReturns(await this.ledger.save(entry));
  }

  /**
   *
   */
  async reverseEntry(
    actor: FinanceActor,
    params: ReverseLedgerEntryParams,
  ): Promise<FinanceLedgerEntryReturns> {
    this.requirePermission(actor, 'finance:adjust_own');
    const occurredAt = this.parseOptionalDate(params.occurredAt) ?? new Date();

    const reversal = await this.dataSource.transaction(async manager => {
      const original = await manager.findOne(FinanceLedgerEntryEntity, {
        where: { id: params.entryId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!original) {
        throw new NotFoundException('Ledger entry not found');
      }
      if (original.coachId !== actor.id) {
        throw new ForbiddenException('Ledger entry does not belong to coach');
      }

      const existing = await manager.findOne(FinanceLedgerEntryEntity, {
        where: { reversesEntryId: original.id },
      });
      if (existing) {
        throw new ConflictException('Ledger entry is already reversed');
      }

      return manager.save(
        manager.create(FinanceLedgerEntryEntity, {
          coachId: actor.id,
          type: 'adjustment',
          amountMinor: reversalAmountMinor(original.type, original.amountMinor),
          currency: original.currency,
          sourceType: 'manual',
          sourceId: null,
          category: 'reversal',
          note: params.note ?? `Reversal of ${original.id}`,
          occurredAt,
          reversesEntryId: original.id,
        }),
      );
    });

    return this.toLedgerReturns(reversal);
  }

  /**
   *
   */
  async getSummary(
    actor: FinanceActor,
    params: FinancePeriodParams,
  ): Promise<FinanceSummaryReturns> {
    this.requirePermission(actor, 'finance:read_own');
    const period = this.parsePeriod(params);
    const [charges, outstanding, ledger] = await Promise.all([
      this.charges.aggregateAccrued(actor.id, period.from, period.to),
      this.charges.aggregateOutstanding(actor.id),
      this.ledger.aggregatePeriod(actor.id, period.from, period.to),
    ]);
    const receivedMinor = ledger.receivedMinor ?? '0';
    const expensesMinor = ledger.expensesMinor ?? '0';
    const adjustmentsMinor = ledger.adjustmentsMinor ?? '0';

    return {
      from: period.from.toISOString(),
      to: period.to.toISOString(),
      currency: 'RUB',
      accruedMinor: charges.accruedMinor ?? '0',
      receivedMinor,
      outstandingMinor: outstanding.outstandingMinor ?? '0',
      expensesMinor,
      adjustmentsMinor,
      netMinor: calculateNetMinor(
        receivedMinor,
        expensesMinor,
        adjustmentsMinor,
      ),
      counts: {
        completed: Number(charges.completedCount),
        noShowChargeable: Number(charges.noShowChargeableCount),
        paid: Number(ledger.paidCount),
        outstanding: Number(outstanding.outstandingCount),
      },
    };
  }

  /**
   *
   */
  async listLedger(
    actor: FinanceActor,
    params: ListLedgerParams,
  ): Promise<FinanceLedgerEntryReturns[]> {
    this.requirePermission(actor, 'finance:read_own');
    const period = this.parsePeriod(params);
    const entries = await this.ledger.findForCoach({
      coachId: actor.id,
      from: period.from,
      to: period.to,
      ...params.type ? { type: params.type } : {},
      ...params.studentId ? { studentId: params.studentId } : {},
    });

    return entries.map(entry => this.toLedgerReturns(entry));
  }

  /**
   *
   */
  async listDebts(
    actor: FinanceActor,
    params: ListDebtsParams,
  ): Promise<DebtReturns[]> {
    this.requirePermission(actor, 'finance:read_own');

    return this.charges.findDebts(actor.id, params.studentId);
  }

  /**
   *
   */
  private requirePermission(actor: FinanceActor, permission: string): void {
    if (!actor.permissions.includes(permission)) {
      throw new ForbiddenException(`Missing ${permission} permission`);
    }
  }

  /**
   *
   */
  private parsePeriod(params: FinancePeriodParams): ParsedFinancePeriod {
    const period = parseFinancePeriod(params.from, params.to);
    if (!period) {
      throw new BadRequestException('to must be after valid ISO from');
    }

    return period;
  }

  /**
   *
   */
  private parseOptionalDate(value?: string): Date | undefined {
    if (!value) {
return undefined;
}
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw new BadRequestException('Invalid ISO datetime');
    }

    return date;
  }

  /**
   *
   */
  private toChargeReturns(charge: SessionChargeEntity): SessionChargeReturns {
    return {
      id: charge.id,
      sessionId: charge.sessionId,
      coachId: charge.coachId,
      studentId: charge.studentId,
      amountMinor: charge.amountMinor,
      currency: charge.currency,
      status: charge.status,
      earnedAt: charge.earnedAt?.toISOString() ?? null,
      paidAt: charge.paidAt?.toISOString() ?? null,
      paymentMethod: charge.paymentMethod,
      cancelledAt: charge.cancelledAt?.toISOString() ?? null,
    };
  }

  /**
   *
   */
  private toLedgerReturns(
    entry: FinanceLedgerEntryEntity,
  ): FinanceLedgerEntryReturns {
    return {
      id: entry.id,
      coachId: entry.coachId,
      type: entry.type,
      amountMinor: entry.amountMinor,
      currency: entry.currency,
      sourceType: entry.sourceType,
      sourceId: entry.sourceId,
      category: entry.category,
      note: entry.note,
      occurredAt: entry.occurredAt.toISOString(),
      reversesEntryId: entry.reversesEntryId,
      createdAt: entry.createdAt.toISOString(),
    };
  }
}
