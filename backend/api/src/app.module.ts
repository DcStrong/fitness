import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { join } from 'path';
import { AccessControlModule } from './access-control/access-control.module';
import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './health/health.module';
import { InvitationsModule } from './invitations/invitations.module';
import { PlansModule } from './plans/plans.module';
import { ExercisesModule } from './exercises/exercises.module';
import { SchedulesModule } from './schedules/schedules.module';
import { SessionsModule } from './sessions/sessions.module';
import { ProgressModule } from './progress/progress.module';
import { TagsModule } from './tags/tags.module';
import { UsersModule } from './users/users.module';
import { BillingModule } from './billing/billing.module';
import { SocialModule } from './social/social.module';
import { ScheduleModule } from '@nestjs/schedule';
import { BookingRequestsModule } from './booking-requests/booking-requests.module';
import { RecurringBookingsModule } from './recurring-bookings/recurring-bookings.module';
import { SessionPackagesModule } from './session-packages/session-packages.module';
import { WorkoutProgramsModule } from './workout-programs/workout-programs.module';
import { ChatModule } from './chat/chat.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [
        join(__dirname, '..', '.env'),
        join(__dirname, '..', '..', '.env'),
      ],
    }),
    ScheduleModule.forRoot(),
    DatabaseModule,
    AccessControlModule,
    AuthModule,
    UsersModule,
    InvitationsModule,
    SchedulesModule,
    SessionsModule,
    ProgressModule,
    TagsModule,
    PlansModule,
    ExercisesModule,
    BillingModule,
    SocialModule,
    BookingRequestsModule,
    RecurringBookingsModule,
    SessionPackagesModule,
    WorkoutProgramsModule,
    ChatModule,
    HealthModule,
  ],
})
export class AppModule {}
