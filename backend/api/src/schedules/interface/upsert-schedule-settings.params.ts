import type { ScheduleSlotMode } from '../../schedules/interface/schedule-slot.types';

export interface UpsertScheduleSettingsParams {
  coachId: string;
  timezone: string;
  defaultDurationMinutes: number;
  breakMinutes: number;
  horizonWeeks: number;
  onlineDurationMinutes: number | null;
  offlineDurationMinutes: number | null;
  defaultMode: ScheduleSlotMode;
}
