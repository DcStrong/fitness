import { MigrationInterface, QueryRunner } from 'typeorm';

export class RecurringBookings1754300000000 implements MigrationInterface {
  name = 'RecurringBookings1754300000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "recurring_bookings" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "weekdays" smallint[] NOT NULL,
        "start_minute" integer NOT NULL,
        "mode" character varying(16) NOT NULL,
        "timezone" character varying(64) NOT NULL,
        "status" character varying(16) NOT NULL DEFAULT 'active',
        "horizon_weeks_override" integer,
        "cancelled_at" TIMESTAMPTZ,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_recurring_bookings" PRIMARY KEY ("id"),
        CONSTRAINT "FK_recurring_bookings_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_recurring_bookings_student"
          FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_recurring_bookings_start"
          CHECK ("start_minute" >= 0 AND "start_minute" < 1440),
        CONSTRAINT "CHK_recurring_bookings_mode"
          CHECK ("mode" IN ('online', 'offline')),
        CONSTRAINT "CHK_recurring_bookings_status"
          CHECK ("status" IN ('active', 'cancelled')),
        CONSTRAINT "CHK_recurring_bookings_horizon"
          CHECK (
            "horizon_weeks_override" IS NULL
            OR ("horizon_weeks_override" > 0 AND "horizon_weeks_override" <= 52)
          ),
        CONSTRAINT "CHK_recurring_bookings_weekdays"
          CHECK (cardinality("weekdays") >= 1)
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_recurring_bookings_coach"
      ON "recurring_bookings" ("coach_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_recurring_bookings_student"
      ON "recurring_bookings" ("student_id")
    `);

    await queryRunner.query(`
      CREATE TABLE "recurring_booking_overrides" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "recurring_booking_id" uuid NOT NULL,
        "local_date" date NOT NULL,
        "type" character varying(16) NOT NULL,
        "new_start_minute" integer,
        "new_local_date" date,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_recurring_booking_overrides" PRIMARY KEY ("id"),
        CONSTRAINT "FK_recurring_overrides_booking"
          FOREIGN KEY ("recurring_booking_id")
          REFERENCES "recurring_bookings"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_recurring_overrides_type"
          CHECK ("type" IN ('skip', 'reschedule')),
        CONSTRAINT "CHK_recurring_overrides_new_start"
          CHECK (
            "new_start_minute" IS NULL
            OR ("new_start_minute" >= 0 AND "new_start_minute" < 1440)
          )
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_recurring_override_booking_date"
      ON "recurring_booking_overrides" ("recurring_booking_id", "local_date")
    `);

    await queryRunner.query(`
      ALTER TABLE "sessions"
      ADD COLUMN "recurring_booking_id" uuid,
      ADD COLUMN "recurring_local_date" date
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_sessions_recurring_booking"
      ON "sessions" ("recurring_booking_id")
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_sessions_recurring_occurrence"
      ON "sessions" ("recurring_booking_id", "recurring_local_date")
      WHERE "recurring_booking_id" IS NOT NULL
        AND "recurring_local_date" IS NOT NULL
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX IF EXISTS "UQ_sessions_recurring_occurrence"`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS "IDX_sessions_recurring_booking"`,
    );
    await queryRunner.query(`
      ALTER TABLE "sessions"
      DROP COLUMN IF EXISTS "recurring_local_date",
      DROP COLUMN IF EXISTS "recurring_booking_id"
    `);
    await queryRunner.query(
      `DROP TABLE IF EXISTS "recurring_booking_overrides"`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS "recurring_bookings"`);
  }
}
