import type { ScheduleSlotMode, ScheduleSlotStatus } from './schedule-slot.types';

/** Domain shape used when mapping entity → public returns (no TypeORM). */
export interface ScheduleSlotModel {
  id: string;
  coachId: string;
  startsAt: Date;
  endsAt: Date;
  mode: ScheduleSlotMode;
  status: ScheduleSlotStatus;
  capacity: number;
  seriesId: string | null;
  gymId: string | null;
  createdAt: Date;
}
