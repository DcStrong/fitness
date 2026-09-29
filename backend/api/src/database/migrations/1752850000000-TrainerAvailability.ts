import { MigrationInterface, QueryRunner } from 'typeorm';

export class TrainerAvailability1752850000000 implements MigrationInterface {
  name = 'TrainerAvailability1752850000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "coach_schedule_settings" (
        "coach_id" uuid NOT NULL,
        "timezone" character varying(64) NOT NULL DEFAULT 'Europe/Moscow',
        "default_duration_minutes" integer NOT NULL DEFAULT 60,
        "break_minutes" integer NOT NULL DEFAULT 0,
        "horizon_weeks" integer NOT NULL DEFAULT 8,
        "online_duration_minutes" integer,
        "offline_duration_minutes" integer,
        "default_mode" character varying(16) NOT NULL DEFAULT 'offline',
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_coach_schedule_settings" PRIMARY KEY ("coach_id"),
        CONSTRAINT "FK_coach_schedule_settings_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_coach_schedule_settings_duration"
          CHECK ("default_duration_minutes" > 0),
        CONSTRAINT "CHK_coach_schedule_settings_break"
          CHECK ("break_minutes" >= 0),
        CONSTRAINT "CHK_coach_schedule_settings_horizon"
          CHECK ("horizon_weeks" > 0 AND "horizon_weeks" <= 52),
        CONSTRAINT "CHK_coach_schedule_settings_online_duration"
          CHECK ("online_duration_minutes" IS NULL OR "online_duration_minutes" > 0),
        CONSTRAINT "CHK_coach_schedule_settings_offline_duration"
          CHECK ("offline_duration_minutes" IS NULL OR "offline_duration_minutes" > 0),
        CONSTRAINT "CHK_coach_schedule_settings_mode"
          CHECK ("default_mode" IN ('online', 'offline'))
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "schedule_series" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "coach_id" uuid NOT NULL,
        "kind" character varying(32) NOT NULL DEFAULT 'weekly_availability',
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_schedule_series" PRIMARY KEY ("id"),
        CONSTRAINT "FK_schedule_series_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_schedule_series_kind"
          CHECK ("kind" IN ('weekly_availability'))
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_schedule_series_coach_weekly"
      ON "schedule_series" ("coach_id", "kind")
    `);

    await queryRunner.query(`
      CREATE TABLE "availability_windows" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "series_id" uuid NOT NULL,
        "day_of_week" smallint NOT NULL,
        "start_minute" integer NOT NULL,
        "end_minute" integer NOT NULL,
        "mode" character varying(16),
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_availability_windows" PRIMARY KEY ("id"),
        CONSTRAINT "FK_availability_windows_series"
          FOREIGN KEY ("series_id") REFERENCES "schedule_series"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_availability_windows_dow"
          CHECK ("day_of_week" BETWEEN 1 AND 7),
        CONSTRAINT "CHK_availability_windows_range"
          CHECK (
            "start_minute" >= 0
            AND "end_minute" <= 1440
            AND "end_minute" > "start_minute"
          ),
        CONSTRAINT "CHK_availability_windows_mode"
          CHECK ("mode" IS NULL OR "mode" IN ('online', 'offline'))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_availability_windows_series_dow"
      ON "availability_windows" ("series_id", "day_of_week")
    `);

    await queryRunner.query(`
      CREATE TABLE "availability_exceptions" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "series_id" uuid NOT NULL,
        "local_date" date NOT NULL,
        "type" character varying(16) NOT NULL,
        "windows" jsonb,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_availability_exceptions" PRIMARY KEY ("id"),
        CONSTRAINT "FK_availability_exceptions_series"
          FOREIGN KEY ("series_id") REFERENCES "schedule_series"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_availability_exceptions_type"
          CHECK ("type" IN ('closed', 'custom_hours')),
        CONSTRAINT "CHK_availability_exceptions_windows"
          CHECK (
            ("type" = 'closed' AND "windows" IS NULL)
            OR ("type" = 'custom_hours' AND "windows" IS NOT NULL)
          )
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_availability_exceptions_series_date"
      ON "availability_exceptions" ("series_id", "local_date")
    `);

    await queryRunner.query(`
      ALTER TABLE "schedule_slots"
        ADD CONSTRAINT "FK_schedule_slots_series"
        FOREIGN KEY ("series_id") REFERENCES "schedule_series"("id")
        ON DELETE SET NULL
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "schedule_slots" DROP CONSTRAINT IF EXISTS "FK_schedule_slots_series"
    `);
    await queryRunner.query(`DROP TABLE IF EXISTS "availability_exceptions"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "availability_windows"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "schedule_series"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "coach_schedule_settings"`);
  }
}
