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
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AttachGymDto, GymSuggestionsQueryDto } from './dto/gym-request.dto';
import { GymResponseDto } from './dto/gym-response.dto';
import type { GymActor } from './interface';
import { GymsService } from './gyms.service';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@RequirePermissions(PERMISSIONS.PROFILES_UPDATE_OWN)
export class GymsController {
  constructor(private readonly gyms: GymsService) {}

  /**
   *
   */
  @Get('profiles/me/gyms')
  async list(@Req() req: RequestWithUser) {
    return (await this.gyms.listOwn(this.actor(req))).map(
      gym => new GymResponseDto(gym),
    );
  }

  /**
   *
   */
  @Post('profiles/me/gyms')
  async attach(@Req() req: RequestWithUser, @Body() dto: AttachGymDto) {
    return new GymResponseDto(await this.gyms.attach(this.actor(req), dto));
  }

  /**
   *
   */
  @Delete('profiles/me/gyms/:gymId')
  @HttpCode(204)
  async detach(
    @Req() req: RequestWithUser,
    @Param('gymId', ParseUUIDPipe) gymId: string,
  ) {
    await this.gyms.detach(this.actor(req), gymId);
  }

  /**
   *
   */
  @Get('gyms/suggestions')
  async suggestions(
    @Req() req: RequestWithUser,
    @Query() query: GymSuggestionsQueryDto,
  ) {
    return (await this.gyms.suggest(this.actor(req), query)).map(
      gym => new GymResponseDto(gym),
    );
  }

  /**
   *
   */
  private actor(req: RequestWithUser): GymActor {
    return { id: req.user.id, roles: req.user.roles ?? [] };
  }
}
