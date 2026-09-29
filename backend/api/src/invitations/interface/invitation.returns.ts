import type { InvitationStatus } from './invitation.types';

/**
 *
 */
export interface InvitationModel {
  id: string;
  coachId: string;
  status: InvitationStatus;
  expiresAt: Date;
  acceptedByUserId: string | null;
  createdAt: Date;
}

/**
 *
 */
export interface InvitationReturns {
  id: string;
  coachId: string;
  status: InvitationStatus;
  expiresAt: string;
  acceptedByUserId: string | null;
  createdAt: string;
}

/**
 *
 */
export interface InvitationCreatedReturns extends InvitationReturns {
  token: string;
  inviteUrl: string;
  deepLink: string;
}

/**
 *
 */
export interface AcceptInvitationReturns {
  invitation: InvitationReturns;
  relationship: {
    id: string;
    coachId: string;
    studentId: string;
    created: boolean;
    coachEmail: string | null;
  };
}

/**
 *
 */
export interface RelationshipReturns {
  id: string;
  coachId: string;
  studentId: string;
  coachEmail: string | null;
  studentEmail: string | null;
  coachDisplayName: string | null;
  studentDisplayName: string | null;
  createdAt: string;
  roleForViewer: 'coach' | 'student';
}
