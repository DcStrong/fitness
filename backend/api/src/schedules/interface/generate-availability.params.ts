export interface GenerateAvailabilityParams {
  coachId: string;
  /** Optional override; defaults to settings.horizonWeeks from now */
  from?: Date;
  to?: Date;
}

export interface PreviewAvailabilityParams {
  coachId: string;
  from: Date;
  to: Date;
}
