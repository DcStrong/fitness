export interface PatchSessionWorkoutLoadItem {
  exerciseId: string;
  weightKg: number;
}

export interface PatchSessionPlanParams {
  actorId: string;
  permissions: string[];
  sessionId: string;
  studentPlanId?: string | null;
  workoutPlanIds?: string[];
}

export interface PatchSessionWorkoutLoadsParams {
  actorId: string;
  permissions: string[];
  sessionId: string;
  studentPlanId: string;
  items: PatchSessionWorkoutLoadItem[];
}

export interface GetSessionParams {
  actorId: string;
  sessionId: string;
}
