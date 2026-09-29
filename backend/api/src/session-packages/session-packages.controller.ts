import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { PERMISSIONS } from '../access-control/constants';
import { RequirePermissions } from '../access-control/permissions.decorator';
import { PermissionsGuard } from '../access-control/permissions.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { CreateSessionPackageDto } from './dto/create-session-package.dto';
import { ExtendSessionPackageDto } from './dto/extend-session-package.dto';
import { SessionPackagesService } from './session-packages.service';

type RequestWithUser = Request & { user: AuthUserPayload };

@Controller('session-packages')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class SessionPackagesController {
  constructor(private readonly service: SessionPackagesService) {}

  @Post()
  @RequirePermissions(PERMISSIONS.PACKAGES_MANAGE)
  async create(
    @Req() req: RequestWithUser,
    @Body() dto: CreateSessionPackageDto,
  ) {
    return this.service.create({
      coachId: req.user.id,
      studentId: dto.studentId,
      totalSessions: dto.totalSessions,
      ...dto.expiresAt !== undefined
        ? { expiresAt: new Date(dto.expiresAt) }
        : {},
    });
  }

  @Get()
  @RequirePermissions(PERMISSIONS.PACKAGES_READ_OWN)
  async list(@Req() req: RequestWithUser) {
    return this.service.list({ actorId: req.user.id });
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.PACKAGES_READ_OWN)
  async get(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.get({ actorId: req.user.id, packageId: id });
  }

  @Post(':id/extend')
  @RequirePermissions(PERMISSIONS.PACKAGES_MANAGE)
  async extend(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ExtendSessionPackageDto,
  ) {
    return this.service.extend({
      coachId: req.user.id,
      packageId: id,
      addSessions: dto.addSessions,
      ...dto.expiresAt !== undefined
        ? { expiresAt: new Date(dto.expiresAt) }
        : {},
    });
  }

  @Post(':id/archive')
  @RequirePermissions(PERMISSIONS.PACKAGES_MANAGE)
  async archive(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.archive({
      coachId: req.user.id,
      packageId: id,
    });
  }
}
