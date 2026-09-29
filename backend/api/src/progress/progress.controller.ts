import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
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
import { ProgressService } from './progress.service';

type RequestWithUser = Request & { user: AuthUserPayload };

@Controller('students')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ProgressController {
  constructor(private readonly progress: ProgressService) {}

  /**
   *
   */
  @Get(':id/progress')
  @RequirePermissions(PERMISSIONS.SESSIONS_READ_OWN)
  async getProgress(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) studentId: string,
    @Query('exerciseId') exerciseId?: string,
    @Query('coachId') coachId?: string,
  ) {
    return this.progress.getProgress({
      actorId: req.user.id,
      studentId,
      ...exerciseId ? { exerciseId } : {},
      ...coachId ? { coachId } : {},
    });
  }
}
