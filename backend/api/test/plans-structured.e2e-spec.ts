import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { CoachStudentLinkEntity } from '../src/database/entity/coach-student-link.entity';
import { ExerciseEntity } from '../src/database/entity/exercise.entity';
import { TrainingPlanEntity } from '../src/database/entity/training-plan.entity';
import { UserEntity } from '../src/database/entity/user.entity';

describe('Structured workout templates (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let coachId = '';
  let studentId = '';
  let otherCoachId = '';
  let coachToken = '';
  let studentToken = '';
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
        email: `tpl-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student = await users.save(
      users.create({
        email: `tpl-student-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const other = await users.save(
      users.create({
        email: `tpl-other-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    coachId = coach.id;
    studentId = student.id;
    otherCoachId = other.id;

    await dataSource.getRepository(CoachStudentLinkEntity).save(
      dataSource.getRepository(CoachStudentLinkEntity).create({
        coachId,
        studentId,
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
    ];
    coachToken = await jwt.signAsync({
      sub: coachId,
      email: coach.email,
      roles: ['trainer'],
      permissions: trainerPerms,
    });
    otherCoachToken = await jwt.signAsync({
      sub: otherCoachId,
      email: other.email,
      roles: ['trainer'],
      permissions: trainerPerms,
    });
    studentToken = await jwt.signAsync({
      sub: studentId,
      email: student.email,
      roles: ['student'],
      permissions: ['plans:read_visible', 'exercises:read_own', 'exercises:read_visible', 'tags:read_own'],
    });

    const catalogExists = await dataSource
      .getRepository(TrainingPlanEntity)
      .findOne({ where: { kind: 'catalog_seed' } });
    if (!catalogExists) {
      const catalogExercise = await dataSource.getRepository(ExerciseEntity).save(
        dataSource.getRepository(ExerciseEntity).create({
          name: `Каталог-${suffix}`,
          kind: 'weight_reps',
          ownerCoachId: null,
        }),
      );
      await dataSource.getRepository(TrainingPlanEntity).save(
        dataSource.getRepository(TrainingPlanEntity).create({
          ownerCoachId: coachId,
          title: 'База — верх',
          body: 'seed',
          kind: 'catalog_seed',
          goal: 'hypertrophy',
        }),
      );
      void catalogExercise;
    }
  });

  afterAll(async () => {
    try {
      if (dataSource?.isInitialized && coachId) {
        await dataSource.query(
          `DELETE FROM training_plans WHERE owner_coach_id = ANY($1)`,
          [[coachId, otherCoachId]],
        );
        await dataSource.query(
          `DELETE FROM exercises WHERE owner_coach_id = ANY($1)`,
          [[coachId, otherCoachId]],
        );
        await dataSource.query(`DELETE FROM tags WHERE creator_id = ANY($1)`, [
          [coachId, otherCoachId],
        ]);
        await dataSource.query(
          `DELETE FROM coach_student_links WHERE coach_id = ANY($1)`,
          [[coachId]],
        );
        await dataSource.getRepository(UserEntity).delete([
          { id: coachId },
          { id: studentId },
          { id: otherCoachId },
        ]);
      }
    } finally {
      await app.close();
    }
  });

  it('тренер создаёт структурированный план с тегом, ученик видит его по общему тегу', async () => {
    const tag = await request(app.getHttpServer())
      .post('/tags')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ name: `Ноги-${Date.now()}` })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/tags/${tag.body.id}/users`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ userId: studentId })
      .expect(201);

    const exercise = await request(app.getHttpServer())
      .post('/exercises')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ name: `Присед-${Date.now()}`, kind: 'weight_reps' })
      .expect(201);

    const created = await request(app.getHttpServer())
      .post('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        title: 'Треня на ноги',
        goal: 'hypertrophy',
        notes: 'разминка 5 мин',
        tagIds: [tag.body.id],
        exercises: [
          {
            exerciseId: exercise.body.id,
            restSeconds: 90,
            sets: [{ reps: 10, weightKg: 20 }],
          },
        ],
      })
      .expect(201);

    expect(created.body.kind).toBe('template');
    expect(created.body.goal).toBe('hypertrophy');
    expect(created.body.notes).toBe('разминка 5 мин');
    expect(created.body.body).toBe('разминка 5 мин');
    expect(created.body.exercises).toHaveLength(1);
    expect(created.body.tags[0].id).toBe(tag.body.id);

    const visible = await request(app.getHttpServer())
      .get('/plans/visible')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);

    expect(visible.body.some((plan: { id: string }) => plan.id === created.body.id)).toBe(
      true,
    );
  });

  it('чужой тренер не может обновить план', async () => {
    const created = await request(app.getHttpServer())
      .post('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ title: 'Чужой' })
      .expect(201);

    await request(app.getHttpServer())
      .patch(`/plans/${created.body.id}`)
      .set('Authorization', `Bearer ${otherCoachToken}`)
      .send({ title: 'Взлом' })
      .expect(403);
  });

  it('каталог нельзя мутировать, clone создаёт свой шаблон', async () => {
    const catalog = await dataSource.getRepository(TrainingPlanEntity).findOne({
      where: { kind: 'catalog_seed' },
    });
    if (!catalog) {
      return;
    }

    await request(app.getHttpServer())
      .patch(`/plans/${catalog.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ title: 'Hack' })
      .expect(403);

    const cloned = await request(app.getHttpServer())
      .post(`/plans/${catalog.id}/clone`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);

    expect(cloned.body.kind).toBe('template');
    expect(cloned.body.ownerCoachId).toBe(coachId);
    expect(cloned.body.goal).toBe(catalog.goal);

    const stillCatalog = await dataSource
      .getRepository(TrainingPlanEntity)
      .findOneByOrFail({ id: catalog.id });
    expect(stillCatalog.title).toBe(catalog.title);
    expect(stillCatalog.kind).toBe('catalog_seed');
  });

  it('список своих не смешивает каталог', async () => {
    const own = await request(app.getHttpServer())
      .get('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(
      own.body.every((plan: { kind: string }) => plan.kind === 'template'),
    ).toBe(true);

    const catalog = await request(app.getHttpServer())
      .get('/plans?kind=catalog')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(
      catalog.body.every((plan: { kind: string }) => plan.kind === 'catalog_seed'),
    ).toBe(true);
  });

  it('удаление упражнения из плана даёт 409', async () => {
    const exercise = await request(app.getHttpServer())
      .post('/exercises')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ name: `Ref-${Date.now()}`, kind: 'duration' })
      .expect(201);

    await request(app.getHttpServer())
      .post('/plans')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        title: 'С упражнением',
        exercises: [{ exerciseId: exercise.body.id, sets: [{ durationSeconds: 30 }] }],
      })
      .expect(201);

    await request(app.getHttpServer())
      .delete(`/exercises/${exercise.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(409);
  });

  it('мутация каталожного упражнения запрещена', async () => {
    const catalog = await dataSource
      .getRepository(ExerciseEntity)
      .createQueryBuilder('e')
      .where('e.owner_coach_id IS NULL')
      .getOne();
    if (!catalog) {
      return;
    }
    await request(app.getHttpServer())
      .patch(`/exercises/${catalog.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ name: 'Hack' })
      .expect(403);
  });
});
