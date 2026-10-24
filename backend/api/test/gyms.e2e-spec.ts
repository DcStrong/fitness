import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { GymEntity } from '../src/database/entity/gym.entity';
import { UserEntity } from '../src/database/entity/user.entity';

describe('Залы тренера и поиск по залам (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let trainerToken: string;
  let otherTrainerToken: string;
  let hiddenTrainerToken: string;
  let studentToken: string;
  let trainerId: string;
  let otherTrainerId: string;
  let hiddenTrainerId: string;
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const tag = suffix.replace(/[^a-z0-9]/giu, '').slice(0, 12);
  const emails = {
    trainer: `gyms-trainer-${suffix}@example.com`,
    other: `gyms-other-${suffix}@example.com`,
    hidden: `gyms-hidden-${suffix}@example.com`,
    student: `gyms-student-${suffix}@example.com`,
  };
  const password = 'Password123';
  const gymName = `Iron Temple ${tag}`;
  const gymAddress = `ул. Тестовая, ${tag}`;
  const district = `Район${tag}`;
  let gymId: string;

  /**
   *
   */
  function auth(token: string): Record<string, string> {
    return { Authorization: `Bearer ${token}` };
  }

  /**
   *
   */
  async function register(
    email: string,
    role: 'trainer' | 'student',
  ): Promise<{ token: string; id: string; }> {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email, password, role })
      .expect(201);

    return {
      token: res.body.accessToken as string,
      id: res.body.user.id as string,
    };
  }

  /**
   *
   */
  async function publish(token: string, displayName: string): Promise<void> {
    await request(app.getHttpServer())
      .put('/profiles/me')
      .set(auth(token))
      .send({ displayName, city: 'Казань', specialties: ['сила'] })
      .expect(200);
    await request(app.getHttpServer())
      .put('/profiles/me/privacy')
      .set(auth(token))
      .send({
        isDiscoverable: true,
        showRating: true,
        showReviews: true,
        showReviewerName: false,
      })
      .expect(200);
  }

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

    const trainer = await register(emails.trainer, 'trainer');
    const other = await register(emails.other, 'trainer');
    const hidden = await register(emails.hidden, 'trainer');
    const student = await register(emails.student, 'student');
    trainerToken = trainer.token;
    trainerId = trainer.id;
    otherTrainerToken = other.token;
    otherTrainerId = other.id;
    hiddenTrainerToken = hidden.token;
    hiddenTrainerId = hidden.id;
    studentToken = student.token;
  });

  afterAll(async () => {
    await dataSource
      .getRepository(UserEntity)
      .delete(Object.values(emails).map(email => ({ email })));
    await dataSource
      .createQueryBuilder()
      .delete()
      .from(GymEntity)
      .where('name ILIKE :name', { name: `%${tag}%` })
      .execute();
    await app.close();
  });

  it('создаёт зал по вводу, склеивает дубль второго тренера и показывает свои залы', async () => {
    const created = await request(app.getHttpServer())
      .post('/profiles/me/gyms')
      .set(auth(trainerToken))
      .send({ name: gymName, address: gymAddress, city: 'Казань', district })
      .expect(201);
    gymId = created.body.id as string;
    expect(created.body).toEqual({
      id: gymId,
      name: gymName,
      address: gymAddress,
      city: 'Казань',
      district,
    });

    const duplicate = await request(app.getHttpServer())
      .post('/profiles/me/gyms')
      .set(auth(otherTrainerToken))
      .send({
        name: `  ${gymName.toUpperCase()} `,
        address: gymAddress.toLowerCase(),
        city: 'казань',
      })
      .expect(201);
    expect(duplicate.body.id).toBe(gymId);

    const rows = await dataSource
      .getRepository(GymEntity)
      .count({ where: { id: gymId } });
    expect(rows).toBe(1);

    await request(app.getHttpServer())
      .post('/profiles/me/gyms')
      .set(auth(trainerToken))
      .send({ gymId })
      .expect(201);

    const own = await request(app.getHttpServer())
      .get('/profiles/me/gyms')
      .set(auth(trainerToken))
      .expect(200);
    expect(own.body).toHaveLength(1);

    const profile = await request(app.getHttpServer())
      .get('/profiles/me')
      .set(auth(trainerToken))
      .expect(200);
    expect(profile.body.gyms).toEqual([expect.objectContaining({ id: gymId })]);
  });

  it('привязывает существующий зал по gymId и отдаёт подсказки', async () => {
    await request(app.getHttpServer())
      .post('/profiles/me/gyms')
      .set(auth(hiddenTrainerToken))
      .send({ gymId })
      .expect(201);

    const byName = await request(app.getHttpServer())
      .get(`/gyms/suggestions?query=${encodeURIComponent(`temple ${tag}`)}`)
      .set(auth(trainerToken))
      .expect(200);
    expect(byName.body).toEqual([expect.objectContaining({ id: gymId })]);

    const byAddress = await request(app.getHttpServer())
      .get(
        `/gyms/suggestions?query=${encodeURIComponent(gymAddress.slice(4))}&city=${encodeURIComponent('казан')}`,
      )
      .set(auth(trainerToken))
      .expect(200);
    expect(byAddress.body).toEqual([expect.objectContaining({ id: gymId })]);

    const otherCity = await request(app.getHttpServer())
      .get(`/gyms/suggestions?query=${tag}&city=${encodeURIComponent('Омск')}`)
      .set(auth(trainerToken))
      .expect(200);
    expect(otherCity.body).toEqual([]);

    const wildcard = await request(app.getHttpServer())
      .get('/gyms/suggestions?query=%25')
      .set(auth(trainerToken))
      .expect(200);
    expect(wildcard.body).not.toEqual(
      expect.arrayContaining([expect.objectContaining({ id: gymId })]),
    );
  });

  it('фильтрует каталог по залу, району и подстроке, показывая залы только опубликованных', async () => {
    await publish(trainerToken, 'Тренер Залов');
    await publish(otherTrainerToken, 'Второй Тренер');
    // hiddenTrainer остаётся неопубликованным, но привязан к залу.

    /**
     *
     */
    async function search(
      qs: string,
    ): Promise<{ items: Array<{ id: string; gyms: Array<{ id: string; }>; }>; }> {
      const res = await request(app.getHttpServer())
        .get(`/trainers?page=1&limit=50&${qs}`)
        .set(auth(studentToken))
        .expect(200);

      return res.body as {
        items: Array<{ id: string; gyms: Array<{ id: string; }>; }>;
      };
    }

    const byGym = await search(`gymId=${gymId}`);
    expect(byGym.items.map(item => item.id).sort()).toEqual(
      [trainerId, otherTrainerId].sort(),
    );
    expect(byGym.items[0]?.gyms).toEqual([
      expect.objectContaining({ id: gymId, name: gymName }),
    ]);
    expect(JSON.stringify(byGym)).not.toContain(hiddenTrainerId);

    const byDistrict = await search(`district=${encodeURIComponent(district)}`);
    expect(byDistrict.items.map(item => item.id)).toEqual(
      expect.arrayContaining([trainerId]),
    );

    const byText = await search(`gymQuery=${encodeURIComponent(tag)}`);
    expect(byText.items).toHaveLength(2);

    const none = await search(`gymQuery=${tag}zzz`);
    expect(none.items).toEqual([]);

    const byCity = await search(`gymId=${gymId}&city=${encodeURIComponent('Казан')}`);
    expect(byCity.items).toHaveLength(2);
    const wrongCity = await search(`gymId=${gymId}&city=${encodeURIComponent('Омск')}`);
    expect(wrongCity.items).toEqual([]);

    const detail = await request(app.getHttpServer())
      .get(`/trainers/${trainerId}`)
      .set(auth(studentToken))
      .expect(200);
    expect(detail.body.gyms).toEqual([expect.objectContaining({ id: gymId })]);

    await request(app.getHttpServer())
      .get(`/trainers/${hiddenTrainerId}`)
      .set(auth(studentToken))
      .expect(404);
  });

  it('удаляет только собственную привязку', async () => {
    await request(app.getHttpServer())
      .delete(`/profiles/me/gyms/${gymId}`)
      .set(auth(hiddenTrainerToken))
      .expect(204);
    await request(app.getHttpServer())
      .delete(`/profiles/me/gyms/${gymId}`)
      .set(auth(hiddenTrainerToken))
      .expect(404);

    const other = await request(app.getHttpServer())
      .get('/profiles/me/gyms')
      .set(auth(otherTrainerToken))
      .expect(200);
    expect(other.body).toHaveLength(1);
  });

  it('валидирует ввод зала и права ученика', async () => {
    await request(app.getHttpServer())
      .post('/profiles/me/gyms')
      .set(auth(trainerToken))
      .send({ name: 'Только имя' })
      .expect(400);
    await request(app.getHttpServer())
      .post('/profiles/me/gyms')
      .set(auth(trainerToken))
      .send({ name: '<b>x</b>', address: 'a', city: 'b' })
      .expect(400);
    await request(app.getHttpServer())
      .post('/profiles/me/gyms')
      .set(auth(trainerToken))
      .send({ gymId: '00000000-0000-4000-8000-000000000000' })
      .expect(404);
    await request(app.getHttpServer())
      .post('/profiles/me/gyms')
      .set(auth(studentToken))
      .send({ gymId })
      .expect(403);
    await request(app.getHttpServer())
      .get('/gyms/suggestions')
      .set(auth(studentToken))
      .expect(403);
    await request(app.getHttpServer()).get('/gyms/suggestions').expect(401);
  });

  it('валидирует телефон и специализации профиля', async () => {
    /**
     *
     */
    function put(body: object): request.Test {
      return request(app.getHttpServer())
        .put('/profiles/me')
        .set(auth(trainerToken))
        .send({ displayName: 'Тренер Залов', ...body });
    }

    await put({ phone: '+79991234567' }).expect(200);
    await put({ phone: '89991234567' }).expect(400);
    await put({ phone: '+380991234567' }).expect(400);
    await put({ phone: '+7 (999) 123-45-67' }).expect(400);

    const eight = Array.from({ length: 8 }, (_, i) => `тег${i}`);
    await put({ specialties: eight }).expect(200);
    await put({ specialties: [...eight, 'девятый'] }).expect(400);
    await put({ specialties: ['а'.repeat(30)] }).expect(200);
    await put({ specialties: ['а'.repeat(31)] }).expect(400);
  });
});
