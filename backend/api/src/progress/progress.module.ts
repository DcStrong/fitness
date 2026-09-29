import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { ProgressController } from './progress.controller';
import { ProgressService } from './progress.service';

@Module({
  imports: [DatabaseModule],
  controllers: [ProgressController],
  providers: [ProgressService],
})
export class ProgressModule {}
