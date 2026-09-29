import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { AvailabilityExceptionEntity } from '../database/entity/availability-exception.entity';
import { AvailabilityWindowEntity } from '../database/entity/availability-window.entity';
import { CoachScheduleSettingsEntity } from '../database/entity/coach-schedule-settings.entity';
import { ScheduleSeriesEntity } from '../database/entity/schedule-series.entity';
import { ScheduleSlotEntity } from '../database/entity/schedule-slot.entity';
import { UserEntity } from '../database/entity/user.entity';
import { AvailabilityExceptionRepository } from '../database/repository/availability-exception.repository';
import { AvailabilityWindowRepository } from '../database/repository/availability-window.repository';
import { BookingRequestRepository } from '../database/repository/booking-request.repository';
import { CoachScheduleSettingsRepository } from '../database/repository/coach-schedule-settings.repository';
import {
  rangesOverlap,
} from '../database/repository/schedule-slot.repository';
import { ScheduleSeriesRepository } from '../database/repository/schedule-series.repository';
import type {
  AvailabilityExceptionModel,
  AvailabilityExceptionWindowModel,
  AvailabilitySlotCandidate,
  AvailabilityTemplateModel,
  AvailabilityWindowModel,
  CoachScheduleSettingsModel,
  GenerateAvailabilitySummary,
  WeekdayNumber,
} from './interface/availability.types';
import type {
  GenerateAvailabilityParams,
  PreviewAvailabilityParams,
} from './interface/generate-availability.params';
import type { ReplaceAvailabilityExceptionsParams } from './interface/replace-availability-exceptions.params';
import type { UpsertAvailabilityTemplateParams } from './interface/upsert-availability-template.params';
import type { UpsertScheduleSettingsParams } from './interface/upsert-schedule-settings.params';
import {
  buildFixedGridCandidates,
  horizonLocalRange,
} from './util/fixed-grid.util';
import { formatZonedDate, zonedLocalToUtc } from './util/zoned-time.util';

const DEFAULT_SETTINGS = {
  timezone: 'Europe/Moscow',
  defaultDurationMinutes: 60,
  breakMinutes: 0,
  horizonWeeks: 8,
  onlineDurationMinutes: null as number | null,
  offlineDurationMinutes: null as number | null,
  defaultMode: 'offline' as const,
};

interface GenerationContext {
  settings: CoachScheduleSettingsModel;
  series: ScheduleSeriesEntity | null;
  windows: AvailabilityWindowModel[];
  exceptions: Array<{
    localDate: string;
    type: 'closed' | 'custom_hours';
    windows: AvailabilityExceptionWindowModel[] | null;
  }>;
}

@Injectable()
export class AvailabilityService {
  constructor(
    private readonly settingsRepo: CoachScheduleSettingsRepository,
    private readonly seriesRepo: ScheduleSeriesRepository,
    private readonly windowsRepo: AvailabilityWindowRepository,
    private readonly exceptionsRepo: AvailabilityExceptionRepository,
    private readonly bookingRequests: BookingRequestRepository,
    private readonly dataSource: DataSource,
  ) {}

  /**
   *
   */
  async getSettings(coachId: string): Promise<CoachScheduleSettingsModel> {
    const existing = await this.settingsRepo.findByCoachId(coachId);
    if (!existing) {
      return {
        coachId,
        ...DEFAULT_SETTINGS,
        updatedAt: new Date(0).toISOString(),
      };
    }

    return this.toSettingsModel(existing);
  }

  /**
   *
   */
  async upsertSettings(
    params: UpsertScheduleSettingsParams,
  ): Promise<CoachScheduleSettingsModel> {
    this.assertSettings(params);
    const saved = await this.settingsRepo.save(params);

    return this.toSettingsModel(saved);
  }

  /**
   *
   */
  async getTemplate(coachId: string): Promise<AvailabilityTemplateModel> {
    const series = await this.seriesRepo.findWeeklyByCoachId(coachId);
    if (!series) {
      return {
        seriesId: '',
        coachId,
        kind: 'weekly_availability',
        windows: [],
      };
    }
    const windows = await this.windowsRepo.findBySeriesId(series.id);

    return {
      seriesId: series.id,
      coachId,
      kind: series.kind,
      windows: windows.map(mapWindow),
    };
  }

  /**
   *
   */
  async upsertTemplate(
    params: UpsertAvailabilityTemplateParams,
  ): Promise<AvailabilityTemplateModel> {
    this.assertWindows(params.windows);

    return this.dataSource.transaction(async manager => {
      await this.lockCoach(manager, params.coachId);
      const series = await this.ensureWeeklySeries(manager, params.coachId);
      await manager.delete(AvailabilityWindowEntity, { seriesId: series.id });
      const entities = params.windows.map(window =>
        manager.create(AvailabilityWindowEntity, {
          seriesId: series.id,
          dayOfWeek: window.dayOfWeek,
          startMinute: window.startMinute,
          endMinute: window.endMinute,
          mode: window.mode,
        }));
      const windows =
        entities.length > 0 ? await manager.save(entities) : [];

      return {
        seriesId: series.id,
        coachId: params.coachId,
        kind: series.kind,
        windows: windows.map(mapWindow),
      };
    });
  }

  /**
   *
   */
  async listExceptions(coachId: string): Promise<AvailabilityExceptionModel[]> {
    const series = await this.seriesRepo.findWeeklyByCoachId(coachId);
    if (!series) {
      return [];
    }
    const rows = await this.exceptionsRepo.findBySeriesId(series.id);

    return rows.map(mapException);
  }

  /**
   *
   */
  async replaceExceptions(
    params: ReplaceAvailabilityExceptionsParams,
  ): Promise<AvailabilityExceptionModel[]> {
    for (const item of params.exceptions) {
      this.assertException(item);
    }

    return this.dataSource.transaction(async manager => {
      await this.lockCoach(manager, params.coachId);
      const series = await this.ensureWeeklySeries(manager, params.coachId);
      await manager.delete(AvailabilityExceptionEntity, {
        seriesId: series.id,
      });
      const entities = params.exceptions.map(item =>
        manager.create(AvailabilityExceptionEntity, {
          seriesId: series.id,
          localDate: item.localDate,
          type: item.type,
          windows: item.windows,
        }));
      const rows = entities.length > 0 ? await manager.save(entities) : [];

      return rows.map(mapException);
    });
  }

  /**
   *
   */
  async preview(
    params: PreviewAvailabilityParams,
  ): Promise<AvailabilitySlotCandidate[]> {
    const ctx = await this.loadGenerationContext(params.coachId);
    if (!ctx.series) {
      return [];
    }
    const fromLocal = formatZonedDate(params.from, ctx.settings.timezone);
    const toLocalExclusive = formatZonedDate(params.to, ctx.settings.timezone);

    return buildFixedGridCandidates({
      settings: ctx.settings,
      windows: ctx.windows,
      exceptions: ctx.exceptions,
      fromLocalDate: fromLocal,
      toLocalDateExclusive: toLocalExclusive,
    });
  }

  /**
   *
   */
  async generate(
    params: GenerateAvailabilityParams,
  ): Promise<GenerateAvailabilitySummary> {
    return this.dataSource.transaction(async manager => {
      await this.lockCoach(manager, params.coachId);
      const ctx = await this.loadGenerationContext(params.coachId);
      if (!ctx.series) {
        throw new NotFoundException('Availability template not found');
      }

      const range =
        params.from && params.to
          ? {
              fromLocalDate: formatZonedDate(
                params.from,
                ctx.settings.timezone,
              ),
              toLocalDateExclusive: formatZonedDate(
                params.to,
                ctx.settings.timezone,
              ),
            }
          : horizonLocalRange(
              new Date(),
              ctx.settings.timezone,
              ctx.settings.horizonWeeks,
            );

      const candidates = buildFixedGridCandidates({
        settings: ctx.settings,
        windows: ctx.windows,
        exceptions: ctx.exceptions,
        fromLocalDate: range.fromLocalDate,
        toLocalDateExclusive: range.toLocalDateExclusive,
      });

      const rangeStart = localDateStartUtc(
        range.fromLocalDate,
        ctx.settings.timezone,
      );
      const rangeEnd = localDateStartUtc(
        range.toLocalDateExclusive,
        ctx.settings.timezone,
      );

      const existing = await manager
        .createQueryBuilder(ScheduleSlotEntity, 'slot')
        .where('slot.coach_id = :coachId', { coachId: params.coachId })
        .andWhere('slot.starts_at < :to AND slot.ends_at > :from', {
          from: rangeStart,
          to: rangeEnd,
        })
        .getMany();

      const now = new Date();
      const heldIds = new Set<string>();
      for (const slot of existing) {
        if (await this.bookingRequests.hasActiveHold(slot.id, now)) {
          heldIds.add(slot.id);
        }
      }

      const desiredKeys = new Set(
        candidates.map(c => intervalKey(c.startsAt, c.endsAt)),
      );

      let created = 0;
      let skippedExisting = 0;
      let skippedConflict = 0;

      for (const candidate of candidates) {
        const exact = existing.find(
          slot =>
            slot.startsAt.getTime() === candidate.startsAt.getTime()
            && slot.endsAt.getTime() === candidate.endsAt.getTime(),
        );
        if (exact) {
          skippedExisting += 1;
          continue;
        }
        const overlaps = existing.some(slot =>
          rangesOverlap(
            slot.startsAt,
            slot.endsAt,
            candidate.startsAt,
            candidate.endsAt,
          ));
        if (overlaps) {
          skippedConflict += 1;
          continue;
        }
        const saved = await manager.save(
          manager.create(ScheduleSlotEntity, {
            coachId: params.coachId,
            startsAt: candidate.startsAt,
            endsAt: candidate.endsAt,
            mode: candidate.mode,
            status: 'open',
            seriesId: ctx.series.id,
            gymId: null,
            capacity: 1,
          }),
        );
        existing.push(saved);
        created += 1;
      }

      const orphans = existing.filter(
        slot =>
          slot.seriesId === ctx.series!.id
          && slot.status === 'open'
          && !heldIds.has(slot.id)
          && !desiredKeys.has(intervalKey(slot.startsAt, slot.endsAt)),
      );
      let removedOrphanOpen = 0;
      if (orphans.length > 0) {
        await manager.remove(ScheduleSlotEntity, orphans);
        removedOrphanOpen = orphans.length;
      }

      return {
        created,
        skippedExisting,
        skippedConflict,
        removedOrphanOpen,
      };
    });
  }

  private async loadGenerationContext(
    coachId: string,
  ): Promise<GenerationContext> {
    const settingsEntity = await this.settingsRepo.findByCoachId(coachId);
    const settings = settingsEntity
      ? this.toSettingsModel(settingsEntity)
      : {
          coachId,
          ...DEFAULT_SETTINGS,
          updatedAt: new Date(0).toISOString(),
        };
    const series = await this.seriesRepo.findWeeklyByCoachId(coachId);
    if (!series) {
      return { settings, series: null, windows: [], exceptions: [] };
    }
    const windows = await this.windowsRepo.findBySeriesId(series.id);
    const exceptions = await this.exceptionsRepo.findBySeriesId(series.id);

    return {
      settings,
      series,
      windows: windows.map(mapWindow),
      exceptions: exceptions.map(row => ({
        localDate: normalizeLocalDate(row.localDate),
        type: row.type,
        windows: row.windows,
      })),
    };
  }

  private async ensureWeeklySeries(
    manager: EntityManager,
    coachId: string,
  ): Promise<ScheduleSeriesEntity> {
    const existing = await manager.findOne(ScheduleSeriesEntity, {
      where: { coachId, kind: 'weekly_availability' },
    });
    if (existing) {
      return existing;
    }

    return manager.save(
      manager.create(ScheduleSeriesEntity, {
        coachId,
        kind: 'weekly_availability',
      }),
    );
  }

  private async lockCoach(
    manager: EntityManager,
    coachId: string,
  ): Promise<void> {
    await manager.findOneOrFail(UserEntity, {
      where: { id: coachId },
      lock: { mode: 'pessimistic_write' },
    });
  }

  private assertSettings(params: UpsertScheduleSettingsParams): void {
    if (params.defaultDurationMinutes <= 0) {
      throw new BadRequestException('defaultDurationMinutes must be positive');
    }
    if (params.breakMinutes < 0) {
      throw new BadRequestException('breakMinutes must be >= 0');
    }
    if (params.horizonWeeks <= 0 || params.horizonWeeks > 52) {
      throw new BadRequestException('horizonWeeks must be between 1 and 52');
    }
    if (!isValidIanaTimeZone(params.timezone)) {
      throw new BadRequestException('Invalid IANA timezone');
    }
    if (
      params.onlineDurationMinutes != null
      && params.onlineDurationMinutes <= 0
    ) {
      throw new BadRequestException('onlineDurationMinutes must be positive');
    }
    if (
      params.offlineDurationMinutes != null
      && params.offlineDurationMinutes <= 0
    ) {
      throw new BadRequestException('offlineDurationMinutes must be positive');
    }
  }

  private assertWindows(windows: AvailabilityWindowModel[]): void {
    for (const window of windows) {
      if (window.dayOfWeek < 1 || window.dayOfWeek > 7) {
        throw new BadRequestException('dayOfWeek must be 1..7');
      }
      this.assertMinuteRange(window.startMinute, window.endMinute);
    }
    const byDow = new Map<WeekdayNumber, AvailabilityWindowModel[]>();
    for (const window of windows) {
      const list = byDow.get(window.dayOfWeek) ?? [];
      list.push(window);
      byDow.set(window.dayOfWeek, list);
    }
    for (const [, list] of byDow) {
      const sorted = [...list].sort((a, b) => a.startMinute - b.startMinute);
      for (let i = 1; i < sorted.length; i += 1) {
        if (sorted[i]!.startMinute < sorted[i - 1]!.endMinute) {
          throw new BadRequestException(
            'Windows on the same weekday must not overlap',
          );
        }
      }
    }
  }

  private assertException(item: {
    localDate: string;
    type: 'closed' | 'custom_hours';
    windows: AvailabilityExceptionWindowModel[] | null;
  }): void {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(item.localDate)) {
      throw new BadRequestException('localDate must be YYYY-MM-DD');
    }
    if (item.type === 'closed') {
      if (item.windows != null) {
        throw new BadRequestException('closed exception must not have windows');
      }

      return;
    }
    if (!item.windows || item.windows.length === 0) {
      throw new BadRequestException('custom_hours exception requires windows');
    }
    for (const window of item.windows) {
      this.assertMinuteRange(window.startMinute, window.endMinute);
    }
  }

  private assertMinuteRange(startMinute: number, endMinute: number): void {
    if (
      !Number.isInteger(startMinute)
      || !Number.isInteger(endMinute)
      || startMinute < 0
      || endMinute > 1440
      || endMinute <= startMinute
    ) {
      throw new BadRequestException('Invalid window minute range');
    }
  }

  private toSettingsModel(
    entity: CoachScheduleSettingsEntity,
  ): CoachScheduleSettingsModel {
    return {
      coachId: entity.coachId,
      timezone: entity.timezone,
      defaultDurationMinutes: entity.defaultDurationMinutes,
      breakMinutes: entity.breakMinutes,
      horizonWeeks: entity.horizonWeeks,
      onlineDurationMinutes: entity.onlineDurationMinutes,
      offlineDurationMinutes: entity.offlineDurationMinutes,
      defaultMode: entity.defaultMode,
      updatedAt: entity.updatedAt.toISOString(),
    };
  }
}

function mapWindow(window: {
  dayOfWeek: WeekdayNumber;
  startMinute: number;
  endMinute: number;
  mode: AvailabilityWindowModel['mode'];
}): AvailabilityWindowModel {
  return {
    dayOfWeek: window.dayOfWeek,
    startMinute: window.startMinute,
    endMinute: window.endMinute,
    mode: window.mode,
  };
}

function mapException(row: {
  id: string;
  localDate: string | Date;
  type: AvailabilityExceptionModel['type'];
  windows: AvailabilityExceptionWindowModel[] | null;
}): AvailabilityExceptionModel {
  return {
    id: row.id,
    localDate: normalizeLocalDate(row.localDate),
    type: row.type,
    windows: row.windows,
  };
}

function normalizeLocalDate(value: string | Date): string {
  if (typeof value === 'string') {
    return value.slice(0, 10);
  }

  return value.toISOString().slice(0, 10);
}

function localDateStartUtc(localDate: string, timezone: string): Date {
  return zonedLocalToUtc(
    {
      year: Number(localDate.slice(0, 4)),
      month: Number(localDate.slice(5, 7)),
      day: Number(localDate.slice(8, 10)),
      hour: 0,
      minute: 0,
    },
    timezone,
  );
}

function intervalKey(startsAt: Date, endsAt: Date): string {
  return `${startsAt.toISOString()}|${endsAt.toISOString()}`;
}

function isValidIanaTimeZone(timezone: string): boolean {
  try {
    Intl.DateTimeFormat(undefined, { timeZone: timezone });

    return true;
  } catch {
    return false;
  }
}
