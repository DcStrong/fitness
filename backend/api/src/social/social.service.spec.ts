import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { SessionRepository } from '../database/repository/session.repository';
import { SessionReviewRepository } from '../database/repository/session-review.repository';
import { TrainerPortfolioRepository } from '../database/repository/trainer-portfolio.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import { UserRepository } from '../database/repository/user.repository';
import type { SessionEntity } from '../database/entity/session.entity';
import { SocialService } from './social.service';

describe('Сервис социальных профилей', () => {
  const profiles = {
    findByUserId: jest.fn(),
    findDiscoverableTrainer: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    listDiscoverable: jest.fn(),
  };
  const portfolio = {
    findByCoachId: jest.fn(),
    countByCoachId: jest.fn(),
  };
  const reviews = {
    ratingForCoach: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
  };
  const sessions = {
    findById: jest.fn(),
  };
  const links = {
    findByPair: jest.fn(),
  };
  const users = {
    findById: jest.fn(),
  };

  const service = new SocialService(
    profiles as unknown as UserProfileRepository,
    portfolio as unknown as TrainerPortfolioRepository,
    reviews as unknown as SessionReviewRepository,
    sessions as unknown as SessionRepository,
    links as unknown as CoachStudentLinkRepository,
    users as unknown as UserRepository,
  );

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('возвращает безопасный owner-объект для legacy пользователя', async () => {
    profiles.findByUserId.mockResolvedValue(null);
    users.findById.mockResolvedValue({ email: 'student@example.com' });

    await expect(
      service.getOwnProfile({ id: 'student-1', roles: ['student'] }),
    ).resolves.toEqual({
      userId: 'student-1',
      displayName: null,
      avatarUrl: null,
      bio: null,
      city: null,
      specialties: [],
      trainingModes: [],
      phone: null,
      telegramUsername: null,
      preferredContactChannels: [],
      email: 'student@example.com',
      privacy: {
        isDiscoverable: false,
        showRating: true,
        showReviews: true,
        showReviewerName: false,
      },
      portfolio: [],
      averageRating: null,
      reviewCount: 0,
      createdAt: null,
      updatedAt: null,
    });
  });

  it('не разрешает студенту опубликовать профиль', async () => {
    await expect(
      service.updateOwnPrivacy(
        { id: 'student-1', roles: ['student'] },
        {
          isDiscoverable: true,
          showRating: true,
          showReviews: true,
          showReviewerName: false,
        },
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(profiles.save).not.toHaveBeenCalled();
  });

  it('скрывает существование непубличного тренера', async () => {
    profiles.findDiscoverableTrainer.mockResolvedValue(null);

    await expect(
      service.getTrainer(
        { id: 'viewer-1', roles: ['student'] },
        'trainer-hidden',
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('запрещает отзыв чужой сессии', async () => {
    sessions.findById.mockResolvedValue({
      id: 'session-1',
      studentId: 'student-2',
      coachId: 'trainer-1',
      status: 'completed',
    } as SessionEntity);

    await expect(
      service.createReview(
        { id: 'student-1', roles: ['student'] },
        'session-1',
        { rating: 5 },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('отклоняет отзыв незавершённой собственной сессии', async () => {
    sessions.findById.mockResolvedValue({
      id: 'session-1',
      studentId: 'student-1',
      coachId: 'trainer-1',
      status: 'booked',
    } as SessionEntity);

    await expect(
      service.createReview(
        { id: 'student-1', roles: ['student'] },
        'session-1',
        { rating: 5 },
      ),
    ).rejects.toBeInstanceOf(ConflictException);
  });
});
