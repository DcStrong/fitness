import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { UserEntity } from '../src/database/entity/user.entity';
import { STORAGE, type StoragePort } from '../src/storage/interface';

const STORAGE_BASE = 'http://storage.test/media';

describe('Загрузка изображений и лимит портфолио (e2e)', () => {
  let JPEG: Buffer;
  let SMALL: Buffer;
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let trainerToken: string;
  let studentToken: string;
  const stored = new Map<string, Buffer>();
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const trainerEmail = `media-trainer-${suffix}@example.com`;
  const studentEmail = `media-student-${suffix}@example.com`;
  const password = 'Password123';
  const fakeStorage: StoragePort = {
    /**
     *
     */
    put: async ({ key, body }) => {
      stored.set(key, body);

      return `${STORAGE_BASE}/${key}`;
    },

    /**
     *
     */
    isOwnUrl: url => url.startsWith(`${STORAGE_BASE}/`),
  };

  beforeAll(async () => {
    JPEG = await sharp({ create: { width: 3000, height: 2000, channels: 3, background: '#336699' } })
      .jpeg()
      .toBuffer();
    SMALL = await sharp({ create: { width: 8, height: 8, channels: 3, background: '#336699' } })
      .jpeg()
      .toBuffer();
    process.env['S3_PUBLIC_URL'] = STORAGE_BASE;
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(STORAGE)
      .useValue(fakeStorage)
      .compile();
    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
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
    trainerToken = trainer.body.accessToken as string;
    studentToken = student.body.accessToken as string;
  });

  afterAll(async () => {
    delete process.env['S3_PUBLIC_URL'];
    await dataSource.getRepository(UserEntity).delete([
      { email: trainerEmail },
      { email: studentEmail },
    ]);
    await app.close();
  });

  it('требует авторизацию', async () => {
    await request(app.getHttpServer()).post('/media/images').expect(401);
  });

  it('загружает jpeg и возвращает URL хранилища', async () => {
    const res = await request(app.getHttpServer())
      .post('/media/images')
      .set('Authorization', `Bearer ${trainerToken}`)
      .attach('file', JPEG, { filename: '../../evil.php', contentType: 'image/jpeg' })
      .expect(201);

    expect(res.body).toMatchObject({ contentType: 'image/webp' });
    expect(res.body.url as string).toMatch(
      /^http:\/\/storage\.test\/media\/images\/[0-9a-f-]{36}\/[0-9a-f-]{36}\.webp$/u,
    );
    expect(stored.size).toBe(1);
    const meta = await sharp(stored.values().next().value as Buffer).metadata();
    expect(meta).toMatchObject({ format: 'webp', width: 512 });
    expect(res.body.size).toBe((stored.values().next().value as Buffer).length);
  });

  it('разрешает загрузку ученику (аватар)', async () => {
    await request(app.getHttpServer())
      .post('/media/images')
      .set('Authorization', `Bearer ${studentToken}`)
      .attach('file', JPEG, { filename: 'a.jpg', contentType: 'image/jpeg' })
      .expect(201);
  });

  it('отклоняет не-картинку, даже с заголовком image/jpeg', async () => {
    const res = await request(app.getHttpServer())
      .post('/media/images')
      .set('Authorization', `Bearer ${trainerToken}`)
      .attach('file', Buffer.from('<svg onload=alert(1)>'), {
        filename: 'a.jpg',
        contentType: 'image/jpeg',
      })
      .expect(400);
    expect(res.body.code).toBe('IMAGE_UNSUPPORTED_TYPE');
  });

  it('отклоняет файл больше 5 МБ', async () => {
    await request(app.getHttpServer())
      .post('/media/images')
      .set('Authorization', `Bearer ${trainerToken}`)
      .attach('file', Buffer.concat([SMALL, Buffer.alloc(5 * 1024 * 1024)]), {
        filename: 'big.jpg',
        contentType: 'image/jpeg',
      })
      .expect(413);
  });

  it('требует поле file', async () => {
    const res = await request(app.getHttpServer())
      .post('/media/images')
      .set('Authorization', `Bearer ${trainerToken}`)
      .field('other', 'x')
      .expect(400);
    expect(res.body.code).toBe('IMAGE_MISSING');
  });

  it('принимает URL нашего хранилища и https, отклоняет чужой http', async () => {
    /**
     *
     */
    function put(avatarUrl: string): request.Test {
      return request(app.getHttpServer())
        .put('/profiles/me')
        .set('Authorization', `Bearer ${trainerToken}`)
        .send({ displayName: 'Тренер', avatarUrl });
    }

    await put(`${STORAGE_BASE}/images/u/a.jpg`).expect(200);
    await put('https://example.com/a.jpg').expect(200);
    await put('http://evil.example.com/a.jpg').expect(400);
  });

  describe('пакетная загрузка фото портфолио', () => {
    const MB = 1024 * 1024;
    const MAX_FILE = 5 * MB;

    /**
     *
     */
    function sized(size: number): Buffer {
      return Buffer.concat([SMALL, Buffer.alloc(size - SMALL.length)]);
    }

    /**
     *
     */
    function upload(token: string, buffers: Buffer[]): request.Test {
      let req = request(app.getHttpServer())
        .post('/media/portfolio-images')
        .set('Authorization', `Bearer ${token}`);
      for (const buffer of buffers) {
        req = req.attach('files', buffer, { filename: 'p.jpg', contentType: 'image/jpeg' });
      }

      return req;
    }

    it('принимает большой и маленький файл', async () => {
      const res = await upload(trainerToken, [sized(5 * MB), sized(1000)]).expect(201);
      expect(res.body.items).toHaveLength(2);
    });

    it('принимает 5 файлов по 5 МБ', async () => {
      const res = await upload(trainerToken, Array.from({ length: 5 }, () => sized(5 * MB))).expect(201);
      expect(res.body.items).toHaveLength(5);
    });

    it('отклоняет 6 файлов', async () => {
      await upload(trainerToken, Array.from({ length: 6 }, () => sized(1000))).expect(400);
    });

    it('отклоняет файл больше 5 МБ кодом IMAGE_TOO_LARGE', async () => {
      const res = await upload(trainerToken, [sized(1000), sized(MAX_FILE + 100)]).expect(413);
      expect(res.body.code).toBe('IMAGE_TOO_LARGE');
    });

    it('запрещает ученику', async () => {
      await upload(studentToken, [sized(1000)]).expect(403);
    });
  });

  it('одна запись — до 5 фото, лимит фото на каждую запись независим, записей не больше 5', async () => {
    const urls = (n: number): string[] => Array.from({ length: n }, (_, i) => `${STORAGE_BASE}/images/u/${i}.jpg`);
    const post = (imageUrls: string[]): request.Test => request(app.getHttpServer())
      .post('/profiles/me/portfolio')
      .set('Authorization', `Bearer ${trainerToken}`)
      .send({ title: 'Работы', imageUrls });

    const first = await post(urls(3)).expect(201);
    expect(first.body.imageUrls).toEqual(urls(3));
    expect(first.body.imageUrl).toBe(urls(3)[0]);

    // 3 фото в одной записи не ограничивают другую: ещё 5 фото во второй
    const second = await post(urls(5)).expect(201);
    expect(second.body.imageUrls).toHaveLength(5);

    const tooMany = await post(urls(6)).expect(409);
    expect(tooMany.body.code).toBe('PORTFOLIO_ITEM_PHOTOS_LIMIT_REACHED');

    // пакетная загрузка не зависит от других записей: 5 файлов за раз ок, 3 тоже
    const uploadFiles = async (n: number): Promise<request.Response> => {
      const req = request(app.getHttpServer())
        .post('/media/portfolio-images')
        .set('Authorization', `Bearer ${trainerToken}`);
      for (let i = 0; i < n; i++) {
        req.attach('files', SMALL, `f${i}.jpg`);
      }

      return req;
    };
    expect((await uploadFiles(5)).status).toBe(201);
    expect((await uploadFiles(3)).status).toBe(201);

    await request(app.getHttpServer())
      .put(`/profiles/me/portfolio/${first.body.id as string}`)
      .set('Authorization', `Bearer ${trainerToken}`)
      .send({ title: 'Работы', imageUrls: urls(5) })
      .expect(200);

    for (const id of [first.body.id as string, second.body.id as string]) {
      await request(app.getHttpServer())
        .delete(`/profiles/me/portfolio/${id}`)
        .set('Authorization', `Bearer ${trainerToken}`)
        .expect(204);
    }
  });

  it('ограничивает портфолио пятью записями и возвращает PORTFOLIO_LIMIT_REACHED на шестой', async () => {
    /**
     *
     */
    function add(): request.Test {
      return request(app.getHttpServer())
        .post('/profiles/me/portfolio')
        .set('Authorization', `Bearer ${trainerToken}`)
        .send({ title: 'Фото', imageUrls: Array.from({ length: 5 }, (_, i) => `${STORAGE_BASE}/images/u/p${i}.jpg`) });
    }

    for (let i = 0; i < 5; i++) {
      await add().expect(201);
    }
    const res = await add().expect(409);
    expect(res.body.code).toBe('PORTFOLIO_LIMIT_REACHED');
  });
});
