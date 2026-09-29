import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
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
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { AvailabilityService } from './availability.service';
import { CreateScheduleSlotDto } from './dto/create-schedule-slot.dto';
import { ReplaceAvailabilityExceptionsDto } from './dto/replace-availability-exceptions.dto';
import { UpsertAvailabilityTemplateDto } from './dto/upsert-availability-template.dto';
import { UpsertScheduleSettingsDto } from './dto/upsert-schedule-settings.dto';
import type { WeekdayNumber } from './interface/availability.types';
import type { ListSlotsQuery } from './interface/list-slots.params';
import { SchedulesService } from './schedules.service';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload };

@Controller('schedule')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class SchedulesController {
  constructor(
    private readonly schedulesService: SchedulesService,
    private readonly availabilityService: AvailabilityService,
    private readonly links: CoachStudentLinkRepository,
  ) {}

  /**
   *
   */
  @Post('slots')
  @RequirePermissions(PERMISSIONS.SCHEDULES_CREATE)
  async create(@Req() req: RequestWithUser, @Body() dto: CreateScheduleSlotDto) {
    return this.schedulesService.createSlot({
      coachId: req.user.id,
      startsAt: dto.startsAt,
      endsAt: dto.endsAt,
      ...dto.mode !== undefined ? { mode: dto.mode } : {},
    });
  }

  /**
   *
   */
  @Get('slots')
  @RequirePermissions(PERMISSIONS.SCHEDULES_READ_OWN)
  async listOwn(
    @Req() req: RequestWithUser,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const query: ListSlotsQuery = {};
    if (from) {
      query.from = from;
    }
    if (to) {
      query.to = to;
    }

    return this.schedulesService.listOwn(req.user.id, query);
  }

  /**
   *
   */
  @Delete('slots/:id')
  @RequirePermissions(PERMISSIONS.SCHEDULES_DELETE_OWN)
  async remove(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.schedulesService.deleteOwnOpen(req.user.id, id);
  }

  /**
   *
   */
  @Get('coaches/:coachId/slots')
  @RequirePermissions(PERMISSIONS.SCHEDULES_READ_LINKED)
  async listLinkedCoach(
    @Req() req: RequestWithUser,
    @Param('coachId', ParseUUIDPipe) coachId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const link = await this.links.findByPair(coachId, req.user.id);
    if (!link) {
      throw new ForbiddenException('Not linked to this coach');
    }
    const query: ListSlotsQuery = {};
    if (from) {
      query.from = from;
    }
    if (to) {
      query.to = to;
    }

    return this.schedulesService.listOpenForLinkedCoach(coachId, query);
  }

  /**
   *
   */
  @Get('availability/settings')
  @RequirePermissions(PERMISSIONS.SCHEDULES_READ_OWN)
  async getSettings(@Req() req: RequestWithUser) {
    return this.availabilityService.getSettings(req.user.id);
  }

  /**
   *
   */
  @Put('availability/settings')
  @RequirePermissions(PERMISSIONS.SCHEDULES_CREATE)
  async putSettings(
    @Req() req: RequestWithUser,
    @Body() dto: UpsertScheduleSettingsDto,
  ) {
    return this.availabilityService.upsertSettings({
      coachId: req.user.id,
      timezone: dto.timezone,
      defaultDurationMinutes: dto.defaultDurationMinutes,
      breakMinutes: dto.breakMinutes,
      horizonWeeks: dto.horizonWeeks,
      onlineDurationMinutes: dto.onlineDurationMinutes ?? null,
      offlineDurationMinutes: dto.offlineDurationMinutes ?? null,
      defaultMode: dto.defaultMode,
    });
  }

  /**
   *
   */
  @Get('availability/template')
  @RequirePermissions(PERMISSIONS.SCHEDULES_READ_OWN)
  async getTemplate(@Req() req: RequestWithUser) {
    return this.availabilityService.getTemplate(req.user.id);
  }

  /**
   *
   */
  @Put('availability/template')
  @RequirePermissions(PERMISSIONS.SCHEDULES_CREATE)
  async putTemplate(
    @Req() req: RequestWithUser,
    @Body() dto: UpsertAvailabilityTemplateDto,
  ) {
    return this.availabilityService.upsertTemplate({
      coachId: req.user.id,
      windows: dto.windows.map(window => ({
        dayOfWeek: window.dayOfWeek as WeekdayNumber,
        startMinute: window.startMinute,
        endMinute: window.endMinute,
        mode: window.mode ?? null,
      })),
    });
  }

  /**
   *
   */
  @Get('availability/exceptions')
  @RequirePermissions(PERMISSIONS.SCHEDULES_READ_OWN)
  async getExceptions(@Req() req: RequestWithUser) {
    return this.availabilityService.listExceptions(req.user.id);
  }

  /**
   *
   */
  @Put('availability/exceptions')
  @RequirePermissions(PERMISSIONS.SCHEDULES_CREATE)
  async putExceptions(
    @Req() req: RequestWithUser,
    @Body() dto: ReplaceAvailabilityExceptionsDto,
  ) {
    return this.availabilityService.replaceExceptions({
      coachId: req.user.id,
      exceptions: dto.exceptions.map(item => ({
        localDate: item.localDate,
        type: item.type,
        windows:
          item.type === 'closed'
            ? null
            : (item.windows ?? []).map(window => ({
                startMinute: window.startMinute,
                endMinute: window.endMinute,
                mode: window.mode ?? null,
              })),
      })),
    });
  }

  /**
   *
   */
  @Get('availability/preview')
  @RequirePermissions(PERMISSIONS.SCHEDULES_READ_OWN)
  async preview(
    @Req() req: RequestWithUser,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    const candidates = await this.availabilityService.preview({
      coachId: req.user.id,
      from: new Date(from),
      to: new Date(to),
    });

    return candidates.map(candidate => ({
      startsAt: candidate.startsAt.toISOString(),
      endsAt: candidate.endsAt.toISOString(),
      mode: candidate.mode,
    }));
  }

  /**
   *
   */
  @Post('availability/generate')
  @RequirePermissions(PERMISSIONS.SCHEDULES_CREATE)
  async generate(@Req() req: RequestWithUser) {
    return this.availabilityService.generate({ coachId: req.user.id });
  }
}
