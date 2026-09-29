import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { SessionPackagesController } from './session-packages.controller';
import { SessionPackagesService } from './session-packages.service';

@Module({
  imports: [DatabaseModule],
  controllers: [SessionPackagesController],
  providers: [SessionPackagesService],
  exports: [SessionPackagesService],
})
export class SessionPackagesModule {}
