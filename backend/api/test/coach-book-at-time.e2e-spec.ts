import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { CoachFinanceSettingsEntity } from '../src/database/entity/coach-finance-settings.entity';
import { CoachStudentLinkEntity } from '../src/database/entity/coach-student-link.entity';
import { UserEntity } from '../src/database/entity/user.entity';

describe('Coach book-at-time (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let coachId = '';
  let studentId = '';
  let strangerId = '';
  let coachToken = '';

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
        email: `bat-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student = await users.save(
      users.create({
        email: `bat-student-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const stranger = await users.save(
      users.create({
        email: `bat-stranger-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    coachId = coach.id;
    studentId = student.id;
    strangerId = stranger.id;

    await dataSource.getRepository(CoachStudentLinkEntity).save(
      dataSource.getRepository(CoachStudentLinkEntity).create({
        coachId,
        studentId,
      }),
    );
    await dataSource.getRepository(CoachFinanceSettingsEntity).save(
      dataSource.getRepository(CoachFinanceSettingsEntity).create({
        coachId,
        defaultSessionPriceMinor: '100000',
        currency: 'RUB',
      }),
    );

    const secret = process.env['JWT_ACCESS_SECRET'];
    if (!secret) {
      throw new Error('JWT_ACCESS_SECRET is required for e2e');
    }
    const jwt = new JwtService({ secret });
    coachToken = await jwt.signAsync({
      sub: coachId,
      email: coach.email,
      roles: ['trainer'],
      permissions: [
        'sessions:book_for_student',
        'sessions:read_own',
        'schedules:create',
        'schedules:read_own',
      ],
    });
  });

  afterAll(async () => {
    if (dataSource?.isInitialized) {
      const ids = [coachId, studentId, strangerId];
      await dataSource.query(
        `DELETE FROM session_charges WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM session_history_events WHERE session_id IN (
          SELECT id FROM sessions WHERE coach_id = ANY($1::uuid[])
        )`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM sessions WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM schedule_slots WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM coach_finance_settings WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM coach_student_links WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(`DELETE FROM users WHERE id = ANY($1::uuid[])`, [
        ids,
      ]);
    }
    await app.close();
  });

  it('записывает ученика на время без предварительного слота', async () => {
    const startsAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    startsAt.setUTCMinutes(0, 0, 0);
    const endsAt = new Date(startsAt.getTime() + 60 * 60 * 1000);

    const booked = await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        mode: 'offline',
        studentId,
      })
      .expect(201);

    expect(booked.body.status).toBe('booked');
    expect(booked.body.studentId).toBe(studentId);
    expect(booked.body.scheduleSlotId).toBeTruthy();

    const slots = await request(app.getHttpServer())
      .get('/schedule/slots')
      .set('Authorization', `Bearer ${coachToken}`)
      .query({ from: startsAt.toISOString(), to: endsAt.toISOString() })
      .expect(200);
    const createdSlot = (slots.body as Array<{ id: string; status: string }>).find(
      s => s.id === booked.body.scheduleSlotId,
    );
    expect(createdSlot?.status).toBe('booked');
  });

  it('отклоняет XOR обоих форм и несвязанного ученика', async () => {
    const startsAt = new Date(Date.now() + 8 * 24 * 60 * 60 * 1000);
    startsAt.setUTCMinutes(0, 0, 0);
    const endsAt = new Date(startsAt.getTime() + 60 * 60 * 1000);

    await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        scheduleSlotId: '00000000-0000-4000-8000-000000000001',
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        studentId,
      })
      .expect(400);

    await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        studentId: strangerId,
      })
      .expect(403);
  });

  it('блокирует overlap и createSlot поверх booked', async () => {
    const startsAt = new Date(Date.now() + 9 * 24 * 60 * 60 * 1000);
    startsAt.setUTCMinutes(0, 0, 0);
    const endsAt = new Date(startsAt.getTime() + 60 * 60 * 1000);

    await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        studentId,
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        studentId,
      })
      .expect(409);

    await request(app.getHttpServer())
      .post('/schedule/slots')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        mode: 'offline',
      })
      .expect(409);
  });
});
