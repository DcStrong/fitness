import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { BookingRequestsController } from './booking-requests.controller';
import { BookingRequestsService } from './booking-requests.service';

@Module({
  imports: [DatabaseModule],
  controllers: [BookingRequestsController],
  providers: [BookingRequestsService],
  exports: [BookingRequestsService],
})
export class BookingRequestsModule {}
