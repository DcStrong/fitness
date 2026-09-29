import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { CoachStudentLinkEntity } from '../src/database/entity/coach-student-link.entity';
import { ScheduleSlotEntity } from '../src/database/entity/schedule-slot.entity';
import { SessionEntity } from '../src/database/entity/session.entity';
import { UserEntity } from '../src/database/entity/user.entity';

describe('Социальные профили и приватность (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let trainerToken: string;
  let secondTrainerToken: string;
  let studentToken: string;
  let trainerId: string;
  let studentId: string;
  let sessionId: string;
  let portfolioItemId: string;
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const trainerEmail = `social-trainer-${suffix}@example.com`;
  const secondTrainerEmail = `social-trainer-foreign-${suffix}@example.com`;
  const studentEmail = `social-student-${suffix}@example.com`;
  const password = 'Password123';

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
    dataSource = app.get(DataSource);

    const trainer = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email: trainerEmail, password, role: 'trainer' })
      .expect(201);
    const student = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email: studentEmail, password, role: 'student' })
      .expect(201);
    const secondTrainer = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email: secondTrainerEmail, password, role: 'trainer' })
      .expect(201);
    trainerToken = trainer.body.accessToken as string;
    secondTrainerToken = secondTrainer.body.accessToken as string;
    studentToken = student.body.accessToken as string;
    trainerId = trainer.body.user.id as string;
    studentId = student.body.user.id as string;

    const startsAt = new Date('2035-06-10T10:00:00.000Z');
    const endsAt = new Date('2035-06-10T11:00:00.000Z');
    const slot = await dataSource.getRepository(ScheduleSlotEntity).save({
      coachId: trainerId,
      startsAt,
      endsAt,
      mode: 'online',
      status: 'booked',
      seriesId: null,
      gymId: null,
      capacity: 1,
    });
    const session = await dataSource.getRepository(SessionEntity).save({
      coachId: trainerId,
      studentId,
      scheduleSlotId: slot.id,
      startsAt,
      endsAt,
      mode: 'online',
      status: 'completed',
      createdBy: 'student',
    });
    sessionId = session.id;
  });

  afterAll(async () => {
    await dataSource.getRepository(UserEntity).delete([
      { email: trainerEmail },
      { email: secondTrainerEmail },
      { email: studentEmail },
    ]);
    await app.close();
  });

  it('выполняет публикацию → поиск → подтверждённый отзыв → приватность', async () => {
    const legacy = await request(app.getHttpServer())
      .get('/profiles/me')
      .set('Authorization', `Bearer ${trainerToken}`)
      .expect(200);
    expect(legacy.body).toMatchObject({
      userId: trainerId,
      displayName: null,
      specialties: [],
      trainingModes: [],
      privacy: { isDiscoverable: false },
      portfolio: [],
    });

    await request(app.getHttpServer())
      .get(`/trainers/${trainerId}`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(404);

    await request(app.getHttpServer())
      .put('/profiles/me')
      .set('Authorization', `Bearer ${trainerToken}`)
      .send({
        displayName: '  Анна   Тренер  ',
        bio: 'Функциональные тренировки',
        city: 'Москва',
        specialties: ['Сила'],
        trainingModes: ['online'],
        avatarUrl: 'https://example.com/avatar.jpg',
      })
      .expect(200);

    const portfolioItem = await request(app.getHttpServer())
      .post('/profiles/me/portfolio')
      .set('Authorization', `Bearer ${trainerToken}`)
      .send({
        title: 'Сертификат',
        imageUrl: 'https://example.com/certificate.jpg',
      })
      .expect(201);
    portfolioItemId = portfolioItem.body.id as string;

    await request(app.getHttpServer())
      .put('/profiles/me/privacy')
      .set('Authorization', `Bearer ${trainerToken}`)
      .send({
        isDiscoverable: true,
        showRating: true,
        showReviews: true,
        showReviewerName: false,
      })
      .expect(200);

    const discovery = await request(app.getHttpServer())
      .get('/trainers?page=1&limit=50&specialty=сила&mode=online')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(discovery.body.items).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: trainerId,
          displayName: 'Анна Тренер',
        }),
      ]),
    );
    expect(discovery.body.meta).toEqual({
      page: 1,
      limit: 50,
      total: expect.any(Number),
      totalPages: expect.any(Number),
    });
    expect(JSON.stringify(discovery.body)).not.toContain(trainerEmail);

    const detail = await request(app.getHttpServer())
      .get(`/trainers/${trainerId}`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(detail.body).toMatchObject({
      id: trainerId,
      isLinked: false,
      portfolio: [expect.objectContaining({ title: 'Сертификат' })],
    });
    expect(detail.body).not.toHaveProperty('email');
    expect(detail.body).not.toHaveProperty('permissions');

    const eligible = await request(app.getHttpServer())
      .get('/reviews/eligible')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(eligible.body).toEqual([
      expect.objectContaining({ sessionId, coachId: trainerId }),
    ]);

    const created = await request(app.getHttpServer())
      .post(`/sessions/${sessionId}/review`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ rating: 5, text: 'Отличная тренировка' })
      .expect(201);
    const reviewId = created.body.id as string;

    await request(app.getHttpServer())
      .post(`/sessions/${sessionId}/review`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ rating: 4 })
      .expect(409);

    await request(app.getHttpServer())
      .put(`/reviews/${reviewId}`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ rating: 4, text: 'Очень полезно' })
      .expect(200);

    const reviews = await request(app.getHttpServer())
      .get(`/trainers/${trainerId}/reviews`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(reviews.body.items[0]).toMatchObject({
      rating: 4,
      reviewer: { displayName: 'Ученик', avatarUrl: null },
    });
    expect(reviews.body.items[0].reviewer).not.toHaveProperty('id');
    expect(reviews.body.items[0]).not.toHaveProperty('sessionId');
    expect(reviews.body.items[0]).not.toHaveProperty('coachId');

    const rated = await request(app.getHttpServer())
      .get('/trainers?page=1&limit=50')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    const trainer = (rated.body.items as Array<Record<string, unknown>>).find(
      item => item['id'] === trainerId,
    );
    expect(trainer).toMatchObject({ averageRating: 4, reviewCount: 1 });

    await request(app.getHttpServer())
      .get('/profiles/me/reviews')
      .set('Authorization', `Bearer ${trainerToken}`)
      .expect(200)
      .expect(response => {
        expect(response.body.items).toHaveLength(1);
        expect(response.body).toMatchObject({
          averageRating: 4,
          reviewCount: 1,
        });
      });

    await request(app.getHttpServer())
      .put('/profiles/me/privacy')
      .set('Authorization', `Bearer ${trainerToken}`)
      .send({
        isDiscoverable: true,
        showRating: false,
        showReviews: false,
        showReviewerName: false,
      })
      .expect(200);

    const hiddenReviews = await request(app.getHttpServer())
      .get(`/trainers/${trainerId}/reviews`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(hiddenReviews.body.items).toEqual([]);

    const privacyDiscovery = await request(app.getHttpServer())
      .get('/trainers')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    const privacyTrainer = (
      privacyDiscovery.body.items as Array<Record<string, unknown>>
    ).find(item => item['id'] === trainerId);
    expect(privacyTrainer).not.toHaveProperty('averageRating');
    expect(privacyTrainer).not.toHaveProperty('reviewCount');
  });

  it('выдаёт контакты только связанному пользователю и не публикует PII', async () => {
    await dataSource.getRepository(CoachStudentLinkEntity).save({
      coachId: trainerId,
      studentId,
      sourceInvitationId: null,
    });
    const studentProfile = await request(app.getHttpServer())
      .put('/profiles/me')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        displayName: 'Иван Ученик',
        phone: '+7 (999) 123-45-67',
        telegramUsername: '@ivan_fit',
        preferredContactChannels: ['phone', 'telegram'],
      })
      .expect(200);
    expect(studentProfile.body).toMatchObject({
      phone: '+79991234567',
      telegramUsername: 'ivan_fit',
      preferredContactChannels: ['phone', 'telegram'],
      email: studentEmail,
    });

    const linked = await request(app.getHttpServer())
      .get(`/profiles/${studentId}/contacts`)
      .set('Authorization', `Bearer ${trainerToken}`)
      .expect(200);
    expect(linked.body).toEqual({
      userId: studentId,
      phone: '+79991234567',
      telegramUsername: 'ivan_fit',
      email: studentEmail,
      preferredContactChannels: ['phone', 'telegram', 'email'],
    });

    await request(app.getHttpServer())
      .get(`/profiles/${studentId}/contacts`)
      .set('Authorization', `Bearer ${secondTrainerToken}`)
      .expect(403);

    await request(app.getHttpServer())
      .put('/profiles/me')
      .set('Authorization', `Bearer ${trainerToken}`)
      .send({
        displayName: 'Анна Тренер',
        bio: 'Функциональные тренировки',
        city: 'Москва',
        specialties: ['сила'],
        trainingModes: ['online'],
        avatarUrl: 'https://example.com/avatar.jpg',
        phone: '+79990001122',
        telegramUsername: 'anna_fit',
        preferredContactChannels: ['phone', 'telegram', 'email'],
      })
      .expect(200);

    const discovery = await request(app.getHttpServer())
      .get('/trainers?page=1&limit=50')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    const detail = await request(app.getHttpServer())
      .get(`/trainers/${trainerId}`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    const reviews = await request(app.getHttpServer())
      .get(`/trainers/${trainerId}/reviews`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    for (const projection of [discovery.body, detail.body, reviews.body]) {
      const serialized = JSON.stringify(projection);
      expect(serialized).not.toContain('+79990001122');
      expect(serialized).not.toContain('anna_fit');
      expect(serialized).not.toContain(trainerEmail);
      expect(serialized).not.toContain('preferredContactChannels');
    }
  });

  it('не позволяет другому тренеру изменить или удалить portfolio item', async () => {
    await request(app.getHttpServer())
      .put(`/profiles/me/portfolio/${portfolioItemId}`)
      .set('Authorization', `Bearer ${secondTrainerToken}`)
      .send({
        title: 'Чужое изменение',
        imageUrl: 'https://example.com/foreign.jpg',
      })
      .expect(404);

    await request(app.getHttpServer())
      .delete(`/profiles/me/portfolio/${portfolioItemId}`)
      .set('Authorization', `Bearer ${secondTrainerToken}`)
      .expect(404);

    const ownerProfile = await request(app.getHttpServer())
      .get('/profiles/me')
      .set('Authorization', `Bearer ${trainerToken}`)
      .expect(200);
    expect(ownerProfile.body.portfolio).toEqual([
      expect.objectContaining({
        id: portfolioItemId,
        title: 'Сертификат',
        imageUrl: 'https://example.com/certificate.jpg',
      }),
    ]);
  });

  it('возвращает pagination meta и отклоняет limit больше 50', async () => {
    const page = await request(app.getHttpServer())
      .get('/trainers?page=1&limit=1')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(page.body.meta).toEqual({
      page: 1,
      limit: 1,
      total: expect.any(Number),
      totalPages: expect.any(Number),
    });
    expect(page.body.items.length).toBeLessThanOrEqual(1);

    await request(app.getHttpServer())
      .get('/trainers?page=1&limit=51')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(400);
  });
});
