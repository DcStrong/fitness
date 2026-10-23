import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CalendarBookingService } from '../calendar/calendar-booking.service';
import { BookingRequestEntity } from '../database/entity/booking-request.entity';
import { RecurringBookingEntity } from '../database/entity/recurring-booking.entity';
import { UserEntity } from '../database/entity/user.entity';
import { CoachScheduleSettingsRepository } from '../database/repository/coach-schedule-settings.repository';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { RecurringBookingOverrideRepository } from '../database/repository/recurring-booking-override.repository';
import { RecurringBookingRepository } from '../database/repository/recurring-booking.repository';
import { ScheduleSlotRepository } from '../database/repository/schedule-slot.repository';
import { SessionRepository } from '../database/repository/session.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import { UserRepository } from '../database/repository/user.repository';
import { horizonLocalRange } from '../schedules/util/fixed-grid.util';
import { SessionLifecycleService } from '../sessions/session-lifecycle.service';
import { WorkoutProgramsService } from '../workout-programs/workout-programs.service';
import { ChatSystemMessageService } from '../chat/chat-system-message.service';
import type { CreateRecurringBookingParams } from './interface/create-recurring-booking.params';
import type { CreateRecurringBookingReturns } from './interface/create-recurring-booking.returns';
import type { ResolveOccurrenceParams } from './interface/resolve-occurrence.params';
import type {
  RecurringBookingModel,
  RecurringConflict,
  RecurringConflictReason,
  RecurringSyncSummary,
  WeekdayNumber,
} from './interface/recurring-booking.types';
import type { SyncRecurringBookingParams } from './interface/sync-recurring-booking.params';
import {
  expandDesiredOccurrences,
  occurrenceToUtcRange,
} from './util/occurrences.util';

@Injectable()
export class RecurringBookingsService {
  constructor(
    private readonly bookings: RecurringBookingRepository,
    private readonly overrides: RecurringBookingOverrideRepository,
    private readonly settingsRepo: CoachScheduleSettingsRepository,
    private readonly links: CoachStudentLinkRepository,
    private readonly slots: ScheduleSlotRepository,
    private readonly sessions: SessionRepository,
    private readonly booking: CalendarBookingService,
    private readonly lifecycle: SessionLifecycleService,
    private readonly profiles: UserProfileRepository,
    private readonly users: UserRepository,
    private readonly dataSource: DataSource,
    private readonly programs: WorkoutProgramsService,
    @Optional() private readonly chat?: ChatSystemMessageService,
  ) {}

  async create(
    params: CreateRecurringBookingParams,
  ): Promise<CreateRecurringBookingReturns> {
    this.assertWeekdays(params.weekdays);
    this.assertStartMinute(params.startMinute);

    const link = await this.links.findByPair(params.coachId, params.studentId);
    if (!link) {
      throw new ForbiddenException('Coach and student are not linked');
    }

    const weekdays = [...params.weekdays].sort((a, b) => a - b) as WeekdayNumber[];
    const pattern = {
      coachId: params.coachId,
      studentId: params.studentId,
      weekdays,
      startMinute: params.startMinute,
      mode: params.mode,
    };

    const activeTwins = await this.bookings.findByPattern({
      ...pattern,
      status: 'active',
    });
    const activeTwin = activeTwins[0];
    if (activeTwin) {
      throw new ConflictException({
        message: 'Такая серия уже есть',
        existingId: activeTwin.id,
      });
    }

    const settings = await this.settingsRepo.findByCoachId(params.coachId);
    const timezone = settings?.timezone ?? 'Europe/Moscow';

    const cancelledTwins = await this.bookings.findByPattern({
      ...pattern,
      status: 'cancelled',
    });
    const cancelledTwin = cancelledTwins
      .slice()
      .sort((a, b) => {
        const aAt = a.cancelledAt?.getTime() ?? a.updatedAt.getTime();
        const bAt = b.cancelledAt?.getTime() ?? b.updatedAt.getTime();
        return bAt - aAt;
      })[0];

    if (cancelledTwin) {
      return this.reactivateBooking(cancelledTwin, {
        timezone,
        horizonWeeksOverride:
          params.horizonWeeksOverride ?? cancelledTwin.horizonWeeksOverride,
      });
    }

    let entity: RecurringBookingEntity;
    try {
      entity = await this.bookings.save(
        this.bookings.create({
          coachId: params.coachId,
          studentId: params.studentId,
          weekdays,
          startMinute: params.startMinute,
          mode: params.mode,
          timezone,
          status: 'active',
          horizonWeeksOverride: params.horizonWeeksOverride ?? null,
          cancelledAt: null,
        }),
      );
    } catch (error) {
      this.rethrowActivePatternConflict(error);
      throw error;
    }

    const sync = await this.sync({
      coachId: params.coachId,
      recurringBookingId: entity.id,
    });

    return { booking: await this.toModel(entity), sync };
  }

  async restore(
    coachId: string,
    id: string,
  ): Promise<CreateRecurringBookingReturns> {
    const booking = await this.requireOwned(coachId, id);
    if (booking.status !== 'cancelled') {
      throw new ConflictException('Recurring booking is already active');
    }

    const weekdays = [...booking.weekdays].sort(
      (a, b) => a - b,
    ) as WeekdayNumber[];
    const activeTwins = await this.bookings.findByPattern({
      coachId: booking.coachId,
      studentId: booking.studentId,
      weekdays,
      startMinute: booking.startMinute,
      mode: booking.mode,
      status: 'active',
    });
    const conflict = activeTwins.find(twin => twin.id !== booking.id);
    if (conflict) {
      throw new ConflictException({
        message: 'Такая серия уже есть',
        existingId: conflict.id,
      });
    }

    return this.reactivateBooking(booking);
  }

  async listForCoach(
    coachId: string,
    status: 'active' | 'cancelled' | 'all' = 'active',
  ): Promise<RecurringBookingModel[]> {
    const rows =
      status === 'all'
        ? await this.bookings.findByCoachId(coachId)
        : status === 'cancelled'
          ? await this.bookings.findByCoachIdAndStatus(coachId, 'cancelled')
          : await this.bookings.findActiveByCoach(coachId);
    return this.toModels(rows);
  }

  async getForCoach(
    coachId: string,
    id: string,
  ): Promise<RecurringBookingModel> {
    const row = await this.requireOwned(coachId, id);
    return this.toModel(row);
  }

  async sync(
    params: SyncRecurringBookingParams,
  ): Promise<RecurringSyncSummary> {
    const booking = await this.requireOwned(
      params.coachId,
      params.recurringBookingId,
    );
    if (booking.status !== 'active') {
      throw new ConflictException('Recurring booking is not active');
    }

    return this.runSync(booking);
  }

  async cancel(coachId: string, id: string): Promise<RecurringBookingModel> {
    const booking = await this.requireOwned(coachId, id);
    if (booking.status === 'cancelled') {
      return this.toModel(booking);
    }

    booking.status = 'cancelled';
    booking.cancelledAt = new Date();
    await this.bookings.save(booking);

    const future = await this.sessions.findFutureBookedByRecurring(
      booking.id,
      new Date(),
    );
    for (const session of future) {
      await this.lifecycle.cancel(
        {
          id: coachId,
          permissions: ['sessions:cancel'],
        },
        {
          sessionId: session.id,
          note: 'recurring_cancelled',
          releaseSlot: true,
          silentChat: true,
        },
      );
    }

    return this.toModel(booking);
  }

  async deleteCancelled(coachId: string, id: string): Promise<void> {
    const booking = await this.requireOwned(coachId, id);
    if (booking.status !== 'cancelled') {
      throw new ConflictException('Only cancelled series can be deleted');
    }
    await this.overrides.deleteByBookingId(booking.id);
    await this.bookings.remove(booking);
  }

  async resolveOccurrence(
    params: ResolveOccurrenceParams,
  ): Promise<RecurringSyncSummary> {
    const booking = await this.requireOwned(
      params.coachId,
      params.recurringBookingId,
    );
    if (booking.status !== 'active') {
      throw new ConflictException('Recurring booking is not active');
    }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(params.localDate)) {
      throw new BadRequestException('Invalid localDate');
    }

    if (params.type === 'reschedule') {
      if (
        params.newStartMinute == null &&
        (params.newLocalDate == null || params.newLocalDate === '')
      ) {
        throw new BadRequestException(
          'Reschedule requires newStartMinute and/or newLocalDate',
        );
      }
      if (params.newStartMinute != null) {
        this.assertStartMinute(params.newStartMinute);
      }
    }

    const existing = await this.overrides.findByBookingAndDate(
      booking.id,
      params.localDate,
    );
    const row =
      existing ??
      this.overrides.create({
        recurringBookingId: booking.id,
        localDate: params.localDate,
      });
    row.type = params.type;
    row.newStartMinute =
      params.type === 'reschedule' ? (params.newStartMinute ?? null) : null;
    row.newLocalDate =
      params.type === 'reschedule' ? (params.newLocalDate ?? null) : null;
    await this.overrides.save(row);

    const summary = await this.sync({
      coachId: params.coachId,
      recurringBookingId: booking.id,
    });
    await this.postOccurrenceChat(booking, params);

    return summary;
  }

  /**
   * Tells the student about a moved or skipped occurrence once the series is
   * re-synced, pointing at the new session when one was booked.
   */
  private async postOccurrenceChat(
    booking: RecurringBookingEntity,
    params: ResolveOccurrenceParams,
  ): Promise<void> {
    const chat = this.chat;
    if (!chat) {
      return;
    }
    const session =
      params.type === 'reschedule'
        ? await this.sessions.findByRecurringOccurrence(
            booking.id,
            params.localDate,
          )
        : null;
    const delivery = await this.dataSource.transaction(manager =>
      chat.post({
        manager,
        coachId: booking.coachId,
        studentId: booking.studentId,
        type:
          params.type === 'reschedule'
            ? 'session_rescheduled'
            : 'occurrence_skipped',
        payload: {
          sessionId: session?.id ?? null,
          startsAt: session?.startsAt.toISOString() ?? null,
          endsAt: session?.endsAt.toISOString() ?? null,
          localDate: params.localDate,
        },
      }),
    );
    chat.publish([delivery]);
  }

  private async runSync(
    booking: RecurringBookingEntity,
  ): Promise<RecurringSyncSummary> {
    await this.dataSource.transaction(async manager => {
      await manager.findOneOrFail(UserEntity, {
        where: { id: booking.coachId },
        lock: { mode: 'pessimistic_write' },
      });
    });

    const settings = await this.settingsRepo.findByCoachId(booking.coachId);
    const duration =
      booking.mode === 'online' && settings?.onlineDurationMinutes != null
        ? settings.onlineDurationMinutes
        : booking.mode === 'offline' &&
            settings?.offlineDurationMinutes != null
          ? settings.offlineDurationMinutes
          : (settings?.defaultDurationMinutes ?? 60);
    const horizonWeeks =
      booking.horizonWeeksOverride ?? settings?.horizonWeeks ?? 8;
    const timezone = booking.timezone;
    const { fromLocalDate, toLocalDateExclusive } = horizonLocalRange(
      new Date(),
      timezone,
      horizonWeeks,
    );
    const overrideRows = await this.overrides.findByBookingId(booking.id);
    const desired = expandDesiredOccurrences({
      weekdays: booking.weekdays,
      startMinute: booking.startMinute,
      fromLocalDate,
      toLocalDateExclusive,
      overrides: overrideRows.map(row => ({
        localDate: row.localDate,
        type: row.type,
        newStartMinute: row.newStartMinute,
        newLocalDate: row.newLocalDate,
      })),
    });

    let booked = 0;
    let skippedExisting = 0;
    let slotsCreated = 0;
    const conflicts: RecurringConflict[] = [];

    for (const occurrence of desired) {
      const existing = await this.sessions.findByRecurringOccurrence(
        booking.id,
        occurrence.sourceLocalDate,
      );
      if (existing) {
        skippedExisting += 1;
        continue;
      }

      const range = occurrenceToUtcRange({
        localDate: occurrence.localDate,
        startMinute: occurrence.startMinute,
        durationMinutes: duration,
        timezone,
      });

      const conflictReason = await this.classifyConflict(
        booking,
        range.startsAt,
        range.endsAt,
      );
      if (conflictReason) {
        conflicts.push({
          localDate: occurrence.sourceLocalDate,
          reason: conflictReason,
          startsAt: range.startsAt.toISOString(),
          endsAt: range.endsAt.toISOString(),
        });
        continue;
      }

      const slot = await this.slots.findExactForCoach({
        coachId: booking.coachId,
        startsAt: range.startsAt,
        endsAt: range.endsAt,
      });

      try {
        if (
          slot &&
          slot.status === 'open' &&
          slot.mode === booking.mode
        ) {
          await this.booking.book({
            scheduleSlotId: slot.id,
            studentId: booking.studentId,
            actorId: booking.coachId,
            createdBy: 'coach',
            recurringBookingId: booking.id,
            recurringLocalDate: occurrence.sourceLocalDate,
          });
        } else {
          await this.booking.bookAtTime({
            coachId: booking.coachId,
            studentId: booking.studentId,
            actorId: booking.coachId,
            createdBy: 'coach',
            startsAt: range.startsAt,
            endsAt: range.endsAt,
            mode: booking.mode,
            recurringBookingId: booking.id,
            recurringLocalDate: occurrence.sourceLocalDate,
          });
          slotsCreated += 1;
        }
        booked += 1;
      } catch (error: unknown) {
        conflicts.push({
          localDate: occurrence.sourceLocalDate,
          reason: 'booked_other',
          startsAt: range.startsAt.toISOString(),
          endsAt: range.endsAt.toISOString(),
        });
      }
    }

    await this.programs.applyIfPresent(booking.id);

    return { booked, skippedExisting, slotsCreated, conflicts };
  }

  private async classifyConflict(
    booking: RecurringBookingEntity,
    startsAt: Date,
    endsAt: Date,
  ): Promise<RecurringConflictReason | null> {
    let exact = await this.slots.findExactForCoach({
      coachId: booking.coachId,
      startsAt,
      endsAt,
    });
    if (exact?.status === 'booked') {
      exact = await this.booking.healOrphanBookedSlotEntity(exact);
    }
    if (exact) {
      let reason: RecurringConflictReason | null = null;
      if (exact.status !== 'open') {
        reason = 'booked_other';
      } else if (exact.mode !== booking.mode) {
        reason = 'mode_mismatch';
      } else {
        const held = await this.dataSource
          .getRepository(BookingRequestEntity)
          .createQueryBuilder('request')
          .where('request.schedule_slot_id = :slotId', { slotId: exact.id })
          .andWhere('request.status = \'pending\'')
          .andWhere('request.expires_at > :now', { now: new Date() })
          .getExists();
        if (held) {
          reason = 'held';
        }
      }
      return reason;
    }

    const overlapping = await this.slots.findOverlappingAnyStatus(
      booking.coachId,
      startsAt,
      endsAt,
    );
    for (const slot of overlapping) {
      if (slot.status === 'booked') {
        await this.booking.healOrphanBookedSlotEntity(slot);
      }
    }
    const remaining = await this.slots.findOverlappingAnyStatus(
      booking.coachId,
      startsAt,
      endsAt,
    );
    if (remaining.length > 0) {
      return 'overlap';
    }
    // Clean miss: auto-create via bookAtTime in runSync.
    return null;
  }

  private async requireOwned(
    coachId: string,
    id: string,
  ): Promise<RecurringBookingEntity> {
    const row = await this.bookings.findByIdForCoach(id, coachId);
    if (!row) {
      throw new NotFoundException('Recurring booking not found');
    }
    return row;
  }

  private assertWeekdays(weekdays: WeekdayNumber[]): void {
    if (!weekdays.length) {
      throw new BadRequestException('weekdays must not be empty');
    }
    for (const day of weekdays) {
      if (day < 1 || day > 7) {
        throw new BadRequestException('weekday must be 1..7');
      }
    }
  }

  private assertStartMinute(startMinute: number): void {
    if (
      !Number.isInteger(startMinute) ||
      startMinute < 0 ||
      startMinute >= 1440
    ) {
      throw new BadRequestException('startMinute must be 0..1439');
    }
  }

  private async reactivateBooking(
    entity: RecurringBookingEntity,
    options?: {
      timezone?: string;
      horizonWeeksOverride?: number | null;
    },
  ): Promise<CreateRecurringBookingReturns> {
    entity.status = 'active';
    entity.cancelledAt = null;
    if (options?.timezone != null) {
      entity.timezone = options.timezone;
    }
    if (options && 'horizonWeeksOverride' in options) {
      entity.horizonWeeksOverride = options.horizonWeeksOverride ?? null;
    }
    let saved: RecurringBookingEntity;
    try {
      saved = await this.bookings.save(entity);
    } catch (error) {
      this.rethrowActivePatternConflict(error);
      throw error;
    }
    const sync = await this.sync({
      coachId: saved.coachId,
      recurringBookingId: saved.id,
    });
    return { booking: await this.toModel(saved), sync };
  }

  private rethrowActivePatternConflict(error: unknown): void {
    const driver = (error as { driverError?: { code?: string; detail?: string } })
      .driverError;
    const message = String(driver?.detail ?? (error as Error).message ?? '');
    if (
      driver?.code === '23505' ||
      message.includes('UQ_recurring_bookings_active_pattern')
    ) {
      throw new ConflictException({
        message: 'Такая серия уже есть',
      });
    }
  }

  private async toModels(
    entities: RecurringBookingEntity[],
  ): Promise<RecurringBookingModel[]> {
    if (!entities.length) {
      return [];
    }
    const studentIds = [...new Set(entities.map(e => e.studentId))];
    const activeIds = entities
      .filter(e => e.status === 'active')
      .map(e => e.id);
    const coachIds = [...new Set(entities.map(e => e.coachId))];
    const [profiles, users, overrideRows, ...settingsList] = await Promise.all([
      this.profiles.findByUserIds(studentIds),
      this.users.findByIds(studentIds),
      this.overrides.findByBookingIds(activeIds),
      ...coachIds.map(id => this.settingsRepo.findByCoachId(id)),
    ]);
    const displayNameByUserId = new Map(
      profiles.map(p => [p.userId, p.displayName]),
    );
    const emailByUserId = new Map(users.map(u => [u.id, u.email]));
    const settingsByCoachId = new Map(
      coachIds.map((id, index) => [id, settingsList[index]] as const),
    );
    const overridesByBookingId = new Map<
      string,
      Array<{
        localDate: string;
        type: 'skip' | 'reschedule';
        newStartMinute: number | null;
        newLocalDate: string | null;
      }>
    >();
    for (const row of overrideRows) {
      const list = overridesByBookingId.get(row.recurringBookingId) ?? [];
      list.push({
        localDate: row.localDate,
        type: row.type,
        newStartMinute: row.newStartMinute,
        newLocalDate: row.newLocalDate,
      });
      overridesByBookingId.set(row.recurringBookingId, list);
    }

    const now = new Date();
    return entities.map(entity => {
      const settings = settingsByCoachId.get(entity.coachId);
      const horizonWeeks =
        entity.horizonWeeksOverride ?? settings?.horizonWeeks ?? 8;
      const nextOccurrenceLocalDate = this.computeNextOccurrenceLocalDate(
        entity,
        horizonWeeks,
        overridesByBookingId.get(entity.id) ?? [],
        now,
      );
      return this.toModelSync(
        entity,
        displayNameByUserId.get(entity.studentId) ?? null,
        emailByUserId.get(entity.studentId) ?? null,
        nextOccurrenceLocalDate,
      );
    });
  }

  private computeNextOccurrenceLocalDate(
    entity: RecurringBookingEntity,
    horizonWeeks: number,
    overrides: Array<{
      localDate: string;
      type: 'skip' | 'reschedule';
      newStartMinute: number | null;
      newLocalDate: string | null;
    }>,
    now: Date,
  ): string | null {
    if (entity.status !== 'active') {
      return null;
    }
    const { fromLocalDate, toLocalDateExclusive } = horizonLocalRange(
      now,
      entity.timezone,
      horizonWeeks,
    );
    const desired = expandDesiredOccurrences({
      weekdays: entity.weekdays,
      startMinute: entity.startMinute,
      fromLocalDate,
      toLocalDateExclusive,
      overrides,
    });
    const nowMs = now.getTime();
    for (const occurrence of desired) {
      const range = occurrenceToUtcRange({
        localDate: occurrence.localDate,
        startMinute: occurrence.startMinute,
        durationMinutes: 60,
        timezone: entity.timezone,
      });
      if (range.startsAt.getTime() >= nowMs) {
        return occurrence.localDate;
      }
    }
    return null;
  }

  private async toModel(
    entity: RecurringBookingEntity,
  ): Promise<RecurringBookingModel> {
    const [model] = await this.toModels([entity]);
    if (!model) {
      throw new NotFoundException('Recurring booking not found');
    }
    return model;
  }

  private toModelSync(
    entity: RecurringBookingEntity,
    studentDisplayName: string | null,
    studentEmail: string | null,
    nextOccurrenceLocalDate: string | null,
  ): RecurringBookingModel {
    return {
      id: entity.id,
      coachId: entity.coachId,
      studentId: entity.studentId,
      studentDisplayName,
      studentEmail,
      weekdays: entity.weekdays,
      startMinute: entity.startMinute,
      mode: entity.mode,
      timezone: entity.timezone,
      status: entity.status,
      horizonWeeksOverride: entity.horizonWeeksOverride,
      nextOccurrenceLocalDate,
      createdAt: entity.createdAt.toISOString(),
      updatedAt: entity.updatedAt.toISOString(),
      cancelledAt: entity.cancelledAt?.toISOString() ?? null,
    };
  }
}
