import { MigrationInterface, QueryRunner } from 'typeorm';

export class BookingRequestsAndContacts1752840000000
  implements MigrationInterface {
  name = 'BookingRequestsAndContacts1752840000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "user_profiles"
        ADD COLUMN "phone" character varying(20),
        ADD COLUMN "telegram_username" character varying(32),
        ADD COLUMN "preferred_contact_channels" character varying[] NOT NULL DEFAULT '{}',
        ADD CONSTRAINT "CHK_user_profiles_phone" CHECK (
          "phone" IS NULL OR "phone" ~ '^\\+[1-9][0-9]{7,14}$'
        ),
        ADD CONSTRAINT "CHK_user_profiles_telegram" CHECK (
          "telegram_username" IS NULL OR "telegram_username" ~ '^[A-Za-z][A-Za-z0-9_]{4,31}$'
        ),
        ADD CONSTRAINT "CHK_user_profiles_contact_channels" CHECK (
          "preferred_contact_channels" <@ ARRAY['phone','telegram','email']::character varying[]
        ),
        ADD CONSTRAINT "CHK_user_profiles_contact_values" CHECK (
          (NOT ('phone' = ANY("preferred_contact_channels")) OR "phone" IS NOT NULL)
          AND (NOT ('telegram' = ANY("preferred_contact_channels")) OR "telegram_username" IS NOT NULL)
        )
    `);
    await queryRunner.query(`
      CREATE TABLE "booking_requests" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "schedule_slot_id" uuid NOT NULL,
        "status" character varying(16) NOT NULL,
        "quoted_price_minor" bigint NOT NULL,
        "quoted_currency" char(3) NOT NULL,
        "expires_at" TIMESTAMPTZ NOT NULL,
        "resolved_by" uuid,
        "resolved_at" TIMESTAMPTZ,
        "rejection_reason" character varying(32),
        "rejection_comment" character varying(500),
        "resolution" character varying(24),
        "resolved_schedule_slot_id" uuid,
        "session_id" uuid,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_booking_requests" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_booking_requests_session" UNIQUE ("session_id"),
        CONSTRAINT "CHK_booking_requests_status" CHECK (
          "status" IN ('pending','accepted','rejected','withdrawn','expired')
        ),
        CONSTRAINT "CHK_booking_requests_price" CHECK ("quoted_price_minor" > 0),
        CONSTRAINT "CHK_booking_requests_currency" CHECK ("quoted_currency" = 'RUB'),
        CONSTRAINT "CHK_booking_requests_rejection_reason" CHECK (
          "rejection_reason" IS NULL OR "rejection_reason" IN ('time_unavailable','plans_changed','other')
        ),
        CONSTRAINT "CHK_booking_requests_resolution" CHECK (
          "resolution" IS NULL OR "resolution" IN ('requested_slot','alternate_slot')
        ),
        CONSTRAINT "FK_booking_requests_coach" FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_booking_requests_student" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_booking_requests_slot" FOREIGN KEY ("schedule_slot_id") REFERENCES "schedule_slots"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_booking_requests_resolver" FOREIGN KEY ("resolved_by") REFERENCES "users"("id") ON DELETE SET NULL,
        CONSTRAINT "FK_booking_requests_resolved_slot" FOREIGN KEY ("resolved_schedule_slot_id") REFERENCES "schedule_slots"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_booking_requests_session" FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_booking_requests_pending_slot"
      ON "booking_requests" ("schedule_slot_id") WHERE "status" = 'pending'
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_booking_requests_pending_pair"
      ON "booking_requests" ("coach_id", "student_id") WHERE "status" = 'pending'
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_booking_requests_coach_status_expiry"
      ON "booking_requests" ("coach_id", "status", "expires_at")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_booking_requests_student_created"
      ON "booking_requests" ("student_id", "created_at" DESC)
    `);
    await queryRunner.query(`
      CREATE TABLE "booking_request_events" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "booking_request_id" uuid NOT NULL,
        "event_type" character varying(16) NOT NULL,
        "actor_id" uuid,
        "metadata" jsonb NOT NULL DEFAULT '{}',
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_booking_request_events" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_booking_request_events_type" CHECK (
          "event_type" IN ('created','accepted','rejected','withdrawn','expired')
        ),
        CONSTRAINT "FK_booking_request_events_request" FOREIGN KEY ("booking_request_id")
          REFERENCES "booking_requests"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_booking_request_events_actor" FOREIGN KEY ("actor_id")
          REFERENCES "users"("id") ON DELETE SET NULL
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_booking_request_events_request_created"
      ON "booking_request_events" ("booking_request_id", "created_at")
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "booking_request_events"`);
    await queryRunner.query(`DROP TABLE "booking_requests"`);
    await queryRunner.query(`
      ALTER TABLE "user_profiles"
        DROP CONSTRAINT "CHK_user_profiles_contact_values",
        DROP CONSTRAINT "CHK_user_profiles_contact_channels",
        DROP CONSTRAINT "CHK_user_profiles_telegram",
        DROP CONSTRAINT "CHK_user_profiles_phone",
        DROP COLUMN "preferred_contact_channels",
        DROP COLUMN "telegram_username",
        DROP COLUMN "phone"
    `);
  }
}
