import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { CoachFinanceSettingsEntity } from '../src/database/entity/coach-finance-settings.entity';
import { CoachStudentLinkEntity } from '../src/database/entity/coach-student-link.entity';
import { ScheduleSlotEntity } from '../src/database/entity/schedule-slot.entity';
import { UserEntity } from '../src/database/entity/user.entity';
import { occurrenceToUtcRange } from '../src/recurring-bookings/util/occurrences.util';
import { addLocalDays, formatZonedDate, localDateWeekday } from '../src/schedules/util/zoned-time.util';

describe('Повторяющаяся запись (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let coachId = '';
  let studentId = '';
  let otherCoachId = '';
  let coachToken = '';
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
        email: `recur-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student = await users.save(
      users.create({
        email: `recur-student-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const other = await users.save(
      users.create({
        email: `recur-other-${suffix}@example.com`,
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
    const coachPerms = [
      'sessions:book_for_student',
      'sessions:read_own',
      'sessions:cancel',
      'schedules:create',
      'schedules:read_own',
    ];
    coachToken = await jwt.signAsync({
      sub: coachId,
      email: coach.email,
      roles: ['trainer'],
      permissions: coachPerms,
    });
    otherCoachToken = await jwt.signAsync({
      sub: otherCoachId,
      email: other.email,
      roles: ['trainer'],
      permissions: coachPerms,
    });
  });

  afterAll(async () => {
    if (dataSource?.isInitialized) {
      const ids = [coachId, studentId, otherCoachId];
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
        `DELETE FROM recurring_booking_overrides WHERE recurring_booking_id IN (
          SELECT id FROM recurring_bookings WHERE coach_id = ANY($1::uuid[])
        )`,
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

  it('создаёт серию, бронирует слоты и идемпотентен на sync', async () => {
    await request(app.getHttpServer())
      .put('/schedule/availability/settings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        timezone: 'Europe/Moscow',
        defaultDurationMinutes: 60,
        breakMinutes: 0,
        horizonWeeks: 2,
        onlineDurationMinutes: null,
        offlineDurationMinutes: null,
        defaultMode: 'offline',
      })
      .expect(200);

    const timezone = 'Europe/Moscow';
    const today = formatZonedDate(new Date(), timezone);
    let monday = today;
    while (localDateWeekday(monday) !== 1) {
      monday = addLocalDays(monday, 1);
    }
    const startMinute = 18 * 60;
    const slots = dataSource.getRepository(ScheduleSlotEntity);
    for (const offset of [0, 7]) {
      const localDate = addLocalDays(monday, offset);
      const range = occurrenceToUtcRange({
        localDate,
        startMinute,
        durationMinutes: 60,
        timezone,
      });
      await slots.save(
        slots.create({
          coachId,
          startsAt: range.startsAt,
          endsAt: range.endsAt,
          mode: 'offline',
          status: 'open',
          seriesId: null,
          gymId: null,
          capacity: 1,
        }),
      );
    }

    const created = await request(app.getHttpServer())
      .post('/recurring-bookings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        studentId,
        weekdays: [1],
        startMinute,
        mode: 'offline',
      })
      .expect(201);
    expect(created.body.booking.status).toBe('active');
    expect(created.body.sync.booked).toBeGreaterThanOrEqual(1);

    const again = await request(app.getHttpServer())
      .post(`/recurring-bookings/${created.body.booking.id}/sync`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);
    expect(again.body.booked).toBe(0);
    expect(again.body.skippedExisting).toBeGreaterThanOrEqual(1);

    await request(app.getHttpServer())
      .post('/recurring-bookings')
      .set('Authorization', `Bearer ${otherCoachToken}`)
      .send({
        studentId,
        weekdays: [1],
        startMinute,
        mode: 'offline',
      })
      .expect(403);
  });

  it('автосоздаёт слоты при пустом календаре и позволяет skip для mode_mismatch', async () => {
    const timezone = 'Europe/Moscow';
    const today = formatZonedDate(new Date(), timezone);
    let wednesday = today;
    while (localDateWeekday(wednesday) !== 3) {
      wednesday = addLocalDays(wednesday, 1);
    }

    const autoCreated = await request(app.getHttpServer())
      .post('/recurring-bookings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        studentId,
        weekdays: [3],
        startMinute: 10 * 60,
        mode: 'offline',
        horizonWeeksOverride: 1,
      })
      .expect(201);
    expect(autoCreated.body.sync.booked).toBeGreaterThanOrEqual(1);
    expect(autoCreated.body.sync.slotsCreated).toBeGreaterThanOrEqual(1);
    expect(
      autoCreated.body.sync.conflicts.some(
        (c: { reason: string }) => c.reason === 'missing_slot',
      ),
    ).toBe(false);

    await request(app.getHttpServer())
      .post(`/recurring-bookings/${autoCreated.body.booking.id}/cancel`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);

    const startMinute = 14 * 60;
    const range = occurrenceToUtcRange({
      localDate: wednesday,
      startMinute,
      durationMinutes: 60,
      timezone,
    });
    const slots = dataSource.getRepository(ScheduleSlotEntity);
    await slots.save(
      slots.create({
        coachId,
        startsAt: range.startsAt,
        endsAt: range.endsAt,
        mode: 'online',
        status: 'open',
        seriesId: null,
        gymId: null,
        capacity: 1,
      }),
    );

    const mismatched = await request(app.getHttpServer())
      .post('/recurring-bookings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        studentId,
        weekdays: [3],
        startMinute,
        mode: 'offline',
        horizonWeeksOverride: 1,
      })
      .expect(201);
    expect(
      mismatched.body.sync.conflicts.some(
        (c: { reason: string }) => c.reason === 'mode_mismatch',
      ),
    ).toBe(true);

    const conflictDate = mismatched.body.sync.conflicts.find(
      (c: { reason: string }) => c.reason === 'mode_mismatch',
    ).localDate as string;
    await request(app.getHttpServer())
      .post(
        `/recurring-bookings/${mismatched.body.booking.id}/occurrences/${conflictDate}/resolve`,
      )
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ type: 'skip' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/recurring-bookings/${mismatched.body.booking.id}/cancel`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201)
      .expect(res => {
        expect(res.body.status).toBe('cancelled');
      });
  });

  it('не создаёт active-дубликат и реактивирует cancelled twin', async () => {
    const startMinute = 11 * 60;
    const payload = {
      studentId,
      weekdays: [2],
      startMinute,
      mode: 'offline' as const,
      horizonWeeksOverride: 1,
    };

    const first = await request(app.getHttpServer())
      .post('/recurring-bookings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send(payload)
      .expect(201);
    const firstId = first.body.booking.id as string;

    const listed = await request(app.getHttpServer())
      .get('/recurring-bookings')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    const row = (listed.body as Array<{ id: string }>).find(b => b.id === firstId);
    expect(row).toMatchObject({
      id: firstId,
      studentEmail: expect.stringContaining('@'),
    });
    expect(row).toHaveProperty('studentDisplayName');
    expect(row).toHaveProperty('nextOccurrenceLocalDate');
    expect(
      (row as { nextOccurrenceLocalDate: string | null }).nextOccurrenceLocalDate,
    ).toMatch(/^\d{4}-\d{2}-\d{2}$/);

    const duplicate = await request(app.getHttpServer())
      .post('/recurring-bookings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send(payload)
      .expect(409);
    expect(duplicate.body.existingId).toBe(firstId);
    expect(duplicate.body.message).toMatch(/уже есть/i);

    await request(app.getHttpServer())
      .post(`/recurring-bookings/${firstId}/cancel`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);

    const restored = await request(app.getHttpServer())
      .post(`/recurring-bookings/${firstId}/restore`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);
    expect(restored.body.booking.id).toBe(firstId);
    expect(restored.body.booking.status).toBe('active');
    expect(restored.body.sync).toBeDefined();

    await request(app.getHttpServer())
      .post(`/recurring-bookings/${firstId}/cancel`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);

    const reactivated = await request(app.getHttpServer())
      .post('/recurring-bookings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send(payload)
      .expect(201);
    expect(reactivated.body.booking.id).toBe(firstId);
    expect(reactivated.body.booking.status).toBe('active');
    expect(reactivated.body.booking.cancelledAt).toBeNull();
  });
});
