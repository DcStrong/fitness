import type { ConfigService } from '@nestjs/config';
import type { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import type { InvitationRepository } from '../database/repository/invitation.repository';
import type { UserProfileRepository } from '../database/repository/user-profile.repository';
import type { UserRepository } from '../database/repository/user.repository';
import { InvitationsService } from './invitations.service';

describe('Сервис приглашений: ссылки', () => {
  const invitations = {
    create: jest.fn((value: object) => value),
    save: jest.fn((value: object) =>
      Promise.resolve({
        id: 'inv-1',
        acceptedByUserId: null,
        createdAt: new Date('2026-01-01T00:00:00Z'),
        ...value,
      }),
    ),
  };

  const createService = (env: Record<string, string | undefined>) =>
    new InvitationsService(
      invitations as unknown as InvitationRepository,
      {} as CoachStudentLinkRepository,
      {} as UserRepository,
      {} as UserProfileRepository,
      { get: (key: string) => env[key] } as unknown as ConfigService,
    );

  it('по умолчанию ведёт на локальный веб :8080', async () => {
    const result = await createService({}).create('coach-1');

    expect(result.inviteUrl).toBe(`http://localhost:8080/i/${result.token}`);
    expect(result.deepLink).toBe(`fitnessyoda://invite/${result.token}`);
  });

  it('строит inviteUrl из INVITE_HTTPS_BASE (origin без /i)', async () => {
    const result = await createService({
      INVITE_HTTPS_BASE: 'https://app.149.154.64.173.sslip.io/',
    }).create('coach-1');

    expect(result.inviteUrl).toBe(
      `https://app.149.154.64.173.sslip.io/i/${result.token}`,
    );
  });

  it('не дублирует /i, если он уже есть в базе', async () => {
    const result = await createService({
      INVITE_HTTPS_BASE: 'https://app.example.com/i',
      INVITE_SCHEME_BASE: 'myapp://invite/',
    }).create('coach-1');

    expect(result.inviteUrl).toBe(`https://app.example.com/i/${result.token}`);
    expect(result.deepLink).toBe(`myapp://invite/${result.token}`);
  });
});
