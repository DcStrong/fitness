import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
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
import { BookSessionDto } from './dto/book-session.dto';
import { CompleteSessionDto } from './dto/complete-session.dto';
import { MarkNoShowDto } from './dto/mark-no-show.dto';
import { PatchSessionDto } from './dto/patch-session.dto';
import type { ListSessionsQuery } from './interface/list-sessions.params';
import type { SessionReturns } from './interface/session.returns';
import { SessionLifecycleService } from './session-lifecycle.service';
import { SessionsService } from './sessions.service';
import { CancelSessionDto } from './dto/cancel-session.dto';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller('sessions')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class SessionsController {
  constructor(
    private readonly sessionsService: SessionsService,
    private readonly lifecycle: SessionLifecycleService,
  ) {}

  /**
   * Booking permission is OR of book_self / book_for_student (checked in service),
   * because PermissionsGuard requires ALL listed codes.
   */
  @Post()
  @UseGuards(JwtAuthGuard)
  async book(
    @Req() req: RequestWithUser,
    @Body() dto: BookSessionDto,
  ): Promise<SessionReturns> {
    return this.sessionsService.book(
      {
        id: req.user.id,
        permissions: req.user.permissions ?? [],
        roles: req.user.roles ?? [],
      },
      {
        ...dto.scheduleSlotId !== undefined ? { scheduleSlotId: dto.scheduleSlotId } : {},
        ...dto.startsAt !== undefined ? { startsAt: dto.startsAt } : {},
        ...dto.endsAt !== undefined ? { endsAt: dto.endsAt } : {},
        ...dto.mode !== undefined ? { mode: dto.mode } : {},
        ...dto.studentId !== undefined ? { studentId: dto.studentId } : {},
        ...dto.priceMinor !== undefined ? { priceMinor: dto.priceMinor } : {},
      },
    );
  }

  /**
   *
   */
  @Get()
  @RequirePermissions(PERMISSIONS.SESSIONS_READ_OWN)
  async list(
    @Req() req: RequestWithUser,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('status') status?: string,
    @Query('studentId') studentId?: string,
  ) {
    const query: ListSessionsQuery = {};
    if (from) {
      query.from = from;
    }
    if (to) {
      query.to = to;
    }
    if (status) {
      query.status = status;
    }
    if (studentId) {
      query.studentId = studentId;
    }

    return this.sessionsService.listOwn(req.user.id, query);
  }

  /**
   *
   */
  @Get(':id')
  @RequirePermissions(PERMISSIONS.SESSIONS_READ_OWN)
  async getOne(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<SessionReturns> {
    return this.sessionsService.getById({
      actorId: req.user.id,
      sessionId: id,
    });
  }

  /**
   *
   */
  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  async patch(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: PatchSessionDto,
  ): Promise<SessionReturns> {
    if (dto.workoutLoads !== undefined) {
      return this.sessionsService.patchWorkoutLoads({
        actorId: req.user.id,
        permissions: req.user.permissions ?? [],
        sessionId: id,
        studentPlanId: dto.workoutLoads.studentPlanId,
        items: dto.workoutLoads.items,
      });
    }
    if (dto.workoutPlanIds === undefined && dto.studentPlanId === undefined) {
      return this.sessionsService.getById({
        actorId: req.user.id,
        sessionId: id,
      });
    }

    return this.sessionsService.patchStudentPlan({
      actorId: req.user.id,
      permissions: req.user.permissions ?? [],
      sessionId: id,
      ...dto.studentPlanId !== undefined
        ? { studentPlanId: dto.studentPlanId }
        : {},
      ...dto.workoutPlanIds !== undefined
        ? { workoutPlanIds: dto.workoutPlanIds }
        : {},
    });
  }

  /**
   *
   */
  @Post(':id/complete')
  @RequirePermissions(PERMISSIONS.SESSIONS_COMPLETE)
  async complete(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto?: CompleteSessionDto,
  ) {
    return this.lifecycle.complete(
      { id: req.user.id, permissions: req.user.permissions ?? [] },
      {
        sessionId: id,
        ...dto?.logs !== undefined ? { logs: dto.logs } : {},
      },
    );
  }

  /**
   *
   */
  @Post(':id/cancel')
  @RequirePermissions(PERMISSIONS.SESSIONS_CANCEL)
  async cancel(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CancelSessionDto,
  ) {
    return this.lifecycle.cancel(
      { id: req.user.id, permissions: req.user.permissions ?? [] },
      {
        sessionId: id,
        ...dto.note !== undefined ? { note: dto.note } : {},
      },
    );
  }

  /**
   *
   */
  @Post(':id/no-show')
  @RequirePermissions(PERMISSIONS.SESSIONS_MARK_NO_SHOW)
  async noShow(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: MarkNoShowDto,
  ) {
    return this.lifecycle.markNoShow(
      { id: req.user.id, permissions: req.user.permissions ?? [] },
      {
        sessionId: id,
        charge: dto.charge,
        ...dto.note !== undefined ? { note: dto.note } : {},
      },
    );
  }

  /**
   *
   */
  @Get(':id/history')
  @RequirePermissions(PERMISSIONS.SESSIONS_READ_HISTORY)
  async history(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.lifecycle.listHistory(req.user.id, id);
  }
}
