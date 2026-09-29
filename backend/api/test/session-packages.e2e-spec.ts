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

describe('Session packages (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let coachId = '';
  let studentId = '';
  let coachToken = '';
  let studentToken = '';

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
        email: `pkg-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student = await users.save(
      users.create({
        email: `pkg-student-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    coachId = coach.id;
    studentId = student.id;

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
        'packages:manage',
        'packages:read_own',
        'sessions:book_for_student',
        'sessions:read_own',
        'sessions:complete',
        'sessions:mark_no_show',
        'schedules:create',
        'schedules:read_own',
        'finance:manage_settings',
      ],
    });
    studentToken = await jwt.signAsync({
      sub: studentId,
      email: student.email,
      roles: ['student'],
      permissions: ['packages:read_own', 'sessions:read_own'],
    });
  });

  afterAll(async () => {
    if (dataSource?.isInitialized && coachId) {
      const ids = [coachId, studentId];
      await dataSource.query(
        `DELETE FROM session_package_debits WHERE package_id IN (
          SELECT id FROM session_packages WHERE coach_id = ANY($1::uuid[])
        )`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM session_packages WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM session_history_events WHERE session_id IN (
          SELECT id FROM sessions WHERE coach_id = ANY($1::uuid[])
        )`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM session_charges WHERE coach_id = ANY($1::uuid[])`,
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

  it('выдаёт пакет, списывает при complete, сигналит исчерпание; booking при exhausted ок', async () => {
    const created = await request(app.getHttpServer())
      .post('/session-packages')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentId, totalSessions: 1 })
      .expect(201);

    expect(created.body.remainingSessions).toBe(1);
    expect(created.body.status).toBe('active');
    const packageId = created.body.id as string;

    await request(app.getHttpServer())
      .post('/session-packages')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentId, totalSessions: 4 })
      .expect(409);

    const studentList = await request(app.getHttpServer())
      .get('/session-packages')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(
      studentList.body.some(
        (p: { id: string }) => p.id === packageId,
      ),
    ).toBe(true);

    const startsAt = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
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

    const sessionId = booked.body.id as string;
    expect(booked.body.finance?.status).toBe('pending');

    const completed = await request(app.getHttpServer())
      .post(`/sessions/${sessionId}/complete`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);

    expect(completed.body.status).toBe('completed');
    expect(completed.body.packageExhausted).toBe(true);
    expect(completed.body.finance?.earnedAt).toBeTruthy();
    expect(completed.body.finance?.status).toBe('pending');

    const after = await request(app.getHttpServer())
      .get(`/session-packages/${packageId}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(after.body.remainingSessions).toBe(0);
    expect(after.body.status).toBe('exhausted');

    const startsAt2 = new Date(startsAt.getTime() + 24 * 60 * 60 * 1000);
    const endsAt2 = new Date(startsAt2.getTime() + 60 * 60 * 1000);
    await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt2.toISOString(),
        endsAt: endsAt2.toISOString(),
        mode: 'offline',
        studentId,
      })
      .expect(201);

    const extended = await request(app.getHttpServer())
      .post(`/session-packages/${packageId}/extend`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ addSessions: 3 })
      .expect(201);
    expect(extended.body.status).toBe('active');
    expect(extended.body.remainingSessions).toBe(3);
  });
});
