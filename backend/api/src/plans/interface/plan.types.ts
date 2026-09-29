import type { ExerciseKind } from '../../exercises/interface';

export const PLAN_KINDS = [
  'template',
  'catalog_seed',
  'student_copy',
] as const;

export type PlanKind = (typeof PLAN_KINDS)[number];

export const PLAN_GOALS = ['hypertrophy', 'fat_loss', 'general'] as const;

export type PlanGoal = (typeof PLAN_GOALS)[number];

export const PLAN_LIST_SCOPES = ['template', 'catalog', 'assigned'] as const;

export type PlanListScope = (typeof PLAN_LIST_SCOPES)[number];

export interface TrainingPlanTagSummary {
  id: string;
  name: string;
}

export interface PlanSetInput {
  reps?: number | null;
  weightKg?: number | null;
  durationSeconds?: number | null;
}

export interface PlanExerciseInput {
  exerciseId: string;
  restSeconds?: number | null;
  notes?: string;
  sets?: PlanSetInput[];
}

export interface PlanSetReturns {
  id: string;
  sortOrder: number;
  reps: number | null;
  weightKg: number | null;
  durationSeconds: number | null;
}

export interface PlanExerciseReturns {
  id: string;
  exerciseId: string;
  exerciseName: string;
  exerciseKind: ExerciseKind;
  sortOrder: number;
  restSeconds: number | null;
  notes: string;
  sets: PlanSetReturns[];
}

export interface TrainingPlanModel {
  id: string;
  ownerCoachId: string;
  title: string;
  body: string;
  kind: PlanKind;
  goal: PlanGoal;
  parentTemplateId: string | null;
  assignedStudentId: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface TrainingPlanReturns {
  id: string;
  ownerCoachId: string;
  ownerCoachEmail: string | null;
  title: string;
  body: string;
  notes: string;
  kind: PlanKind;
  goal: PlanGoal;
  parentTemplateId: string | null;
  assignedStudentId: string | null;
  tags: TrainingPlanTagSummary[];
  exercises: PlanExerciseReturns[];
  createdAt: string;
  updatedAt: string;
}

export interface CreatePlanParams {
  title: string;
  body?: string;
  notes?: string;
  goal?: PlanGoal;
  tagIds?: string[];
  exercises?: PlanExerciseInput[];
  assignedStudentId?: string;
}

export interface UpdatePlanParams {
  planId: string;
  title?: string;
  body?: string;
  notes?: string;
  goal?: PlanGoal;
  tagIds?: string[];
  exercises?: PlanExerciseInput[];
}

export interface PatchPlanLoadsItem {
  exerciseId: string;
  weightKg: number;
}

export interface PatchPlanLoadsParams {
  planId: string;
  items: PatchPlanLoadsItem[];
}

export interface ReplacePlanSetParams {
  sortOrder: number;
  reps: number | null;
  weightKg: number | null;
  durationSeconds: number | null;
}

export interface ReplacePlanExerciseParams {
  exerciseId: string;
  sortOrder: number;
  restSeconds: number | null;
  notes: string;
  sets: ReplacePlanSetParams[];
}

export interface ListOwnPlansParams {
  ownerCoachId: string;
  scope?: PlanListScope;
}

export interface AssignPlanParams {
  planId: string;
  studentIds?: string[];
  tagIds?: string[];
}

export interface AssignPlansBatchParams {
  studentId: string;
  planIds: string[];
}

export interface ListAssignedPlansParams {
  actorId: string;
  permissions: string[];
  studentId?: string;
}

export interface ListPlansQueryParams {
  actorId: string;
  permissions: string[];
  kind?: string;
  studentId?: string;
  tagId?: string;
}
