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

describe('Программы тренировок и несколько workouts на сессии (e2e)', () => {
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
        email: `wprog-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student = await users.save(
      users.create({
        email: `wprog-student-${suffix}@example.com`,
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
    const trainerPerms = [
      'plans:create',
      'plans:read_own',
      'plans:update_own',
      'exercises:manage_own',
      'exercises:read_own',
      'sessions:book_for_student',
      'sessions:read_own',
      'sessions:complete',
      'sessions:cancel',
    ];
    coachToken = await jwt.signAsync({
      sub: coachId,
      email: coach.email,
      roles: ['trainer'],
      permissions: trainerPerms,
    });
    studentToken = await jwt.signAsync({
      sub: studentId,
      email: student.email,
      roles: ['student'],
      permissions: ['sessions:read_own'],
    });
  });

  afterAll(async () => {
    if (dataSource?.isInitialized) {
      const ids = [coachId, studentId];
      await dataSource.query(
        `DELETE FROM session_prescription_sets WHERE session_workout_item_id IN (
          SELECT id FROM session_workout_items WHERE session_id IN (
            SELECT id FROM sessions WHERE coach_id = ANY($1::uuid[])
          )
        )`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM session_workout_items WHERE session_id IN (
          SELECT id FROM sessions WHERE coach_id = ANY($1::uuid[])
        )`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM session_set_logs WHERE session_id IN (
          SELECT id FROM sessions WHERE coach_id = ANY($1::uuid[])
        )`,
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
        `DELETE FROM workout_program_day_items WHERE program_day_id IN (
          SELECT d.id FROM workout_program_days d
          JOIN workout_programs p ON p.id = d.program_id
          WHERE p.owner_coach_id = ANY($1::uuid[])
        )`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM workout_programs WHERE owner_coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM recurring_bookings WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM schedule_slots WHERE coach_id = ANY($1::uuid[])`,
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

  it('вешает две тренировки, отвергает чужую копию и копирует snapshot при complete', async () => {
    const bench = await request(app.getHttpServer())
      .post('/exercises')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ name: `Жим-${Date.now()}`, kind: 'weight_reps' })
      .expect(201);
    const core = await request(app.getHttpServer())
      .post('/exercises')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ name: `Планка-${Date.now()}`, kind: 'duration' })
      .expect(201);

    const strength = await request(app.getHttpServer())
      .post('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        title: 'Силовая',
        goal: 'hypertrophy',
        exercises: [
          {
            exerciseId: bench.body.id,
            sets: [{ reps: 5, weightKg: 40 }],
          },
        ],
      })
      .expect(201);
    const corePlan = await request(app.getHttpServer())
      .post('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        title: 'Кор',
        goal: 'general',
        exercises: [
          {
            exerciseId: core.body.id,
            sets: [{ durationSeconds: 30 }],
          },
        ],
      })
      .expect(201);

    await request(app.getHttpServer())
      .patch(`/plans/${strength.body.id}/loads`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ items: [{ exerciseId: bench.body.id, weightKg: 80 }] })
      .expect(200);

    const assigned = await request(app.getHttpServer())
      .post('/plans/assign-batch')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        studentId,
        planIds: [strength.body.id, corePlan.body.id],
      })
      .expect(201);
    const copyIds = assigned.body.map((row: { id: string }) => row.id) as string[];

    const startsAt = new Date(Date.now() + 3600_000).toISOString();
    const endsAt = new Date(Date.now() + 7200_000).toISOString();
    const booked = await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentId, startsAt, endsAt, mode: 'offline' })
      .expect(201);

    await request(app.getHttpServer())
      .patch(`/sessions/${booked.body.id}`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ workoutPlanIds: copyIds })
      .expect(403);

    const attached = await request(app.getHttpServer())
      .patch(`/sessions/${booked.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ workoutPlanIds: copyIds })
      .expect(200);
    expect(attached.body.workouts).toHaveLength(2);
    expect(attached.body.studentPlanId).toBe(copyIds[0]);
    expect(attached.body.workouts[0].exercises[0].sets[0].weightKg).toBe(80);

    await request(app.getHttpServer())
      .patch(`/plans/${copyIds[0]}/loads`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ items: [{ exerciseId: bench.body.id, weightKg: 90 }] })
      .expect(200);

    const fetched = await request(app.getHttpServer())
      .get(`/sessions/${booked.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(fetched.body.workouts[0].exercises[0].sets[0].weightKg).toBe(80);

    await request(app.getHttpServer())
      .post(`/sessions/${booked.body.id}/complete`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);

    const series = await request(app.getHttpServer())
      .post('/recurring-bookings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        studentId,
        weekdays: [1, 4, 6],
        startMinute: 13 * 60,
        mode: 'offline',
        horizonWeeksOverride: 2,
      })
      .expect(201);

    await request(app.getHttpServer())
      .put(`/recurring-bookings/${series.body.booking.id}/program`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        horizonWeeks: 2,
        days: [{ weekday: 2, items: [{ templateId: strength.body.id }] }],
      })
      .expect(400);

    const program = await request(app.getHttpServer())
      .put(`/recurring-bookings/${series.body.booking.id}/program`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        horizonWeeks: 2,
        days: [
          { weekday: 1, items: [{ templateId: strength.body.id }] },
          { weekday: 4, items: [{ templateId: corePlan.body.id }] },
          { weekday: 6, items: [{ templateId: strength.body.id }] },
        ],
        progressionRules: [
          {
            exerciseId: bench.body.id,
            startWeightKg: 80,
            deltaKg: 5,
            incrementKg: 2.5,
          },
        ],
      })
      .expect(200);
    expect(program.body.days).toHaveLength(3);
    const benchPreview = program.body.preview.filter(
      (point: { exerciseId: string }) => point.exerciseId === bench.body.id,
    ) as Array<{ weightKg: number }>;
    if (benchPreview.length > 0) {
      expect(benchPreview[benchPreview.length - 1]?.weightKg).toBe(85);
    }

    const again = await request(app.getHttpServer())
      .put(`/recurring-bookings/${series.body.booking.id}/program`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        horizonWeeks: 2,
        days: [
          { weekday: 1, items: [{ templateId: strength.body.id }] },
          { weekday: 4, items: [{ templateId: corePlan.body.id }] },
          { weekday: 6, items: [{ templateId: strength.body.id }] },
        ],
        progressionRules: [
          {
            exerciseId: bench.body.id,
            startWeightKg: 80,
            deltaKg: 5,
          },
        ],
      })
      .expect(200);
    expect(again.body.id).toBe(program.body.id);
  });
});
