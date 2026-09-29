export const EXERCISE_KINDS = [
  'weight_reps',
  'bodyweight_reps',
  'duration',
] as const;

export type ExerciseKind = (typeof EXERCISE_KINDS)[number];

export const EXERCISE_SOURCES = ['own', 'catalog'] as const;

export type ExerciseSource = (typeof EXERCISE_SOURCES)[number];

export interface ExerciseTagSummary {
  id: string;
  name: string;
}

export interface ExerciseReturns {
  id: string;
  name: string;
  kind: ExerciseKind;
  source: ExerciseSource;
  ownerCoachId: string | null;
  tags: ExerciseTagSummary[];
  createdAt: string;
  updatedAt: string;
}

export interface CreateExerciseParams {
  name: string;
  kind: ExerciseKind;
  tagIds?: string[];
}

export interface UpdateExerciseParams {
  exerciseId: string;
  name?: string;
  kind?: ExerciseKind;
  tagIds?: string[];
}

export interface ReplaceExerciseTagsParams {
  exerciseId: string;
  tagIds: string[];
}

export interface AssignExercisesParams {
  exerciseIds: string[];
  studentIds?: string[];
  tagIds?: string[];
}

export interface UnassignExerciseParams {
  exerciseId: string;
  studentId: string;
}

export interface ListExercisesQueryParams {
  actorId: string;
  tagId?: string;
}

export interface CreateExerciseEntityParams {
  name: string;
  kind: ExerciseKind;
  ownerCoachId: string | null;
}

export interface FindExerciseByOwnerAndNameParams {
  ownerCoachId: string | null;
  name: string;
}

export interface CreateStudentExerciseParams {
  coachId: string;
  studentId: string;
  exerciseId: string;
}
