import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { PERMISSIONS } from '../access-control/constants';
import { RequirePermissions } from '../access-control/permissions.decorator';
import { PermissionsGuard } from '../access-control/permissions.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { BillingService } from './billing.service';
import { MarkChargePaidDto } from './dto/mark-charge-paid.dto';
import { RecordExpenseDto } from './dto/record-expense.dto';
import { ReverseLedgerEntryDto } from './dto/reverse-ledger-entry.dto';
import { UpdateFinanceSettingsDto } from './dto/update-finance-settings.dto';
import type {
  FinanceLedgerEntryType,
  ListDebtsParams,
  ListLedgerParams,
} from './interface';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller('finance')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class BillingController {
  constructor(private readonly billing: BillingService) {}

  /**
   *
   */
  @Get('settings')
  @RequirePermissions(PERMISSIONS.FINANCE_MANAGE_SETTINGS)
  async getSettings(@Req() req: RequestWithUser) {
    return this.billing.getSettings(this.actor(req));
  }

  /**
   *
   */
  @Put('settings')
  @RequirePermissions(PERMISSIONS.FINANCE_MANAGE_SETTINGS)
  async updateSettings(
    @Req() req: RequestWithUser,
    @Body() dto: UpdateFinanceSettingsDto,
  ) {
    return this.billing.updateSettings(this.actor(req), {
      defaultSessionPriceMinor: dto.defaultSessionPriceMinor,
      currency: dto.currency,
    });
  }

  /**
   *
   */
  @Get('summary')
  @RequirePermissions(PERMISSIONS.FINANCE_READ_OWN)
  async summary(
    @Req() req: RequestWithUser,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.billing.getSummary(this.actor(req), { from, to });
  }

  /**
   *
   */
  @Get('ledger')
  @RequirePermissions(PERMISSIONS.FINANCE_READ_OWN)
  async ledger(
    @Req() req: RequestWithUser,
    @Query('from') from: string,
    @Query('to') to: string,
    @Query('type') type?: FinanceLedgerEntryType,
    @Query('studentId') studentId?: string,
  ) {
    const params: ListLedgerParams = { from, to };
    if (type) {
params.type = type;
}
    if (studentId) {
params.studentId = studentId;
}

    return this.billing.listLedger(this.actor(req), params);
  }

  /**
   *
   */
  @Get('debts')
  @RequirePermissions(PERMISSIONS.FINANCE_READ_OWN)
  async debts(
    @Req() req: RequestWithUser,
    @Query('studentId') studentId?: string,
  ) {
    const params: ListDebtsParams = {};
    if (studentId) {
params.studentId = studentId;
}

    return this.billing.listDebts(this.actor(req), params);
  }

  /**
   *
   */
  @Post('charges/:id/mark-paid')
  @RequirePermissions(PERMISSIONS.FINANCE_MARK_PAID)
  async markPaid(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: MarkChargePaidDto,
  ) {
    return this.billing.markPaid(this.actor(req), {
      chargeId: id,
      paymentMethod: dto.paymentMethod,
      ...dto.paidAt ? { paidAt: dto.paidAt } : {},
    });
  }

  /**
   *
   */
  @Post('expenses')
  @RequirePermissions(PERMISSIONS.FINANCE_RECORD_EXPENSE)
  async recordExpense(
    @Req() req: RequestWithUser,
    @Body() dto: RecordExpenseDto,
  ) {
    return this.billing.recordExpense(this.actor(req), {
      amountMinor: dto.amountMinor,
      ...dto.category ? { category: dto.category } : {},
      ...dto.note ? { note: dto.note } : {},
      ...dto.occurredAt ? { occurredAt: dto.occurredAt } : {},
    });
  }

  /**
   *
   */
  @Post('ledger/:id/reverse')
  @RequirePermissions(PERMISSIONS.FINANCE_ADJUST_OWN)
  async reverse(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReverseLedgerEntryDto,
  ) {
    return this.billing.reverseEntry(this.actor(req), {
      entryId: id,
      ...dto.note ? { note: dto.note } : {},
      ...dto.occurredAt ? { occurredAt: dto.occurredAt } : {},
    });
  }

  /**
   *
   */
  private actor(req: RequestWithUser) {
    return {
      id: req.user.id,
      permissions: req.user.permissions ?? [],
    };
  }
}
