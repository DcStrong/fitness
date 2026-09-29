import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomBytes } from 'crypto';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { InvitationRepository } from '../database/repository/invitation.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import { UserRepository } from '../database/repository/user.repository';
import type {
  AcceptInvitationReturns,
  InvitationCreatedReturns,
  InvitationModel,
  InvitationReturns,
  RelationshipReturns,
} from './interface/invitation.returns';

const DEFAULT_TTL_DAYS = 7;

@Injectable()
export class InvitationsService {
  constructor(
    private readonly invitations: InvitationRepository,
    private readonly links: CoachStudentLinkRepository,
    private readonly users: UserRepository,
    private readonly profiles: UserProfileRepository,
    private readonly config: ConfigService,
  ) {}

  /**
   *
   */
  async create(coachId: string): Promise<InvitationCreatedReturns> {
    const rawToken = randomBytes(32).toString('base64url');
    const days = Number(
      this.config.get('INVITATION_TTL_DAYS') ?? DEFAULT_TTL_DAYS,
    );
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + days);

    const invitation = await this.invitations.save(
      this.invitations.create({
        coachId,
        tokenHash: this.hashToken(rawToken),
        status: 'pending',
        expiresAt,
        acceptedByUserId: null,
      }),
    );

    return this.toCreateResponse(invitation, rawToken);
  }

  /**
   *
   */
  async listOwn(coachId: string): Promise<InvitationReturns[]> {
    const items = await this.invitations.findByCoachId(coachId);

    return items.map(item => this.toPublicInvitation(item));
  }

  /**
   *
   */
  async revoke(
    coachId: string,
    invitationId: string,
  ): Promise<InvitationReturns> {
    const invitation = await this.invitations.findById(invitationId);
    if (!invitation || invitation.coachId !== coachId) {
      throw new NotFoundException('Invitation not found');
    }
    if (invitation.status !== 'pending') {
      throw new ConflictException('Only pending invitations can be revoked');
    }
    invitation.status = 'revoked';
    const saved = await this.invitations.save(invitation);

    return this.toPublicInvitation(saved);
  }

  /**
   *
   */
  async accept(
    studentId: string,
    token: string,
  ): Promise<AcceptInvitationReturns> {
    const invitation = await this.invitations.findByTokenHash(
      this.hashToken(token),
    );
    if (!invitation) {
      throw new BadRequestException('Invalid invitation');
    }
    if (invitation.coachId === studentId) {
      throw new ForbiddenException('Cannot accept own invitation');
    }
    if (invitation.status === 'revoked') {
      throw new ConflictException('Invitation revoked');
    }
    if (invitation.status === 'accepted') {
      throw new ConflictException('Invitation already accepted');
    }
    if (invitation.expiresAt.getTime() <= Date.now()) {
      if (invitation.status === 'pending') {
        invitation.status = 'expired';
        await this.invitations.save(invitation);
      }
      throw new ConflictException('Invitation expired');
    }
    if (invitation.status !== 'pending') {
      throw new ConflictException('Invitation is not pending');
    }

    invitation.status = 'accepted';
    invitation.acceptedByUserId = studentId;
    await this.invitations.save(invitation);

    const { link, created } = await this.links.upsertLink({
      coachId: invitation.coachId,
      studentId,
      sourceInvitationId: invitation.id,
    });

    const coach = await this.users.findByIdWithAccess(invitation.coachId);

    return {
      invitation: this.toPublicInvitation(invitation),
      relationship: {
        id: link.id,
        coachId: link.coachId,
        studentId: link.studentId,
        created,
        coachEmail: coach?.email ?? null,
      },
    };
  }

  /**
   *
   */
  async listRelationships(userId: string): Promise<RelationshipReturns[]> {
    const links = await this.links.findForUser(userId);
    const profileUserIds = [
      ...new Set(links.flatMap(link => [link.coachId, link.studentId])),
    ];
    const profiles = await this.profiles.findByUserIds(profileUserIds);
    const displayNameByUserId = new Map(
      profiles.map(profile => [profile.userId, profile.displayName]),
    );

    return links.map(link => ({
      id: link.id,
      coachId: link.coachId,
      studentId: link.studentId,
      coachEmail: link.coach?.email ?? null,
      studentEmail: link.student?.email ?? null,
      coachDisplayName: displayNameByUserId.get(link.coachId) ?? null,
      studentDisplayName: displayNameByUserId.get(link.studentId) ?? null,
      createdAt: link.createdAt.toISOString(),
      roleForViewer:
        link.coachId === userId ? ('coach' as const) : ('student' as const),
    }));
  }

  /**
   *
   */
  private toCreateResponse(
    invitation: InvitationModel,
    rawToken: string,
  ): InvitationCreatedReturns {
    const httpsBase =
      this.config.get<string>('INVITE_HTTPS_BASE') ??
      'https://app.fitness-yoda.local/i';
    const schemeBase =
      this.config.get<string>('INVITE_SCHEME_BASE') ?? 'fitnessyoda://invite';

    return {
      ...this.toPublicInvitation(invitation),
      token: rawToken,
      inviteUrl: `${httpsBase.replace(/\/$/, '')}/${rawToken}`,
      deepLink: `${schemeBase.replace(/\/$/, '')}/${rawToken}`,
    };
  }

  /**
   *
   */
  private toPublicInvitation(invitation: InvitationModel): InvitationReturns {
    return {
      id: invitation.id,
      coachId: invitation.coachId,
      status: invitation.status,
      expiresAt: invitation.expiresAt.toISOString(),
      acceptedByUserId: invitation.acceptedByUserId,
      createdAt: invitation.createdAt.toISOString(),
    };
  }

  /**
   *
   */
  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}
