import type { AvailabilityWindowModel } from './availability.types';

export interface UpsertAvailabilityTemplateParams {
  coachId: string;
  windows: AvailabilityWindowModel[];
}
