import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
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
import { CreateRecurringBookingDto } from './dto/create-recurring-booking.dto';
import { ResolveOccurrenceDto } from './dto/resolve-occurrence.dto';
import type { WeekdayNumber } from './interface/recurring-booking.types';
import { RecurringBookingsService } from './recurring-bookings.service';

type RequestWithUser = Request & { user: AuthUserPayload };

@Controller('recurring-bookings')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class RecurringBookingsController {
  constructor(private readonly service: RecurringBookingsService) {}

  @Post()
  @RequirePermissions(PERMISSIONS.SESSIONS_BOOK_FOR_STUDENT)
  async create(
    @Req() req: RequestWithUser,
    @Body() dto: CreateRecurringBookingDto,
  ) {
    return this.service.create({
      coachId: req.user.id,
      studentId: dto.studentId,
      weekdays: dto.weekdays as WeekdayNumber[],
      startMinute: dto.startMinute,
      mode: dto.mode,
      ...dto.horizonWeeksOverride !== undefined
        ? { horizonWeeksOverride: dto.horizonWeeksOverride }
        : {},
    });
  }

  @Get()
  @RequirePermissions(PERMISSIONS.SESSIONS_READ_OWN)
  async list(
    @Req() req: RequestWithUser,
    @Query('status') status?: string,
  ) {
    const normalized =
      status === 'cancelled' || status === 'all' || status === 'active'
        ? status
        : 'active';
    return this.service.listForCoach(req.user.id, normalized);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.SESSIONS_READ_OWN)
  async get(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.getForCoach(req.user.id, id);
  }

  @Post(':id/sync')
  @RequirePermissions(PERMISSIONS.SESSIONS_BOOK_FOR_STUDENT)
  async sync(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.sync({
      coachId: req.user.id,
      recurringBookingId: id,
    });
  }

  @Post(':id/cancel')
  @RequirePermissions(PERMISSIONS.SESSIONS_BOOK_FOR_STUDENT)
  async cancel(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.cancel(req.user.id, id);
  }

  @Post(':id/restore')
  @RequirePermissions(PERMISSIONS.SESSIONS_BOOK_FOR_STUDENT)
  async restore(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.restore(req.user.id, id);
  }

  @Delete(':id')
  @HttpCode(204)
  @RequirePermissions(PERMISSIONS.SESSIONS_BOOK_FOR_STUDENT)
  async remove(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    await this.service.deleteCancelled(req.user.id, id);
  }

  @Post(':id/occurrences/:localDate/resolve')
  @RequirePermissions(PERMISSIONS.SESSIONS_BOOK_FOR_STUDENT)
  async resolve(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('localDate') localDate: string,
    @Body() dto: ResolveOccurrenceDto,
  ) {
    return this.service.resolveOccurrence({
      coachId: req.user.id,
      recurringBookingId: id,
      localDate,
      type: dto.type,
      ...dto.newStartMinute !== undefined
        ? { newStartMinute: dto.newStartMinute }
        : {},
      ...dto.newLocalDate !== undefined
        ? { newLocalDate: dto.newLocalDate }
        : {},
    });
  }
}
