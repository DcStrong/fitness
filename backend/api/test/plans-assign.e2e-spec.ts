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

describe('Assign plans and session workout (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let coachId = '';
  let studentId = '';
  let student2Id = '';
  let strangerId = '';
  let coachToken = '';
  let studentToken = '';
  let student2Token = '';

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
        email: `asg-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student = await users.save(
      users.create({
        email: `asg-student-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student2 = await users.save(
      users.create({
        email: `asg-student2-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const stranger = await users.save(
      users.create({
        email: `asg-stranger-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    coachId = coach.id;
    studentId = student.id;
    student2Id = student2.id;
    strangerId = stranger.id;

    const links = dataSource.getRepository(CoachStudentLinkEntity);
    await links.save(links.create({ coachId, studentId }));
    await links.save(links.create({ coachId, studentId: student2Id }));
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
      'plans:delete_own',
      'exercises:manage_own',
      'exercises:read_own',
      'tags:create',
      'tags:read_own',
      'tags:assign',
      'sessions:book_for_student',
      'sessions:read_own',
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
      permissions: ['plans:read_visible', 'sessions:read_own'],
    });
    student2Token = await jwt.signAsync({
      sub: student2Id,
      email: student2.email,
      roles: ['student'],
      permissions: ['plans:read_visible', 'sessions:read_own'],
    });
  });

  afterAll(async () => {
    if (dataSource?.isInitialized) {
      const ids = [coachId, studentId, student2Id, strangerId];
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
        `DELETE FROM training_plans WHERE owner_coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM exercises WHERE owner_coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(`DELETE FROM tags WHERE creator_id = ANY($1::uuid[])`, [
        ids,
      ]);
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

  it('назначает шаблон, привязывает к сессии и не даёт ученику PATCH', async () => {
    const exercise = await request(app.getHttpServer())
      .post('/exercises')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ name: `Жим-${Date.now()}`, kind: 'weight_reps' })
      .expect(201);

    const template = await request(app.getHttpServer())
      .post('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        title: 'Верх',
        goal: 'hypertrophy',
        notes: 'цель — сила',
        exercises: [
          {
            exerciseId: exercise.body.id,
            restSeconds: 90,
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

    expect(assigned.body).toHaveLength(1);
    expect(assigned.body[0].kind).toBe('student_copy');
    expect(assigned.body[0].assignedStudentId).toBe(studentId);
    expect(assigned.body[0].parentTemplateId).toBe(template.body.id);
    expect(assigned.body[0].exercises).toHaveLength(1);
    const copyId = assigned.body[0].id as string;

    const again = await request(app.getHttpServer())
      .post(`/plans/${template.body.id}/assign`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentIds: [studentId] })
      .expect(201);
    expect(again.body[0].id).toBe(copyId);

    await request(app.getHttpServer())
      .post(`/plans/${template.body.id}/assign`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentIds: [strangerId] })
      .expect(403);

    await request(app.getHttpServer())
      .patch(`/plans/${copyId}`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ title: 'Взлом' })
      .expect(403);

    const customized = await request(app.getHttpServer())
      .patch(`/plans/${copyId}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        exercises: [
          {
            exerciseId: exercise.body.id,
            restSeconds: 60,
            sets: [{ reps: 6, weightKg: 50 }],
          },
        ],
      })
      .expect(200);
    expect(customized.body.exercises[0].sets[0].reps).toBe(6);

    const source = await request(app.getHttpServer())
      .get(`/plans/${template.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(source.body.exercises[0].sets[0].reps).toBe(10);

    const listed = await request(app.getHttpServer())
      .get('/plans')
      .query({ kind: 'assigned', studentId })
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(listed.body.some((plan: { id: string }) => plan.id === copyId)).toBe(
      true,
    );

    const own = await request(app.getHttpServer())
      .get('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(own.body.every((plan: { kind: string }) => plan.kind === 'template')).toBe(
      true,
    );

    const studentCopies = await request(app.getHttpServer())
      .get('/plans')
      .query({ kind: 'assigned' })
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(
      studentCopies.body.some((plan: { id: string }) => plan.id === copyId),
    ).toBe(true);

    const startsAt = new Date(Date.now() + 11 * 24 * 60 * 60 * 1000);
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

    const attached = await request(app.getHttpServer())
      .patch(`/sessions/${booked.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentPlanId: copyId })
      .expect(200);
    expect(attached.body.studentPlanId).toBe(copyId);
    expect(attached.body.plan.title).toBe('Верх');
    expect(attached.body.plan.exercises[0].sets[0].reps).toBe(6);

    const fetched = await request(app.getHttpServer())
      .get(`/sessions/${booked.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(fetched.body.studentPlanId).toBe(copyId);
    expect(fetched.body.plan.goal).toBe('hypertrophy');

    await request(app.getHttpServer())
      .patch(`/sessions/${booked.body.id}`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ studentPlanId: copyId })
      .expect(403);

    const copy2 = await request(app.getHttpServer())
      .post(`/plans/${template.body.id}/assign`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentIds: [student2Id] })
      .expect(201);

    await request(app.getHttpServer())
      .patch(`/sessions/${booked.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentPlanId: copy2.body[0].id })
      .expect(400);

    const detached = await request(app.getHttpServer())
      .patch(`/sessions/${booked.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ studentPlanId: null })
      .expect(200);
    expect(detached.body.studentPlanId).toBeNull();
    void student2Token;
  });

  it('назначает шаблон двум ученикам через тег', async () => {
    const tag = await request(app.getHttpServer())
      .post('/tags')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ name: `Группа-${Date.now()}` })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/tags/${tag.body.id}/users`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ userId: studentId })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/tags/${tag.body.id}/users`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ userId: student2Id })
      .expect(201);

    const template = await request(app.getHttpServer())
      .post('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ title: 'Общая' })
      .expect(201);

    const assigned = await request(app.getHttpServer())
      .post(`/plans/${template.body.id}/assign`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ tagIds: [tag.body.id] })
      .expect(201);

    expect(assigned.body).toHaveLength(2);
    const studentIds = assigned.body.map(
      (plan: { assignedStudentId: string }) => plan.assignedStudentId,
    );
    expect(studentIds.sort()).toEqual([studentId, student2Id].sort());
  });
});
