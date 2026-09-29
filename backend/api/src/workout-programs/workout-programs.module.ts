import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { PlansModule } from '../plans/plans.module';
import { WorkoutProgramsController } from './workout-programs.controller';
import { WorkoutProgramsService } from './workout-programs.service';

@Module({
  imports: [DatabaseModule, PlansModule],
  controllers: [WorkoutProgramsController],
  providers: [WorkoutProgramsService],
  exports: [WorkoutProgramsService],
})
export class WorkoutProgramsModule {}
