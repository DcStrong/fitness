export interface CreateSessionPackageParams {
  coachId: string;
  studentId: string;
  totalSessions: number;
  expiresAt?: Date | null;
}

export interface ExtendSessionPackageParams {
  coachId: string;
  packageId: string;
  addSessions: number;
  expiresAt?: Date | null;
}

export interface ArchiveSessionPackageParams {
  coachId: string;
  packageId: string;
}

export interface GetSessionPackageParams {
  actorId: string;
  packageId: string;
}

export interface ListSessionPackagesParams {
  actorId: string;
}
