import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { SessionRepository } from '../database/repository/session.repository';
import { SessionReviewRepository } from '../database/repository/session-review.repository';
import { TrainerGymRepository } from '../database/repository/trainer-gym.repository';
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
  const trainerGyms = {
    findGymsByCoachId: jest.fn().mockResolvedValue([]),
    findGymsByCoachIds: jest.fn().mockResolvedValue(new Map()),
  };

  const service = new SocialService(
    profiles as unknown as UserProfileRepository,
    portfolio as unknown as TrainerPortfolioRepository,
    reviews as unknown as SessionReviewRepository,
    sessions as unknown as SessionRepository,
    links as unknown as CoachStudentLinkRepository,
    users as unknown as UserRepository,
    trainerGyms as unknown as TrainerGymRepository,
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
      gyms: [],
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

  it('отклоняет шестой элемент портфолио кодом PORTFOLIO_LIMIT_REACHED', async () => {
    portfolio.countByCoachId.mockResolvedValue(5);

    await expect(
      service.createPortfolioItem(
        { id: 'trainer-1', roles: ['trainer'] },
        { title: 'Фото' },
      ),
    ).rejects.toMatchObject({
      response: { code: 'PORTFOLIO_LIMIT_REACHED' },
    });
  });

  describe('валидация профиля тренера', () => {
    const trainer = { id: 'trainer-1', roles: ['trainer'] };
    const base = { displayName: 'Иван Петров' };

    beforeEach(() => {
      profiles.findByUserId.mockResolvedValue(null);
      profiles.create.mockImplementation((data: object) => ({ ...data }));
      profiles.save.mockImplementation(async (entity: object) => entity);
      users.findById.mockResolvedValue({ email: 'trainer@example.com' });
      portfolio.findByCoachId.mockResolvedValue([]);
      reviews.ratingForCoach.mockResolvedValue({
        averageRating: null,
        reviewCount: 0,
      });
    });

    it('принимает российский телефон в формате +7XXXXXXXXXX', async () => {
      await service.updateOwnProfile(trainer, {
        ...base,
        phone: '+7 (999) 123-45-67',
      });

      expect(profiles.save).toHaveBeenCalledWith(
        expect.objectContaining({ phone: '+79991234567' }),
      );
    });

    it.each(['+380991234567', '89991234567', '+7999123456'])(
      'отклоняет телефон %s',
      async phone => {
        await expect(
          service.updateOwnProfile(trainer, { ...base, phone }),
        ).rejects.toBeInstanceOf(BadRequestException);
      },
    );

    it('отклоняет более 8 специализаций', async () => {
      const specialties = Array.from({ length: 9 }, (_, i) => `тег${i}`);

      await expect(
        service.updateOwnProfile(trainer, { ...base, specialties }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('отклоняет специализацию длиннее 30 символов', async () => {
      await expect(
        service.updateOwnProfile(trainer, {
          ...base,
          specialties: ['а'.repeat(31)],
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('принимает 8 специализаций по 30 символов', async () => {
      const specialties = Array.from({ length: 8 }, (_, i) =>
        `${i}`.padEnd(30, 'ф'));

      await service.updateOwnProfile(trainer, { ...base, specialties });

      expect(profiles.save).toHaveBeenCalledWith(
        expect.objectContaining({ specialties }),
      );
    });
  });

  describe('залы в каталоге', () => {
    it('отдаёт залы тренеров в карточках и передаёт фильтры', async () => {
      profiles.listDiscoverable.mockResolvedValue({
        items: [
          {
            profile: {
              userId: 'trainer-1',
              displayName: 'Иван',
              avatarUrl: null,
              bio: null,
              city: 'Москва',
              specialties: [],
              trainingModes: ['offline'],
              showRating: false,
            },
            averageRating: null,
            reviewCount: 0,
          },
        ],
        total: 1,
      });
      const gym = {
        id: 'gym-1',
        name: 'Зал',
        address: 'ул. Ленина, 1',
        city: 'Москва',
        district: 'Центр',
        dedupeKey: 'k',
      };
      trainerGyms.findGymsByCoachIds.mockResolvedValue(
        new Map([['trainer-1', [gym]]]),
      );

      const page = await service.listTrainers({
        page: 1,
        limit: 20,
        gymId: 'gym-1',
        district: '  Центр ',
        gymQuery: 'Ленина',
        city: 'Москва',
      });

      expect(profiles.listDiscoverable).toHaveBeenCalledWith(
        expect.objectContaining({
          gymId: 'gym-1',
          district: 'Центр',
          gymQuery: 'Ленина',
          city: 'Москва',
        }),
      );
      expect(page.items[0]?.gyms).toEqual([
        {
          id: 'gym-1',
          name: 'Зал',
          address: 'ул. Ленина, 1',
          city: 'Москва',
          district: 'Центр',
        },
      ]);
    });
  });
});
