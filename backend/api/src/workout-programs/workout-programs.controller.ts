import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { PERMISSIONS } from '../access-control/constants';
import { RequirePermissions } from '../access-control/permissions.decorator';
import { PermissionsGuard } from '../access-control/permissions.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import type { WeekdayNumber } from '../recurring-bookings/interface/recurring-booking.types';
import {
  ApplyWorkoutProgramDto,
  UpsertWorkoutProgramDto,
} from './dto/upsert-workout-program.dto';
import { WorkoutProgramsService } from './workout-programs.service';

type RequestWithUser = Request & { user: AuthUserPayload };

@Controller('recurring-bookings')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class WorkoutProgramsController {
  constructor(private readonly programs: WorkoutProgramsService) {}

  /**
   *
   */
  @Get(':id/program')
  @RequirePermissions(PERMISSIONS.SESSIONS_READ_OWN)
  async get(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.programs.get(req.user.id, id);
  }

  /**
   *
   */
  @Put(':id/program')
  @RequirePermissions(PERMISSIONS.SESSIONS_BOOK_FOR_STUDENT)
  async upsert(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpsertWorkoutProgramDto,
  ) {
    return this.programs.upsert({
      coachId: req.user.id,
      recurringBookingId: id,
      days: dto.days.map(day => ({
        weekday: day.weekday as WeekdayNumber,
        items: day.items.map(item => ({ templateId: item.templateId })),
      })),
      ...dto.horizonWeeks !== undefined
        ? { horizonWeeks: dto.horizonWeeks }
        : {},
      ...dto.progressionRules !== undefined
        ? {
            progressionRules: dto.progressionRules.map(rule => ({
              exerciseId: rule.exerciseId,
              ...rule.startWeightKg !== undefined
                ? { startWeightKg: rule.startWeightKg }
                : {},
              ...rule.deltaKg !== undefined ? { deltaKg: rule.deltaKg } : {},
              ...rule.incrementKg !== undefined
                ? { incrementKg: rule.incrementKg }
                : {},
              ...rule.holdOnMiss !== undefined
                ? { holdOnMiss: rule.holdOnMiss }
                : {},
            })),
          }
        : {},
    });
  }

  /**
   *
   */
  @Post(':id/program/apply')
  @RequirePermissions(PERMISSIONS.SESSIONS_BOOK_FOR_STUDENT)
  async apply(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ApplyWorkoutProgramDto,
  ) {
    return this.programs.apply({
      coachId: req.user.id,
      recurringBookingId: id,
      ...dto.force !== undefined ? { force: dto.force } : {},
    });
  }
}
