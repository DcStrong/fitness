import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { AvailabilityService } from './availability.service';
import { SchedulesController } from './schedules.controller';
import { SchedulesService } from './schedules.service';
import { BookingRequestsModule } from '../booking-requests/booking-requests.module';

@Module({
  imports: [DatabaseModule, BookingRequestsModule],
  controllers: [SchedulesController],
  providers: [SchedulesService, AvailabilityService],
  exports: [SchedulesService, AvailabilityService],
})
export class SchedulesModule {}
