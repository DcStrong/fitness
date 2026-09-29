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
import { AssignPlanDto } from './dto/assign-plan.dto';
import { AssignPlansBatchDto } from './dto/assign-plans-batch.dto';
import { CreatePlanDto } from './dto/create-plan.dto';
import { PatchPlanLoadsDto } from './dto/patch-plan-loads.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';
import type { PlanExerciseInput } from './interface';
import { PlansService } from './plans.service';

type RequestWithUser = Request & { user: AuthUserPayload };

@Controller('plans')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class PlansController {
  constructor(private readonly plansService: PlansService) {}

  /**
   *
   */
  @Post()
  @RequirePermissions(PERMISSIONS.PLANS_CREATE)
  async create(@Req() req: RequestWithUser, @Body() dto: CreatePlanDto) {
    return this.plansService.create(req.user.id, {
      title: dto.title,
      ...dto.body !== undefined ? { body: dto.body } : {},
      ...dto.notes !== undefined ? { notes: dto.notes } : {},
      ...dto.goal !== undefined ? { goal: dto.goal } : {},
      ...dto.tagIds !== undefined ? { tagIds: dto.tagIds } : {},
      ...dto.exercises !== undefined
        ? { exercises: this.toExerciseInputs(dto.exercises) }
        : {},
      ...dto.assignedStudentId !== undefined
        ? { assignedStudentId: dto.assignedStudentId }
        : {},
    });
  }

  /**
   *
   */
  @Get()
  @UseGuards(JwtAuthGuard)
  async listOwn(
    @Req() req: RequestWithUser,
    @Query('kind') kind?: string,
    @Query('studentId') studentId?: string,
    @Query('tagId', new ParseUUIDPipe({ optional: true })) tagId?: string,
  ) {
    return this.plansService.list({
      actorId: req.user.id,
      permissions: req.user.permissions ?? [],
      ...kind !== undefined ? { kind } : {},
      ...studentId !== undefined ? { studentId } : {},
      ...tagId !== undefined ? { tagId } : {},
    });
  }

  /**
   *
   */
  @Get('visible')
  @RequirePermissions(PERMISSIONS.PLANS_READ_VISIBLE)
  async listVisible(@Req() req: RequestWithUser) {
    return this.plansService.listVisible(req.user.id);
  }

  /**
   *
   */
  @Post('assign-batch')
  @RequirePermissions(PERMISSIONS.PLANS_CREATE)
  async assignBatch(
    @Req() req: RequestWithUser,
    @Body() dto: AssignPlansBatchDto,
  ) {
    return this.plansService.assignBatch(req.user.id, {
      studentId: dto.studentId,
      planIds: dto.planIds,
    });
  }

  /**
   *
   */
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getOne(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.plansService.getById(req.user.id, id);
  }

  /**
   *
   */
  @Post(':id/clone')
  @RequirePermissions(PERMISSIONS.PLANS_CREATE)
  async clone(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.plansService.cloneCatalog(req.user.id, id);
  }

  /**
   *
   */
  @Post(':id/assign')
  @RequirePermissions(PERMISSIONS.PLANS_CREATE)
  async assign(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignPlanDto,
  ) {
    return this.plansService.assign(req.user.id, {
      planId: id,
      ...dto.studentIds !== undefined ? { studentIds: dto.studentIds } : {},
      ...dto.tagIds !== undefined ? { tagIds: dto.tagIds } : {},
    });
  }

  /**
   *
   */
  @Patch(':id/loads')
  @RequirePermissions(PERMISSIONS.PLANS_UPDATE_OWN)
  async updateLoads(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: PatchPlanLoadsDto,
  ) {
    return this.plansService.updateLoads(req.user.id, {
      planId: id,
      items: dto.items,
    });
  }

  /**
   *
   */
  @Patch(':id')
  @RequirePermissions(PERMISSIONS.PLANS_UPDATE_OWN)
  async update(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePlanDto,
  ) {
    return this.plansService.update(req.user.id, {
      planId: id,
      ...dto.title !== undefined ? { title: dto.title } : {},
      ...dto.body !== undefined ? { body: dto.body } : {},
      ...dto.notes !== undefined ? { notes: dto.notes } : {},
      ...dto.goal !== undefined ? { goal: dto.goal } : {},
      ...dto.tagIds !== undefined ? { tagIds: dto.tagIds } : {},
      ...dto.exercises !== undefined
        ? { exercises: this.toExerciseInputs(dto.exercises) }
        : {},
    });
  }

  /**
   *
   */
  @Delete(':id')
  @HttpCode(204)
  @RequirePermissions(PERMISSIONS.PLANS_DELETE_OWN)
  async delete(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    await this.plansService.deleteOwn(req.user.id, id);
  }

  /**
   *
   */
  private toExerciseInputs(
    exercises: CreatePlanDto['exercises'],
  ): PlanExerciseInput[] {
    return (exercises ?? []).map(item => ({
      exerciseId: item.exerciseId,
      ...item.restSeconds !== undefined ? { restSeconds: item.restSeconds } : {},
      ...item.notes !== undefined ? { notes: item.notes } : {},
      ...item.sets !== undefined
        ? {
            sets: item.sets.map(set => ({
              ...set.reps !== undefined ? { reps: set.reps } : {},
              ...set.weightKg !== undefined ? { weightKg: set.weightKg } : {},
              ...set.durationSeconds !== undefined
                ? { durationSeconds: set.durationSeconds }
                : {},
            })),
          }
        : {},
    }));
  }
}
