import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import request, { type Response } from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { CoachFinanceSettingsEntity } from '../src/database/entity/coach-finance-settings.entity';
import { CoachStudentLinkEntity } from '../src/database/entity/coach-student-link.entity';
import { UserEntity } from '../src/database/entity/user.entity';
import type { ScheduleSlotMode } from '../src/schedules/interface';

const MILLISECONDS_PER_MINUTE = 60 * 1000;
const MILLISECONDS_PER_HOUR = 60 * MILLISECONDS_PER_MINUTE;

function futureDate(offsetHours: number): Date {
  const offset = offsetHours * MILLISECONDS_PER_HOUR;

  return new Date(Date.now() + offset);
}

describe('Заявки на бронирование (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let coachId = '';
  let studentId = '';
  let secondStudentId = '';
  let foreignCoachId = '';
  let coachToken = '';
  let studentToken = '';
  let secondStudentToken = '';
  let foreignCoachToken = '';

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
        email: `requests-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student = await users.save(
      users.create({
        email: `requests-student-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const secondStudent = await users.save(
      users.create({
        email: `requests-student-2-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const foreignCoach = await users.save(
      users.create({
        email: `requests-coach-foreign-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    coachId = coach.id;
    studentId = student.id;
    secondStudentId = secondStudent.id;
    foreignCoachId = foreignCoach.id;
    await dataSource.getRepository(CoachStudentLinkEntity).save([
      { coachId, studentId, sourceInvitationId: null },
      { coachId, studentId: secondStudentId, sourceInvitationId: null },
    ]);
    await dataSource.getRepository(CoachFinanceSettingsEntity).save({
      coachId,
      defaultSessionPriceMinor: '175000',
      currency: 'RUB',
    });
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
        'schedules:create',
        'schedules:read_own',
        'schedules:delete_own',
        'booking_requests:read_inbox',
        'booking_requests:respond',
      ],
    });
    studentToken = await jwt.signAsync({
      sub: studentId,
      email: student.email,
      roles: ['student'],
      permissions: [
        'schedules:read_linked',
        'sessions:book_self',
        'booking_requests:create',
        'booking_requests:read_own',
      ],
    });
    secondStudentToken = await jwt.signAsync({
      sub: secondStudentId,
      email: secondStudent.email,
      roles: ['student'],
      permissions: [
        'schedules:read_linked',
        'booking_requests:create',
        'booking_requests:read_own',
      ],
    });
    foreignCoachToken = await jwt.signAsync({
      sub: foreignCoachId,
      email: foreignCoach.email,
      roles: ['trainer'],
      permissions: [
        'booking_requests:read_inbox',
        'booking_requests:respond',
      ],
    });
  });

  afterEach(async () => {
    await dataSource.transaction(async manager => {
      await manager.query(
        `DROP TRIGGER IF EXISTS "TRG_e2e_fail_booking_charge"
         ON "session_charges"`,
      );
      await manager.query(
        `DROP FUNCTION IF EXISTS "e2e_fail_booking_charge"()`,
      );
      await manager.query(
        `DELETE FROM "booking_request_events"
         WHERE "booking_request_id" IN (
           SELECT "id" FROM "booking_requests" WHERE "coach_id" = $1
         )`,
        [coachId],
      );
      await manager.query(`DELETE FROM "booking_requests" WHERE "coach_id" = $1`, [
        coachId,
      ]);
      await manager.query(`DELETE FROM "session_charges" WHERE "coach_id" = $1`, [
        coachId,
      ]);
      await manager.query(`DELETE FROM "sessions" WHERE "coach_id" = $1`, [
        coachId,
      ]);
      await manager.query(`DELETE FROM "schedule_slots" WHERE "coach_id" = $1`, [
        coachId,
      ]);
      await manager.query(
        `UPDATE "coach_finance_settings"
         SET "default_session_price_minor" = '175000'
         WHERE "coach_id" = $1`,
        [coachId],
      );
      await manager.query(
        `INSERT INTO "coach_student_links"
           ("coach_id", "student_id", "source_invitation_id")
         VALUES ($1, $2, NULL), ($1, $3, NULL)
         ON CONFLICT ("coach_id", "student_id") DO NOTHING`,
        [coachId, studentId, secondStudentId],
      );
    });
  });

  afterAll(async () => {
    if (dataSource?.isInitialized && coachId) {
      await dataSource.transaction(async manager => {
        await manager.query(
          `DELETE FROM "booking_request_events"
           WHERE "booking_request_id" IN (
             SELECT "id" FROM "booking_requests" WHERE "coach_id" = $1
           )`,
          [coachId],
        );
        await manager.query(`DELETE FROM "booking_requests" WHERE "coach_id" = $1`, [
          coachId,
        ]);
        await manager.query(`DELETE FROM "session_charges" WHERE "coach_id" = $1`, [
          coachId,
        ]);
        await manager.query(`DELETE FROM "sessions" WHERE "coach_id" = $1`, [
          coachId,
        ]);
        await manager.query(`DELETE FROM "schedule_slots" WHERE "coach_id" = $1`, [
          coachId,
        ]);
        await manager.query(
          `DELETE FROM "coach_finance_settings" WHERE "coach_id" = $1`,
          [coachId],
        );
        await manager.query(
          `DELETE FROM "coach_student_links" WHERE "coach_id" = $1`,
          [coachId],
        );
        await manager.query(
          `DELETE FROM "users" WHERE "id" IN ($1, $2, $3, $4)`,
          [coachId, studentId, secondStudentId, foreignCoachId],
        );
      });
    }
    await app?.close();
  });

  async function createSlot(
    offsetHours: number,
    durationMinutes = 60,
    mode: ScheduleSlotMode = 'offline',
  ): Promise<Response> {
    const startsAt = futureDate(offsetHours);
    const duration = durationMinutes * MILLISECONDS_PER_MINUTE;
    const endsAt = new Date(
      startsAt.getTime() + duration,
    );

    return request(app.getHttpServer())
      .post('/schedule/slots')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        mode,
      })
      .expect(201);
  }

  async function createBookingRequest(
    slotId: string,
    token = studentToken,
  ): Promise<Response> {
    return request(app.getHttpServer())
      .post('/booking-requests')
      .set('Authorization', `Bearer ${token}`)
      .send({ scheduleSlotId: slotId });
  }

  it('удерживает слот и атомарно создаёт Session с quoted charge', async () => {
    const startsAt = futureDate(24);
    const endsAt = new Date(
      startsAt.getTime() + MILLISECONDS_PER_HOUR,
    );
    const slot = await request(app.getHttpServer())
      .post('/schedule/slots')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        mode: 'online',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ scheduleSlotId: slot.body.id })
      .expect(403);

    const created = await request(app.getHttpServer())
      .post('/booking-requests')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ scheduleSlotId: slot.body.id })
      .expect(201);
    expect(created.body).toMatchObject({
      status: 'pending',
      quotedPriceMinor: '175000',
      quotedCurrency: 'RUB',
      counterpart: { id: coachId, label: 'Тренер' },
    });
    expect(JSON.stringify(created.body)).not.toContain('@example.com');

    const availability = await request(app.getHttpServer())
      .get(`/schedule/coaches/${coachId}/slots`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(availability.body).toEqual([]);

    await request(app.getHttpServer())
      .delete(`/schedule/slots/${slot.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(409);

    const accepted = await request(app.getHttpServer())
      .post(`/booking-requests/${created.body.id}/accept`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);
    expect(accepted.body).toMatchObject({
      status: 'accepted',
      resolution: 'requested_slot',
      resolvedScheduleSlotId: slot.body.id,
    });
    expect(accepted.body.sessionId).toEqual(expect.any(String));

    const charge = await dataSource.query(
      `SELECT "amount_minor", "currency"
       FROM "session_charges" WHERE "session_id" = $1`,
      [accepted.body.sessionId],
    );
    expect(charge).toEqual([{ amount_minor: '175000', currency: 'RUB' }]);
  });

  it('обеспечивает one-pending ограничения при конкурентном создании', async () => {
    const firstSlot = await createSlot(30);
    const secondSlot = await createSlot(32);
    const samePair = await Promise.all([
      createBookingRequest(firstSlot.body.id),
      createBookingRequest(secondSlot.body.id),
    ]);
    expect(
      samePair.map(response => response.status).sort((a, b) => a - b),
    ).toEqual([201, 409]);
    const pending = samePair.find(response => response.status === 201);
    await request(app.getHttpServer())
      .post(`/booking-requests/${pending?.body.id}/withdraw`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(201);

    const sharedSlot = await createSlot(34);
    const sameSlot = await Promise.all([
      createBookingRequest(sharedSlot.body.id, studentToken),
      createBookingRequest(sharedSlot.body.id, secondStudentToken),
    ]);
    expect(
      sameSlot.map(response => response.status).sort((a, b) => a - b),
    ).toEqual([201, 409]);
    expect(
      await dataSource.query(
        `SELECT COUNT(*)::int AS "count" FROM "booking_requests"
         WHERE "schedule_slot_id" = $1 AND "status" = 'pending'`,
        [sharedSlot.body.id],
      ),
    ).toEqual([{ count: 1 }]);
  });

  it('при конкурентном accept создаёт Session, charge и event ровно один раз', async () => {
    const slot = await createSlot(36);
    const created = await createBookingRequest(slot.body.id);
    expect(created.status).toBe(201);
    await request(app.getHttpServer())
      .post(`/booking-requests/${created.body.id}/accept`)
      .set('Authorization', `Bearer ${foreignCoachToken}`)
      .expect(403);

    const accepted = await Promise.all([
      request(app.getHttpServer())
        .post(`/booking-requests/${created.body.id}/accept`)
        .set('Authorization', `Bearer ${coachToken}`),
      request(app.getHttpServer())
        .post(`/booking-requests/${created.body.id}/accept`)
        .set('Authorization', `Bearer ${coachToken}`),
    ]);
    expect(
      accepted.map(response => response.status).sort((a, b) => a - b),
    ).toEqual([201, 409]);
    const rows = await dataSource.query(
      `SELECT
         (SELECT COUNT(*)::int FROM "sessions" WHERE "schedule_slot_id" = $1) AS "sessions",
         (SELECT COUNT(*)::int FROM "session_charges" charge
          JOIN "sessions" session ON session.id = charge.session_id
          WHERE session.schedule_slot_id = $1) AS "charges",
         (SELECT COUNT(*)::int FROM "booking_request_events"
          WHERE "booking_request_id" = $2 AND "event_type" = 'accepted') AS "events"`,
      [slot.body.id, created.body.id],
    );
    expect(rows).toEqual([{ sessions: 1, charges: 1, events: 1 }]);
  });

  it('сохраняет quote при изменении finance settings', async () => {
    const slot = await createSlot(38);
    const created = await createBookingRequest(slot.body.id);
    await dataSource.query(
      `UPDATE "coach_finance_settings"
       SET "default_session_price_minor" = '250000'
       WHERE "coach_id" = $1`,
      [coachId],
    );
    const accepted = await request(app.getHttpServer())
      .post(`/booking-requests/${created.body.id}/accept`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);
    const charge = await dataSource.query(
      `SELECT "amount_minor" FROM "session_charges" WHERE "session_id" = $1`,
      [accepted.body.sessionId],
    );
    expect(charge).toEqual([{ amount_minor: '175000' }]);
  });

  it('откатывает request, slot и Session при ошибке создания charge', async () => {
    const slot = await createSlot(39);
    const created = await createBookingRequest(slot.body.id);
    await dataSource.query(`
      CREATE FUNCTION "e2e_fail_booking_charge"() RETURNS trigger AS $$
      BEGIN
        IF NEW.coach_id = '${coachId}'::uuid THEN
          RAISE EXCEPTION 'forced charge failure';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);
    await dataSource.query(`
      CREATE TRIGGER "TRG_e2e_fail_booking_charge"
      BEFORE INSERT ON "session_charges"
      FOR EACH ROW EXECUTE FUNCTION "e2e_fail_booking_charge"()
    `);

    await request(app.getHttpServer())
      .post(`/booking-requests/${created.body.id}/accept`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(500);
    expect(
      await dataSource.query(
        `SELECT "status", "session_id", "resolved_schedule_slot_id"
         FROM "booking_requests" WHERE "id" = $1`,
        [created.body.id],
      ),
    ).toEqual([
      {
        status: 'pending',
        session_id: null,
        resolved_schedule_slot_id: null,
      },
    ]);
    expect(
      await dataSource.query(
        `SELECT "status" FROM "schedule_slots" WHERE "id" = $1`,
        [slot.body.id],
      ),
    ).toEqual([{ status: 'open' }]);
    expect(
      await dataSource.query(
        `SELECT COUNT(*)::int AS "count" FROM "sessions"
         WHERE "schedule_slot_id" = $1`,
        [slot.body.id],
      ),
    ).toEqual([{ count: 0 }]);
  });

  it('атомарно withdraw/reject/expiry освобождают hold без дублирования событий', async () => {
    const withdrawnSlot = await createSlot(40);
    const withdrawn = await createBookingRequest(withdrawnSlot.body.id);
    await request(app.getHttpServer())
      .post(`/booking-requests/${withdrawn.body.id}/withdraw`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(201);

    const rejectedSlot = await createSlot(42);
    const rejected = await createBookingRequest(rejectedSlot.body.id);
    await request(app.getHttpServer())
      .post(`/booking-requests/${rejected.body.id}/reject`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({})
      .expect(400);
    const rejection = await request(app.getHttpServer())
      .post(`/booking-requests/${rejected.body.id}/reject`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ reason: 'plans_changed', comment: 'Нужно перенести' })
      .expect(201);
    expect(rejection.body).toMatchObject({
      status: 'rejected',
      rejectionReason: 'plans_changed',
      rejectionComment: 'Нужно перенести',
    });

    const expiredSlot = await createSlot(44);
    const expired = await createBookingRequest(expiredSlot.body.id);
    await dataSource.query(
      `UPDATE "booking_requests" SET "expires_at" = NOW() - INTERVAL '1 minute'
       WHERE "id" = $1`,
      [expired.body.id],
    );
    await request(app.getHttpServer())
      .get(`/schedule/coaches/${coachId}/slots`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    await request(app.getHttpServer())
      .get('/booking-requests/mine')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    const expiryEvents = await dataSource.query(
      `SELECT COUNT(*)::int AS "count" FROM "booking_request_events"
       WHERE "booking_request_id" = $1 AND "event_type" = 'expired'`,
      [expired.body.id],
    );
    expect(expiryEvents).toEqual([{ count: 1 }]);

    const availability = await request(app.getHttpServer())
      .get(`/schedule/coaches/${coachId}/slots`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    expect(availability.body.map((slot: { id: string }) => slot.id)).toEqual(
      expect.arrayContaining([
        withdrawnSlot.body.id,
        rejectedSlot.body.id,
        expiredSlot.body.id,
      ]),
    );
    await request(app.getHttpServer())
      .delete(`/schedule/slots/${expiredSlot.body.id}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    const ownSlots = await request(app.getHttpServer())
      .get('/schedule/slots')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(ownSlots.body.map((slot: { id: string }) => slot.id)).not.toContain(
      expiredSlot.body.id,
    );
  });

  it('alternate отклоняет конфликт и создаёт корректный one-off booking', async () => {
    const original = await createSlot(48, 90, 'online');
    const created = await createBookingRequest(original.body.id);
    const conflict = await createSlot(52, 60, 'offline');
    await request(app.getHttpServer())
      .post(`/booking-requests/${created.body.id}/alternate`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ startsAt: conflict.body.startsAt })
      .expect(409);

    const alternateStartsAt = futureDate(56);
    const accepted = await request(app.getHttpServer())
      .post(`/booking-requests/${created.body.id}/alternate`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ startsAt: alternateStartsAt.toISOString() })
      .expect(201);
    expect(accepted.body).toMatchObject({
      status: 'accepted',
      resolution: 'alternate_slot',
    });
    const slots = await dataSource.query(
      `SELECT "id", "starts_at", "ends_at", "mode", "status", "series_id"
       FROM "schedule_slots" WHERE "id" IN ($1, $2) ORDER BY "id"`,
      [original.body.id, accepted.body.resolvedScheduleSlotId],
    );
    const originalRow = slots.find(
      (slot: { id: string }) => slot.id === original.body.id,
    );
    const resolvedRow = slots.find(
      (slot: { id: string }) =>
        slot.id === accepted.body.resolvedScheduleSlotId,
    );
    if (!originalRow || !resolvedRow) {
      throw new Error('Expected original and resolved slots');
    }
    expect(originalRow.status).toBe('open');
    expect(resolvedRow).toMatchObject({
      mode: 'online',
      status: 'booked',
      series_id: null,
    });
    expect(
      new Date(resolvedRow.ends_at).getTime() -
        new Date(resolvedRow.starts_at).getTime(),
    ).toBe(90 * 60 * 1000);
    const persisted = await dataSource.query(
      `SELECT
         (SELECT COUNT(*)::int FROM "sessions" WHERE "id" = $1) AS "sessions",
         (SELECT COUNT(*)::int FROM "session_charges" WHERE "session_id" = $1) AS "charges"`,
      [accepted.body.sessionId],
    );
    expect(persisted).toEqual([{ sessions: 1, charges: 1 }]);
  });

  it('alternate откатывается при исчезнувшей relationship', async () => {
    const original = await createSlot(60, 45, 'offline');
    const created = await createBookingRequest(original.body.id);
    await dataSource.query(
      `DELETE FROM "coach_student_links"
       WHERE "coach_id" = $1 AND "student_id" = $2`,
      [coachId, studentId],
    );
    const before = await dataSource.query(
      `SELECT COUNT(*)::int AS "count" FROM "schedule_slots"
       WHERE "coach_id" = $1`,
      [coachId],
    );
    await request(app.getHttpServer())
      .post(`/booking-requests/${created.body.id}/alternate`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: futureDate(64).toISOString(),
      })
      .expect(403);
    const after = await dataSource.query(
      `SELECT COUNT(*)::int AS "count" FROM "schedule_slots"
       WHERE "coach_id" = $1`,
      [coachId],
    );
    expect(after).toEqual(before);
    expect(
      await dataSource.query(
        `SELECT "status", "session_id" FROM "booking_requests" WHERE "id" = $1`,
        [created.body.id],
      ),
    ).toEqual([{ status: 'pending', session_id: null }]);
  });
});
