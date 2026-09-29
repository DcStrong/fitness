import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
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
import { AssignExercisesDto } from './dto/assign-exercises.dto';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { ReplaceExerciseTagsDto } from './dto/replace-exercise-tags.dto';
import { UnassignExercisesDto } from './dto/unassign-exercises.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
import { ExercisesService } from './exercises.service';

type RequestWithUser = Request & { user: AuthUserPayload };

@Controller('exercises')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ExercisesController {
  constructor(private readonly exercisesService: ExercisesService) {}

  /**
   *
   */
  @Post()
  @RequirePermissions(PERMISSIONS.EXERCISES_MANAGE_OWN)
  async create(@Req() req: RequestWithUser, @Body() dto: CreateExerciseDto) {
    return this.exercisesService.create(req.user.id, {
      name: dto.name,
      kind: dto.kind,
      ...dto.tagIds !== undefined ? { tagIds: dto.tagIds } : {},
    });
  }

  /**
   *
   */
  @Get()
  @RequirePermissions(PERMISSIONS.EXERCISES_READ_OWN)
  async list(
    @Req() req: RequestWithUser,
    @Query('tagId', new ParseUUIDPipe({ optional: true })) tagId?: string,
  ) {
    return this.exercisesService.listOwnAndCatalog({
      actorId: req.user.id,
      ...tagId !== undefined ? { tagId } : {},
    });
  }

  /**
   *
   */
  @Get('visible')
  @RequirePermissions(PERMISSIONS.EXERCISES_READ_VISIBLE)
  async listVisible(@Req() req: RequestWithUser) {
    return this.exercisesService.listVisible(req.user.id);
  }

  /**
   *
   */
  @Post('assign')
  @RequirePermissions(PERMISSIONS.EXERCISES_MANAGE_OWN)
  async assign(
    @Req() req: RequestWithUser,
    @Body() dto: AssignExercisesDto,
  ) {
    return this.exercisesService.assign(req.user.id, {
      exerciseIds: dto.exerciseIds,
      ...dto.studentIds !== undefined ? { studentIds: dto.studentIds } : {},
      ...dto.tagIds !== undefined ? { tagIds: dto.tagIds } : {},
    });
  }

  /**
   *
   */
  @Delete('assign')
  @HttpCode(204)
  @RequirePermissions(PERMISSIONS.EXERCISES_MANAGE_OWN)
  async unassign(
    @Req() req: RequestWithUser,
    @Body() dto: UnassignExercisesDto,
  ) {
    await this.exercisesService.unassignMany(
      req.user.id,
      dto.studentId,
      dto.exerciseIds,
    );
  }

  /**
   *
   */
  @Put(':id/tags')
  @RequirePermissions(PERMISSIONS.EXERCISES_MANAGE_OWN)
  async replaceTags(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReplaceExerciseTagsDto,
  ) {
    return this.exercisesService.replaceTags(req.user.id, {
      exerciseId: id,
      tagIds: dto.tagIds,
    });
  }

  /**
   *
   */
  @Patch(':id')
  @RequirePermissions(PERMISSIONS.EXERCISES_MANAGE_OWN)
  async update(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateExerciseDto,
  ) {
    return this.exercisesService.update(req.user.id, {
      exerciseId: id,
      ...dto.name !== undefined ? { name: dto.name } : {},
      ...dto.kind !== undefined ? { kind: dto.kind } : {},
      ...dto.tagIds !== undefined ? { tagIds: dto.tagIds } : {},
    });
  }

  /**
   *
   */
  @Delete(':id')
  @HttpCode(204)
  @RequirePermissions(PERMISSIONS.EXERCISES_MANAGE_OWN)
  async delete(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    await this.exercisesService.deleteOwn(req.user.id, id);
  }
}
