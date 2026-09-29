import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
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
import { AssignTagDto } from './dto/assign-tag.dto';
import { CreateTagDto } from './dto/create-tag.dto';
import { TagsService } from './tags.service';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller('tags')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class TagsController {
  constructor(private readonly tagsService: TagsService) {}

  /**
   *
   */
  @Post()
  @RequirePermissions(PERMISSIONS.TAGS_CREATE)
  async create(@Req() req: RequestWithUser, @Body() dto: CreateTagDto) {
    return this.tagsService.create(req.user.id, { name: dto.name });
  }

  /**
   *
   */
  @Get()
  @RequirePermissions(PERMISSIONS.TAGS_READ_OWN)
  async list(@Req() req: RequestWithUser) {
    const canCreate = (req.user.permissions ?? []).includes(
      PERMISSIONS.TAGS_CREATE,
    );

    return this.tagsService.listForUser(req.user.id, canCreate);
  }

  /**
   *
   */
  @Get(':id')
  @RequirePermissions(PERMISSIONS.TAGS_READ_OWN)
  async getHub(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tagsService.getHub(req.user.id, id);
  }

  /**
   *
   */
  @Delete(':id')
  @HttpCode(204)
  @RequirePermissions(PERMISSIONS.TAGS_DELETE_OWN)
  async delete(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    await this.tagsService.deleteOwn(req.user.id, id);
  }

  /**
   *
   */
  @Post(':id/users')
  @RequirePermissions(PERMISSIONS.TAGS_ASSIGN)
  async assign(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignTagDto,
  ) {
    return this.tagsService.assign(req.user.id, {
      tagId: id,
      userId: dto.userId,
    });
  }

  /**
   *
   */
  @Delete(':id/users/:userId')
  @HttpCode(204)
  @RequirePermissions(PERMISSIONS.TAGS_ASSIGN)
  async unassign(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    await this.tagsService.unassign(req.user.id, id, userId);
  }

  /**
   *
   */
  @Get(':id/users')
  @RequirePermissions(PERMISSIONS.TAGS_ASSIGN)
  async listAssignees(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tagsService.listAssignees(req.user.id, id);
  }
}
