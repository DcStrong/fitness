import { Module } from '@nestjs/common';
import { CalendarBookingService } from '../calendar/calendar-booking.service';
import { ChatModule } from '../chat/chat.module';
import { DatabaseModule } from '../database/database.module';
import { SessionLifecycleService } from './session-lifecycle.service';
import { SessionsController } from './sessions.controller';
import { SessionsService } from './sessions.service';
import { BookingRequestsModule } from '../booking-requests/booking-requests.module';
import { PlansModule } from '../plans/plans.module';
import { WorkoutProgramsModule } from '../workout-programs/workout-programs.module';

@Module({
  imports: [DatabaseModule, ChatModule, BookingRequestsModule, PlansModule, WorkoutProgramsModule],
  controllers: [SessionsController],
  providers: [
    SessionsService,
    SessionLifecycleService,
    CalendarBookingService,
  ],
})
export class SessionsModule {}
