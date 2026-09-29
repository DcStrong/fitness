import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { CoachStudentLinkEntity } from '../src/database/entity/coach-student-link.entity';
import { ScheduleSlotEntity } from '../src/database/entity/schedule-slot.entity';
import { SessionEntity } from '../src/database/entity/session.entity';
import { UserEntity } from '../src/database/entity/user.entity';

describe('Финансовый учёт (e2e)', () => {
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
        email: `billing-coach-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    const student = await users.save(
      users.create({
        email: `billing-student-${suffix}@example.com`,
        passwordHash: 'not-used',
      }),
    );
    coachId = coach.id;
    studentId = student.id;

    const links = dataSource.getRepository(CoachStudentLinkEntity);
    await links.save(
      links.create({
        coachId,
        studentId,
        sourceInvitationId: null,
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
        'schedules:create',
        'sessions:book_for_student',
        'sessions:read_own',
        'sessions:complete',
        'sessions:mark_no_show',
        'finance:manage_settings',
        'finance:read_own',
        'finance:mark_paid',
        'finance:record_expense',
        'finance:adjust_own',
      ],
    });
    studentToken = await jwt.signAsync({
      sub: studentId,
      email: student.email,
      roles: ['student'],
      permissions: [
        'sessions:book_self',
        'sessions:read_own',
        'finance:read_own_charge',
      ],
    });
  });

  afterAll(async () => {
    if (dataSource?.isInitialized && coachId && studentId) {
      await dataSource.transaction(async manager => {
        await manager.query(
          `DELETE FROM "finance_ledger_entries" WHERE "coach_id" = $1`,
          [coachId],
        );
        await manager.query(
          `DELETE FROM "session_history_events"
           WHERE "session_id" IN (SELECT "id" FROM "sessions" WHERE "coach_id" = $1)`,
          [coachId],
        );
        await manager.query(
          `DELETE FROM "session_charges" WHERE "coach_id" = $1`,
          [coachId],
        );
        await manager.query(`DELETE FROM "sessions" WHERE "coach_id" = $1`, [
          coachId,
        ]);
        await manager.query(
          `DELETE FROM "schedule_slots" WHERE "coach_id" = $1`,
          [coachId],
        );
        await manager.query(
          `DELETE FROM "coach_student_links" WHERE "coach_id" = $1`,
          [coachId],
        );
        await manager.query(
          `DELETE FROM "coach_finance_settings" WHERE "coach_id" = $1`,
          [coachId],
        );
        await manager.query(`DELETE FROM "users" WHERE "id" IN ($1, $2)`, [
          coachId,
          studentId,
        ]);
      });
    }
    await app?.close();
  });

  it('settings → snapshot → complete → paid → expense → summary и privacy', async () => {
    await request(app.getHttpServer())
      .put('/finance/settings')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ defaultSessionPriceMinor: '150000', currency: 'RUB' })
      .expect(200);

    const startsAt = new Date(Date.now() + 86_400_000);
    const endsAt = new Date(startsAt.getTime() + 3_600_000);
    const slot = await request(app.getHttpServer())
      .post('/schedule/slots')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt.toISOString(),
        endsAt: endsAt.toISOString(),
        mode: 'offline',
      })
      .expect(201);

    const booking = await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ scheduleSlotId: slot.body.id, studentId })
      .expect(201);
    expect(booking.body.finance).toMatchObject({
      status: 'pending',
      amountMinor: '150000',
      currency: 'RUB',
      earnedAt: null,
    });

    const completed = await request(app.getHttpServer())
      .post(`/sessions/${booking.body.id}/complete`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(201);
    expect(completed.body.finance.earnedAt).not.toBeNull();

    await request(app.getHttpServer())
      .post(`/finance/charges/${booking.body.finance.chargeId}/mark-paid`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ paymentMethod: 'cash' })
      .expect(201);

    await request(app.getHttpServer())
      .post('/finance/expenses')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ amountMinor: '25000', category: 'rent' })
      .expect(201);

    const from = new Date(Date.now() - 86_400_000).toISOString();
    const to = new Date(Date.now() + 86_400_000).toISOString();
    const summary = await request(app.getHttpServer())
      .get(`/finance/summary?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`)
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);
    expect(summary.body).toMatchObject({
      accruedMinor: '150000',
      receivedMinor: '150000',
      expensesMinor: '25000',
      netMinor: '125000',
      currency: 'RUB',
    });

    await request(app.getHttpServer())
      .get(`/finance/summary?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`)
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(403);
  });

  it('возвращает legacy Session как not_tracked', async () => {
    const slots = dataSource.getRepository(ScheduleSlotEntity);
    const startsAt = new Date(Date.now() + 172_800_000);
    const slot = await slots.save(
      slots.create({
        coachId,
        startsAt,
        endsAt: new Date(startsAt.getTime() + 3_600_000),
        mode: 'offline',
        status: 'booked',
        seriesId: null,
        gymId: null,
        capacity: 1,
      }),
    );
    const sessions = dataSource.getRepository(SessionEntity);
    const legacy = await sessions.save(
      sessions.create({
        coachId,
        studentId,
        scheduleSlotId: slot.id,
        startsAt: slot.startsAt,
        endsAt: slot.endsAt,
        mode: slot.mode,
        status: 'booked',
        createdBy: 'coach',
      }),
    );

    const response = await request(app.getHttpServer())
      .get('/sessions')
      .set('Authorization', `Bearer ${studentToken}`)
      .expect(200);
    const returned = response.body.find(
      (session: { id: string; }) => session.id === legacy.id,
    );
    expect(returned.finance).toEqual({ status: 'not_tracked' });
  });

  it('требует charge для no-show и отменяет бесплатное начисление', async () => {
    const startsAt = new Date(Date.now() + 259_200_000);
    const slot = await request(app.getHttpServer())
      .post('/schedule/slots')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({
        startsAt: startsAt.toISOString(),
        endsAt: new Date(startsAt.getTime() + 3_600_000).toISOString(),
        mode: 'offline',
      })
      .expect(201);
    const booking = await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ scheduleSlotId: slot.body.id, studentId })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/sessions/${booking.body.id}/no-show`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({})
      .expect(400);

    const noShow = await request(app.getHttpServer())
      .post(`/sessions/${booking.body.id}/no-show`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ charge: false })
      .expect(201);
    expect(noShow.body.status).toBe('no_show');
    expect(noShow.body.finance.status).toBe('cancelled');
  });
});
