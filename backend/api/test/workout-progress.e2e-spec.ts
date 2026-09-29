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

describe('Workout progress (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let coachId = '';
  let studentId = '';
  let strangerId = '';
  let coachToken = '';
  let studentToken = '';
  let strangerToken = '';

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
        email: `prg-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student = await users.save(
      users.create({
        email: `prg-student-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const stranger = await users.save(
      users.create({
        email: `prg-stranger-${suffix}@example.com`,
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
        'plans:create',
        'plans:read_own',
        'exercises:manage_own',
        'sessions:book_for_student',
        'sessions:read_own',
        'sessions:complete',
        'sessions:cancel',
      ],
    });
    studentToken = await jwt.signAsync({
      sub: studentId,
      email: student.email,
      roles: ['student'],
      permissions: ['sessions:read_own', 'plans:read_visible'],
    });
    strangerToken = await jwt.signAsync({
      sub: strangerId,
      email: stranger.email,
      roles: ['student'],
      permissions: ['sessions:read_own'],
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
        `DELETE FROM sessions WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM training_plans WHERE owner_coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM exercises WHERE owner_coach_id = ANY($1::uuid[])`,
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

  async function bookSession(offsetDays: number): Promise<string> {
    const startsAt = new Date(Date.now() + offsetDays * 24 * 60 * 60 * 1000);
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

    return booked.body.id as string;
  }

  it('две completed сессии дают две точки; чужой 403', async () => {
    const exercise = await request(app.getHttpServer())
      .post('/exercises')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ name: `Жим-${Date.now()}`, kind: 'weight_reps' })
      .expect(201);
    const exerciseId = exercise.body.id as string;

    const template = await request(app.getHttpServer())
      .post('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        title: 'Жим прогресс',
        goal: 'hypertrophy',
        exercises: [
          {
            exerciseId,
            sets: [{ reps: 10, weightKg: 40 }],
          },
        ],
      })
      .expect(201);

    const assigned = await request(app.getHttpServer())
      .post(`/plans/${template.body.id}/assign`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentIds: [studentId] })
      .expect(201);
    const copyId = assigned.body[0].id as string;

    const firstId = await bookSession(12);
    await request(app.getHttpServer())
      .patch(`/sessions/${firstId}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentPlanId: copyId })
      .expect(200);
    await request(app.getHttpServer())
      .post(`/sessions/${firstId}/complete`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        logs: [
          {
            exerciseId,
            sets: [{ reps: 10, weightKg: 40 }],
          },
        ],
      })
      .expect(201);

    const secondId = await bookSession(13);
    await request(app.getHttpServer())
      .patch(`/sessions/${secondId}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentPlanId: copyId })
      .expect(200);
    await request(app.getHttpServer())
      .post(`/sessions/${secondId}/complete`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        logs: [
          {
            exerciseId,
            sets: [{ reps: 8, weightKg: 50 }],
          },
        ],
      })
      .expect(201);

    const cancelledId = await bookSession(14);
    await request(app.getHttpServer())
      .post(`/sessions/${cancelledId}/cancel`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({})
      .expect(201);

    const progress = await request(app.getHttpServer())
      .get(`/students/${studentId}/progress`)
      .query({ exerciseId })
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);

    expect(progress.body.points).toHaveLength(2);
    expect(progress.body.points[0].weightKg).toBe(40);
    expect(progress.body.points[1].weightKg).toBe(50);
    expect(progress.body.goal).toBe('hypertrophy');

    const asStudent = await request(app.getHttpServer())
      .get(`/students/${studentId}/progress`)
      .query({ exerciseId })
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(asStudent.body.points).toHaveLength(2);

    await request(app.getHttpServer())
      .get(`/students/${studentId}/progress`)
      .query({ exerciseId })
      .set('Authorization', `Bearer ${strangerToken}`)
      .expect(403);

    const logsCount = await dataSource.query(
      `SELECT COUNT(*)::int AS count FROM session_set_logs WHERE session_id = $1`,
      [cancelledId],
    );
    expect(logsCount[0].count).toBe(0);

    const copiedId = await bookSession(15);
    await request(app.getHttpServer())
      .patch(`/sessions/${copiedId}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentPlanId: copyId })
      .expect(200);
    await request(app.getHttpServer())
      .post(`/sessions/${copiedId}/complete`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({})
      .expect(201);
    const copiedLogs = await dataSource.query(
      `SELECT COUNT(*)::int AS count FROM session_set_logs WHERE session_id = $1`,
      [copiedId],
    );
    expect(copiedLogs[0].count).toBe(1);
  });
});
