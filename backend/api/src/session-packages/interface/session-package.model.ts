import type { SessionPackageStatus } from './session-package.types';

export interface SessionPackageModel {
  id: string;
  coachId: string;
  studentId: string;
  totalSessions: number;
  remainingSessions: number;
  expiresAt: Date | null;
  status: SessionPackageStatus;
  createdAt: Date;
  updatedAt: Date;
  archivedAt: Date | null;
  coachEmail?: string | null;
  studentEmail?: string | null;
}
