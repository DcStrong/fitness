import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from './../src/app.module';
import { UserEntity } from '../src/database/entity/user.entity';

describe('Auth (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  const trainerEmail = `trainer-${Date.now()}@example.com`;
  const studentEmail = `student-${Date.now()}@example.com`;
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
  });

  afterAll(async () => {
    await dataSource.getRepository(UserEntity).delete([
      { email: trainerEmail },
      { email: studentEmail },
    ]);
    await app.close();
  });

  it('GET /health', () => request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect({ status: 'ok' }));

  it('register trainer → me → refresh → logout', async () => {
    const register = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        email: trainerEmail,
        password,
        role: 'trainer',
        displayName: 'Анна Тренер',
      })
      .expect(201);

    expect(register.body.accessToken).toBeDefined();
    expect(register.body.refreshToken).toBeDefined();
    expect(register.body.user.displayName).toBe('Анна Тренер');
    expect(register.body.user.roles).toContain('trainer');
    expect(register.body.user.permissions).toContain('users:read_self');

    const me = await request(app.getHttpServer())
      .get('/users/me')
      .set('Authorization', `Bearer ${register.body.accessToken}`)
      .expect(200);

    expect(me.body.email).toBe(trainerEmail);
    expect(me.body.displayName).toBe('Анна Тренер');

    const refreshed = await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: register.body.refreshToken })
      .expect(201);

    expect(refreshed.body.accessToken).toBeDefined();

    await request(app.getHttpServer())
      .post('/auth/logout')
      .send({ refreshToken: refreshed.body.refreshToken })
      .expect(201);

    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: refreshed.body.refreshToken })
      .expect(401);
  });

  it('register student and reject admin self-register', async () => {
    const student = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email: studentEmail, password, role: 'student' })
      .expect(201);

    expect(student.body.user.roles).toContain('student');

    await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        email: `admin-${Date.now()}@example.com`,
        password,
        role: 'admin',
      })
      .expect(400);
  });

  it('login with email and password', async () => {
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: trainerEmail, password })
      .expect(201);

    expect(login.body.user.email).toBe(trainerEmail);
  });
});
