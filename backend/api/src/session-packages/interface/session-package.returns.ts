import type { SessionPackageStatus } from './session-package.types';

export interface SessionPackageReturns {
  id: string;
  coachId: string;
  studentId: string;
  totalSessions: number;
  remainingSessions: number;
  expiresAt: string | null;
  status: SessionPackageStatus;
  createdAt: string;
  updatedAt: string;
  archivedAt: string | null;
  coachEmail: string | null;
  studentEmail: string | null;
  coachDisplayName: string | null;
  studentDisplayName: string | null;
}
