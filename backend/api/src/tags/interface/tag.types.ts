/**
 *
 */
export interface TagModel {
  id: string;
  name: string;
  creatorId: string;
  createdAt: Date;
}

/**
 *
 */
export interface TagReturns {
  id: string;
  name: string;
  creatorId: string;
  creatorEmail: string | null;
  createdAt: string;
}

/**
 *
 */
export interface CreateTagParams {
  name: string;
}

/**
 *
 */
export interface AssignTagParams {
  tagId: string;
  userId: string;
}

/**
 *
 */
export interface TagAssigneeReturns {
  userId: string;
  email: string | null;
  displayName: string | null;
  assignedAt: string;
}

/**
 *
 */
export interface TagHubPlanSummary {
  id: string;
  title: string;
  kind: string;
}

/**
 *
 */
export interface TagHubExerciseSummary {
  id: string;
  name: string;
  kind: string;
  source: 'own' | 'catalog';
}

/**
 *
 */
export interface TagHubReturns extends TagReturns {
  users: TagAssigneeReturns[];
  plans: TagHubPlanSummary[];
  exercises: TagHubExerciseSummary[];
}
