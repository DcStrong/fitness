import { Module } from '@nestjs/common';
import { CalendarBookingService } from '../calendar/calendar-booking.service';
import { ChatModule } from '../chat/chat.module';
import { DatabaseModule } from '../database/database.module';
import { SessionLifecycleService } from '../sessions/session-lifecycle.service';
import { RecurringBookingsController } from './recurring-bookings.controller';
import { RecurringBookingsService } from './recurring-bookings.service';

import { WorkoutProgramsModule } from '../workout-programs/workout-programs.module';

@Module({
  imports: [DatabaseModule, ChatModule, WorkoutProgramsModule],
  controllers: [RecurringBookingsController],
  providers: [
    RecurringBookingsService,
    CalendarBookingService,
    SessionLifecycleService,
  ],
})
export class RecurringBookingsModule {}
