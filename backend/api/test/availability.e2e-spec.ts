import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { UserEntity } from '../src/database/entity/user.entity';

describe('Доступность тренера (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let coachId = '';
  let otherCoachId = '';
  let coachToken = '';
  let otherCoachToken = '';

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    app.useLogger(false);
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
    dataSource = app.get(DataSource);
    const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const users = dataSource.getRepository(UserEntity);
    const coach = await users.save(
      users.create({
        email: `avail-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const other = await users.save(
      users.create({
        email: `avail-coach-other-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    coachId = coach.id;
    otherCoachId = other.id;
    const secret = process.env['JWT_ACCESS_SECRET'];
    if (!secret) {
      throw new Error('JWT_ACCESS_SECRET is required for e2e');
    }
    const jwt = new JwtService({ secret });
    const perms = [
      'schedules:create',
      'schedules:read_own',
      'schedules:delete_own',
    ];
    coachToken = await jwt.signAsync({
      sub: coachId,
      email: coach.email,
      roles: ['trainer'],
      permissions: perms,
    });
    otherCoachToken = await jwt.signAsync({
      sub: otherCoachId,
      email: other.email,
      roles: ['trainer'],
      permissions: perms,
    });
  });

  afterAll(async () => {
    if (dataSource?.isInitialized) {
      await dataSource.query(
        `DELETE FROM schedule_slots WHERE coach_id = ANY($1::uuid[])`,
        [[coachId, otherCoachId]],
      );
      await dataSource.query(
        `DELETE FROM availability_exceptions WHERE series_id IN (
          SELECT id FROM schedule_series WHERE coach_id = ANY($1::uuid[])
        )`,
        [[coachId, otherCoachId]],
      );
      await dataSource.query(
        `DELETE FROM availability_windows WHERE series_id IN (
          SELECT id FROM schedule_series WHERE coach_id = ANY($1::uuid[])
        )`,
        [[coachId, otherCoachId]],
      );
      await dataSource.query(
        `DELETE FROM schedule_series WHERE coach_id = ANY($1::uuid[])`,
        [[coachId, otherCoachId]],
      );
      await dataSource.query(
        `DELETE FROM coach_schedule_settings WHERE coach_id = ANY($1::uuid[])`,
        [[coachId, otherCoachId]],
      );
      await dataSource.query(`DELETE FROM users WHERE id = ANY($1::uuid[])`, [
        [coachId, otherCoachId],
      ]);
    }
    await app.close();
  });

  /**
   *
   */
  it('сохраняет settings и отклоняет невалидную длительность', async () => {
    await request(app.getHttpServer())
      .put('/schedule/availability/settings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        timezone: 'Europe/Moscow',
        defaultDurationMinutes: 60,
        breakMinutes: 15,
        horizonWeeks: 2,
        onlineDurationMinutes: null,
        offlineDurationMinutes: null,
        defaultMode: 'offline',
      })
      .expect(200)
      .expect(res => {
        expect(res.body.defaultDurationMinutes).toBe(60);
        expect(res.body.breakMinutes).toBe(15);
        expect(res.body.timezone).toBe('Europe/Moscow');
      });

    await request(app.getHttpServer())
      .put('/schedule/availability/settings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        timezone: 'Europe/Moscow',
        defaultDurationMinutes: 0,
        breakMinutes: 0,
        horizonWeeks: 2,
        defaultMode: 'offline',
      })
      .expect(400);
  });

  /**
   *
   */
  it('upsert шаблона и изоляция между тренерами', async () => {
    const body = {
      windows: [
        {
          dayOfWeek: 1,
          startMinute: 9 * 60,
          endMinute: 13 * 60,
          mode: null,
        },
      ],
    };
    const saved = await request(app.getHttpServer())
      .put('/schedule/availability/template')
      .set('Authorization', `Bearer ${coachToken}`)
      .send(body)
      .expect(200);
    expect(saved.body.seriesId).toBeTruthy();
    expect(saved.body.windows).toHaveLength(1);

    await request(app.getHttpServer())
      .put('/schedule/availability/template')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        windows: [
          {
            dayOfWeek: 1,
            startMinute: 9 * 60,
            endMinute: 12 * 60,
            mode: null,
          },
          {
            dayOfWeek: 1,
            startMinute: 10 * 60,
            endMinute: 11 * 60,
            mode: null,
          },
        ],
      })
      .expect(400);

    const other = await request(app.getHttpServer())
      .get('/schedule/availability/template')
      .set('Authorization', `Bearer ${otherCoachToken}`)
      .expect(200);
    expect(other.body.windows).toEqual([]);
  });

  /**
   *
   */
  it('генерирует слоты идемпотентно', async () => {
    await request(app.getHttpServer())
      .put('/schedule/availability/settings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        timezone: 'Europe/Moscow',
        defaultDurationMinutes: 60,
        breakMinutes: 15,
        horizonWeeks: 1,
        defaultMode: 'offline',
      })
      .expect(200);

    await request(app.getHttpServer())
      .put('/schedule/availability/template')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        windows: [
          {
            dayOfWeek: 1,
            startMinute: 9 * 60,
            endMinute: 13 * 60,
            mode: null,
          },
          {
            dayOfWeek: 2,
            startMinute: 9 * 60,
            endMinute: 13 * 60,
            mode: null,
          },
          {
            dayOfWeek: 3,
            startMinute: 9 * 60,
            endMinute: 13 * 60,
            mode: null,
          },
          {
            dayOfWeek: 4,
            startMinute: 9 * 60,
            endMinute: 13 * 60,
            mode: null,
          },
          {
            dayOfWeek: 5,
            startMinute: 9 * 60,
            endMinute: 13 * 60,
            mode: null,
          },
        ],
      })
      .expect(200);

    const first = await request(app.getHttpServer())
      .post('/schedule/availability/generate')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);
    expect(first.body.created).toBeGreaterThan(0);

    const second = await request(app.getHttpServer())
      .post('/schedule/availability/generate')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);
    expect(second.body.created).toBe(0);
    expect(second.body.skippedExisting).toBeGreaterThan(0);

    const list = await request(app.getHttpServer())
      .get('/schedule/slots')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(Array.isArray(list.body)).toBe(true);
    expect(list.body.length).toBeGreaterThan(0);
    expect(list.body.every((s: { seriesId: string | null }) => s.seriesId)).toBe(
      true,
    );
  });
});
