import { Module } from '@nestjs/common';
import { ChatModule } from '../chat/chat.module';
import { DatabaseModule } from '../database/database.module';
import { BookingRequestsController } from './booking-requests.controller';
import { BookingRequestsService } from './booking-requests.service';

@Module({
  imports: [DatabaseModule, ChatModule],
  controllers: [BookingRequestsController],
  providers: [BookingRequestsService],
  exports: [BookingRequestsService],
})
export class BookingRequestsModule {}
