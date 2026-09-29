import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { resolveDatabaseUrl } from './database-url';
import { entities } from './entity';
import { CoachStudentLinkRepository } from './repository/coach-student-link.repository';
import { InvitationRepository } from './repository/invitation.repository';
import { RefreshTokenRepository } from './repository/refresh-token.repository';
import { RoleRepository } from './repository/role.repository';
import { ScheduleSlotRepository } from './repository/schedule-slot.repository';
import { SessionHistoryEventRepository } from './repository/session-history-event.repository';
import { SessionRepository } from './repository/session.repository';
import { SessionSetLogRepository } from './repository/session-set-log.repository';
import { TagRepository } from './repository/tag.repository';
import { TrainingPlanRepository } from './repository/training-plan.repository';
import { TrainingPlanTagRepository } from './repository/training-plan-tag.repository';
import { ExerciseRepository } from './repository/exercise.repository';
import { ExerciseTagRepository } from './repository/exercise-tag.repository';
import { StudentExerciseRepository } from './repository/student-exercise.repository';
import { PlanExerciseRepository } from './repository/plan-exercise.repository';
import { PlanSetRepository } from './repository/plan-set.repository';
import { UserRepository } from './repository/user.repository';
import { UserTagRepository } from './repository/user-tag.repository';
import { CoachFinanceSettingsRepository } from './repository/coach-finance-settings.repository';
import { FinanceLedgerRepository } from './repository/finance-ledger.repository';
import { SessionChargeRepository } from './repository/session-charge.repository';
import { UserProfileRepository } from './repository/user-profile.repository';
import { TrainerPortfolioRepository } from './repository/trainer-portfolio.repository';
import { SessionReviewRepository } from './repository/session-review.repository';
import { BookingRequestRepository } from './repository/booking-request.repository';
import { BookingRequestEventRepository } from './repository/booking-request-event.repository';
import { CoachScheduleSettingsRepository } from './repository/coach-schedule-settings.repository';
import { ScheduleSeriesRepository } from './repository/schedule-series.repository';
import { AvailabilityWindowRepository } from './repository/availability-window.repository';
import { AvailabilityExceptionRepository } from './repository/availability-exception.repository';
import { RecurringBookingRepository } from './repository/recurring-booking.repository';
import { RecurringBookingOverrideRepository } from './repository/recurring-booking-override.repository';
import { SessionPackageRepository } from './repository/session-package.repository';
import { SessionPackageDebitRepository } from './repository/session-package-debit.repository';
import { WorkoutProgramRepository } from './repository/workout-program.repository';
import { SessionWorkoutItemRepository } from './repository/session-workout-item.repository';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],

      /**
       *
       */
      useFactory: () => ({
        type: 'postgres' as const,
        url: resolveDatabaseUrl(),
        entities,
        migrations: [`${__dirname}/migrations/*{.ts,.js}`],
        synchronize: false,
        logging: false,
      }),
    }),
    TypeOrmModule.forFeature(entities),
  ],
  providers: [
    UserRepository,
    RoleRepository,
    RefreshTokenRepository,
    InvitationRepository,
    CoachStudentLinkRepository,
    ScheduleSlotRepository,
    SessionRepository,
    SessionHistoryEventRepository,
    SessionSetLogRepository,
    TagRepository,
    UserTagRepository,
    TrainingPlanRepository,
    TrainingPlanTagRepository,
    ExerciseRepository,
    ExerciseTagRepository,
    StudentExerciseRepository,
    PlanExerciseRepository,
    PlanSetRepository,
    CoachFinanceSettingsRepository,
    SessionChargeRepository,
    FinanceLedgerRepository,
    UserProfileRepository,
    TrainerPortfolioRepository,
    SessionReviewRepository,
    BookingRequestRepository,
    BookingRequestEventRepository,
    CoachScheduleSettingsRepository,
    ScheduleSeriesRepository,
    AvailabilityWindowRepository,
    AvailabilityExceptionRepository,
    RecurringBookingRepository,
    RecurringBookingOverrideRepository,
    SessionPackageRepository,
    SessionPackageDebitRepository,
    WorkoutProgramRepository,
    SessionWorkoutItemRepository,
  ],
  exports: [
    TypeOrmModule,
    UserRepository,
    RoleRepository,
    RefreshTokenRepository,
    InvitationRepository,
    CoachStudentLinkRepository,
    ScheduleSlotRepository,
    SessionRepository,
    SessionHistoryEventRepository,
    SessionSetLogRepository,
    TagRepository,
    UserTagRepository,
    TrainingPlanRepository,
    TrainingPlanTagRepository,
    ExerciseRepository,
    ExerciseTagRepository,
    StudentExerciseRepository,
    PlanExerciseRepository,
    PlanSetRepository,
    CoachFinanceSettingsRepository,
    SessionChargeRepository,
    FinanceLedgerRepository,
    UserProfileRepository,
    TrainerPortfolioRepository,
    SessionReviewRepository,
    BookingRequestRepository,
    BookingRequestEventRepository,
    CoachScheduleSettingsRepository,
    ScheduleSeriesRepository,
    AvailabilityWindowRepository,
    AvailabilityExceptionRepository,
    RecurringBookingRepository,
    RecurringBookingOverrideRepository,
    SessionPackageRepository,
    SessionPackageDebitRepository,
    WorkoutProgramRepository,
    SessionWorkoutItemRepository,
  ],
})
export class DatabaseModule {}
