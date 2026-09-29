import type { ScheduleSlotMode } from './schedule-slot.types';

/** ISO weekday: 1 = Monday … 7 = Sunday */
export type WeekdayNumber = 1 | 2 | 3 | 4 | 5 | 6 | 7;

export type ScheduleSeriesKind = 'weekly_availability';

export type AvailabilityExceptionType = 'closed' | 'custom_hours';

export interface AvailabilityWindowModel {
  dayOfWeek: WeekdayNumber;
  startMinute: number;
  endMinute: number;
  mode: ScheduleSlotMode | null;
}

export interface AvailabilityExceptionWindowModel {
  startMinute: number;
  endMinute: number;
  mode: ScheduleSlotMode | null;
}

export interface AvailabilityExceptionModel {
  id: string;
  localDate: string;
  type: AvailabilityExceptionType;
  windows: AvailabilityExceptionWindowModel[] | null;
}

export interface CoachScheduleSettingsModel {
  coachId: string;
  timezone: string;
  defaultDurationMinutes: number;
  breakMinutes: number;
  horizonWeeks: number;
  onlineDurationMinutes: number | null;
  offlineDurationMinutes: number | null;
  defaultMode: ScheduleSlotMode;
  updatedAt: string;
}

export interface AvailabilityTemplateModel {
  seriesId: string;
  coachId: string;
  kind: ScheduleSeriesKind;
  windows: AvailabilityWindowModel[];
}

export interface GenerateAvailabilitySummary {
  created: number;
  skippedExisting: number;
  skippedConflict: number;
  removedOrphanOpen: number;
}

export interface AvailabilitySlotCandidate {
  startsAt: Date;
  endsAt: Date;
  mode: ScheduleSlotMode;
}
