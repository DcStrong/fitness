import { randomUUID } from 'crypto';
import type { Server } from 'http';
import type { AddressInfo } from 'net';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import { io, type Socket } from 'socket.io-client';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { CoachFinanceSettingsEntity } from '../src/database/entity/coach-finance-settings.entity';
import { CoachStudentLinkEntity } from '../src/database/entity/coach-student-link.entity';
import { UserEntity } from '../src/database/entity/user.entity';

const CHAT_PERMISSIONS = ['chat:read_own', 'chat:send_own'];
const SOCKET_TIMEOUT_MS = 5000;

/**
 * Resolves with the first payload of `event`, or rejects after a timeout.
 */
function nextEvent<T>(socket: Socket, event: string): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new Error(`No ${event} within ${SOCKET_TIMEOUT_MS}ms`)),
      SOCKET_TIMEOUT_MS,
    );
    socket.once(event, (payload: T) => {
      clearTimeout(timer);
      resolve(payload);
    });
  });
}

describe('Чат тренер↔ученик (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let baseUrl = '';
  let coachId = '';
  let studentId = '';
  let strangerId = '';
  let coachToken = '';
  let studentToken = '';
  let strangerToken = '';
  let noChatToken = '';
  let conversationId = '';
  const sockets: Socket[] = [];

  /**
   *
   */
  function connect(token: string | null): Socket {
    const socket = io(`${baseUrl}/chat`, {
      transports: ['websocket'],
      reconnection: false,
      ...token !== null ? { auth: { token } } : {},
    });
    sockets.push(socket);

    return socket;
  }

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
    await app.listen(0);
    const server = app.getHttpServer() as unknown as Server;
    const address = server.address() as AddressInfo;
    baseUrl = `http://127.0.0.1:${address.port}`;
    dataSource = app.get(DataSource);

    const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const users = dataSource.getRepository(UserEntity);
    const coach = await users.save(
      users.create({ email: `chat-coach-${suffix}@example.com`, passwordHash: 'x' }),
    );
    const student = await users.save(
      users.create({ email: `chat-student-${suffix}@example.com`, passwordHash: 'x' }),
    );
    const stranger = await users.save(
      users.create({ email: `chat-stranger-${suffix}@example.com`, passwordHash: 'x' }),
    );
    coachId = coach.id;
    studentId = student.id;
    strangerId = stranger.id;
    await dataSource
      .getRepository(CoachStudentLinkEntity)
      .save({ coachId, studentId, sourceInvitationId: null });
    await dataSource.getRepository(CoachFinanceSettingsEntity).save({
      coachId,
      defaultSessionPriceMinor: '100000',
      currency: 'RUB',
    });

    const secret = process.env['JWT_ACCESS_SECRET'];
    if (!secret) {
      throw new Error('JWT_ACCESS_SECRET is required for e2e');
    }
    const jwt = new JwtService({ secret });
    coachToken = await jwt.signAsync(
      {
        sub: coachId,
        email: coach.email,
        roles: ['trainer'],
        permissions: [
          ...CHAT_PERMISSIONS,
          'sessions:book_for_student',
          'sessions:read_own',
          'sessions:cancel',
          'schedules:create',
          'booking_requests:read_inbox',
          'booking_requests:respond',
        ],
      },
      { expiresIn: '15m' },
    );
    studentToken = await jwt.signAsync(
      {
        sub: studentId,
        email: student.email,
        roles: ['student'],
        permissions: [
          ...CHAT_PERMISSIONS,
          'schedules:read_linked',
          'booking_requests:create',
          'booking_requests:read_own',
        ],
      },
      { expiresIn: '15m' },
    );
    strangerToken = await jwt.signAsync(
      {
        sub: strangerId,
        email: stranger.email,
        roles: ['student'],
        permissions: CHAT_PERMISSIONS,
      },
      { expiresIn: '15m' },
    );
    noChatToken = await jwt.signAsync(
      { sub: strangerId, email: stranger.email, roles: [], permissions: [] },
      { expiresIn: '15m' },
    );
  });

  afterAll(async () => {
    for (const socket of sockets) {
      socket.disconnect();
    }
    if (dataSource?.isInitialized) {
      const ids = [coachId, studentId, strangerId];
      await dataSource.query(
        `DELETE FROM chat_conversations WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM booking_requests WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM session_charges WHERE coach_id = ANY($1::uuid[])`,
        [ids],
      );
      await dataSource.query(
        `DELETE FROM session_history_events WHERE session_id IN (
          SELECT id FROM sessions WHERE coach_id = ANY($1::uuid[]))`,
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

  it('открывает один диалог на пару и не пускает без связи', async () => {
    const first = await request(app.getHttpServer())
      .post('/chats')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ counterpartId: studentId })
      .expect(200);
    const second = await request(app.getHttpServer())
      .post('/chats')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ counterpartId: coachId })
      .expect(200);

    expect(second.body.id).toBe(first.body.id);
    expect(first.body.myRole).toBe('coach');
    expect(second.body.myRole).toBe('student');
    expect(first.body.counterpart.id).toBe(studentId);
    conversationId = first.body.id as string;

    await request(app.getHttpServer())
      .post('/chats')
      .set('Authorization', `Bearer ${strangerToken}`)
      .send({ counterpartId: coachId })
      .expect(403);
  });

  it('пустой диалог не попадает в список', async () => {
    const list = await request(app.getHttpServer())
      .get('/chats')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);

    expect(list.body).toEqual([]);
  });

  it('отправляет сообщение идемпотентно по clientId', async () => {
    const clientId = randomUUID();
    const sent = await request(app.getHttpServer())
      .post(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ clientId, body: '  Можно сегодня в 11:15?  ' })
      .expect(201);
    const retry = await request(app.getHttpServer())
      .post(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ clientId, body: 'Можно сегодня в 11:15?' })
      .expect(201);

    expect(sent.body.body).toBe('Можно сегодня в 11:15?');
    expect(sent.body.kind).toBe('text');
    expect(retry.body.id).toBe(sent.body.id);

    const page = await request(app.getHttpServer())
      .get(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(page.body.items).toHaveLength(1);
  });

  it('отклоняет пустое сообщение', async () => {
    await request(app.getHttpServer())
      .post(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ clientId: randomUUID(), body: '   ' })
      .expect(400);
  });

  it('чужой диалог отдаёт 404', async () => {
    await request(app.getHttpServer())
      .get(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${strangerToken}`)
      .expect(404);
    await request(app.getHttpServer())
      .post(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${strangerToken}`)
      .send({ clientId: randomUUID(), body: 'привет' })
      .expect(404);
  });

  it('считает непрочитанные и сбрасывает их по read', async () => {
    const list = await request(app.getHttpServer())
      .get('/chats')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(list.body).toHaveLength(1);
    expect(list.body[0].unreadCount).toBe(1);
    expect(list.body[0].lastMessage.body).toBe('Можно сегодня в 11:15?');

    const total = await request(app.getHttpServer())
      .get('/chats/unread-count')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(total.body.total).toBe(1);

    const studentTotal = await request(app.getHttpServer())
      .get('/chats/unread-count')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(studentTotal.body.total).toBe(0);

    await request(app.getHttpServer())
      .post(`/chats/${conversationId}/read`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ upToMessageId: list.body[0].lastMessage.id })
      .expect(200);

    const after = await request(app.getHttpServer())
      .get('/chats/unread-count')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(after.body.total).toBe(0);
  });

  it('пагинирует по курсору after/before', async () => {
    for (const body of ['раз', 'два', 'три']) {
      await request(app.getHttpServer())
        .post(`/chats/${conversationId}/messages`)
        .set('Authorization', `Bearer ${coachToken}`)
        .send({ clientId: randomUUID(), body })
        .expect(201);
    }
    const all = await request(app.getHttpServer())
      .get(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    const ids = (all.body.items as Array<{ id: string; body: string; }>).map(
      item => item.body,
    );
    expect(ids).toEqual(['Можно сегодня в 11:15?', 'раз', 'два', 'три']);

    const first = all.body.items[0].id as string;
    const last = all.body.items[3].id as string;
    const newer = await request(app.getHttpServer())
      .get(`/chats/${conversationId}/messages?after=${first}&limit=2`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(newer.body.items.map((item: { body: string; }) => item.body)).toEqual([
      'раз',
      'два',
    ]);
    expect(newer.body.hasMore).toBe(true);

    const none = await request(app.getHttpServer())
      .get(`/chats/${conversationId}/messages?after=${last}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(none.body.items).toEqual([]);

    const older = await request(app.getHttpServer())
      .get(`/chats/${conversationId}/messages?before=${last}&limit=2`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(older.body.items.map((item: { body: string; }) => item.body)).toEqual([
      'раз',
      'два',
    ]);
  });

  it('доставляет сообщение собеседнику через WebSocket', async () => {
    const coachSocket = connect(coachToken);
    await nextEvent(coachSocket, 'connect');
    const received = nextEvent<{ body: string; conversationId: string; }>(
      coachSocket,
      'message.created',
    );

    await request(app.getHttpServer())
      .post(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ clientId: randomUUID(), body: 'Спасибо!' })
      .expect(201);

    const payload = await received;
    expect(payload.body).toBe('Спасибо!');
    expect(payload.conversationId).toBe(conversationId);
  });

  it('отключает сокет без токена или без права chat:read_own', async () => {
    const anonymous = connect(null);
    await nextEvent(anonymous, 'disconnect');
    const noRights = connect(noChatToken);
    await nextEvent(noRights, 'disconnect');

    expect(anonymous.connected).toBe(false);
    expect(noRights.connected).toBe(false);
  });

  it('пишет системные сообщения о записи и отмене занятия', async () => {
    const startsAt = new Date(Date.now() + (9 * 24 * 60 * 60 * 1000));
    startsAt.setUTCMinutes(0, 0, 0);
    const endsAt = new Date(startsAt.getTime() + (60 * 60 * 1000));
    const studentSocket = connect(studentToken);
    await nextEvent(studentSocket, 'connect');
    const bookedEvent = nextEvent<{ systemType: string; }>(
      studentSocket,
      'message.created',
    );

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
    expect((await bookedEvent).systemType).toBe('session_booked');

    await request(app.getHttpServer())
      .post(`/sessions/${booked.body.id}/cancel`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ note: 'Заболел' })
      .expect(201);

    const page = await request(app.getHttpServer())
      .get(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    const system = (
      page.body.items as Array<{
        kind: string;
        systemType: string;
        body: string;
        payload: { sessionId: string; note: string | null; };
      }>
    ).filter(item => item.kind === 'system');

    expect(system.map(item => item.systemType)).toEqual([
      'session_booked',
      'session_cancelled',
    ]);
    expect(system[1]!.payload.sessionId).toBe(booked.body.id);
    expect(system[1]!.payload.note).toBe('Заболел');
    expect(system[1]!.body).toBe('Занятие отменено: Заболел');

    const unread = await request(app.getHttpServer())
      .get('/chats/unread-count')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    // The student's own «Спасибо!» marked the coach's earlier messages read,
    // so only the two system messages are new.
    expect(unread.body.total).toBe(2);
  });

  it('пишет системные сообщения об ответах на заявки', async () => {
    /**
     *
     */
    async function requestSlot(offsetDays: number): Promise<string> {
      const startsAt = new Date(Date.now() + (offsetDays * 24 * 60 * 60 * 1000));
      startsAt.setUTCMinutes(0, 0, 0);
      const slot = await request(app.getHttpServer())
        .post('/schedule/slots')
        .set('Authorization', `Bearer ${coachToken}`)
        .send({
          startsAt: startsAt.toISOString(),
          endsAt: new Date(startsAt.getTime() + (60 * 60 * 1000)).toISOString(),
          mode: 'offline',
        })
        .expect(201);
      const created = await request(app.getHttpServer())
        .post('/booking-requests')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ scheduleSlotId: slot.body.id })
        .expect(201);

      return created.body.id as string;
    }

    // A student may hold one pending request per coach, so answer each in turn.
    const toAccept = await requestSlot(11);
    await request(app.getHttpServer())
      .post(`/booking-requests/${toAccept}/accept`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);
    const toAlternate = await requestSlot(12);
    const alternateAt = new Date(Date.now() + (14 * 24 * 60 * 60 * 1000));
    alternateAt.setUTCMinutes(0, 0, 0);
    await request(app.getHttpServer())
      .post(`/booking-requests/${toAlternate}/alternate`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ startsAt: alternateAt.toISOString() })
      .expect(201);
    const toReject = await requestSlot(13);
    await request(app.getHttpServer())
      .post(`/booking-requests/${toReject}/reject`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ reason: 'time_unavailable', comment: 'Уезжаю' })
      .expect(201);

    const page = await request(app.getHttpServer())
      .get(`/chats/${conversationId}/messages`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    const system = (
      page.body.items as Array<{
        systemType: string | null;
        payload: { bookingRequestId?: string; startsAt?: string; } | null;
      }>
    ).filter(item => item.systemType?.startsWith('request_'));

    expect(system.map(item => item.systemType)).toEqual([
      'request_accepted',
      'request_alternate',
      'request_rejected',
    ]);
    expect(system[1]!.payload?.startsAt).toBe(alternateAt.toISOString());
    expect(system[2]!.payload?.bookingRequestId).toBe(toReject);
  });
});
