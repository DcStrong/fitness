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
import { AcceptInvitationDto } from './dto/accept-invitation.dto';
import { InvitationsService } from './invitations.service';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller()
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class InvitationsController {
  constructor(private readonly invitationsService: InvitationsService) {}

  /**
   *
   */
  @Post('invitations')
  @RequirePermissions(PERMISSIONS.INVITATIONS_CREATE)
  async create(@Req() req: RequestWithUser) {
    return this.invitationsService.create(req.user.id);
  }

  /**
   *
   */
  @Get('invitations')
  @RequirePermissions(PERMISSIONS.INVITATIONS_READ_OWN)
  async list(@Req() req: RequestWithUser) {
    return this.invitationsService.listOwn(req.user.id);
  }

  /**
   *
   */
  @Post('invitations/accept')
  @RequirePermissions(PERMISSIONS.INVITATIONS_ACCEPT)
  async accept(@Req() req: RequestWithUser, @Body() dto: AcceptInvitationDto) {
    return this.invitationsService.accept(req.user.id, dto.token);
  }

  /**
   *
   */
  @Post('invitations/:id/revoke')
  @RequirePermissions(PERMISSIONS.INVITATIONS_REVOKE)
  async revoke(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.invitationsService.revoke(req.user.id, id);
  }

  /**
   *
   */
  @Get('relationships/me')
  @RequirePermissions(PERMISSIONS.RELATIONSHIPS_READ_OWN)
  async relationships(@Req() req: RequestWithUser) {
    return this.invitationsService.listRelationships(req.user.id);
  }
}
