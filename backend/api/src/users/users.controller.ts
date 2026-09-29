import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import type { Request } from 'express';
import { PERMISSIONS } from '../access-control/constants';
import { RequirePermissions } from '../access-control/permissions.decorator';
import { PermissionsGuard } from '../access-control/permissions.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { UsersService } from './users.service';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller('users')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   *
   */
  @Get('me')
  @RequirePermissions(PERMISSIONS.USERS_READ_SELF)
  async me(@Req() req: RequestWithUser) {
    return this.usersService.getMe(req.user.id);
  }
}
