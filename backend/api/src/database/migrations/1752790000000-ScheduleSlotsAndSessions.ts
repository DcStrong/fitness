import { MigrationInterface, QueryRunner } from 'typeorm';

export class ScheduleSlotsAndSessions1752790000000
  implements MigrationInterface {
  name = 'ScheduleSlotsAndSessions1752790000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "schedule_slots" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "coach_id" uuid NOT NULL,
        "starts_at" TIMESTAMPTZ NOT NULL,
        "ends_at" TIMESTAMPTZ NOT NULL,
        "mode" character varying(16) NOT NULL DEFAULT 'offline',
        "status" character varying(16) NOT NULL DEFAULT 'open',
        "series_id" uuid,
        "gym_id" uuid,
        "capacity" integer NOT NULL DEFAULT 1,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_schedule_slots" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_schedule_slots_range" CHECK ("ends_at" > "starts_at"),
        CONSTRAINT "CHK_schedule_slots_status" CHECK ("status" IN ('open', 'booked', 'blocked')),
        CONSTRAINT "CHK_schedule_slots_mode" CHECK ("mode" IN ('online', 'offline')),
        CONSTRAINT "CHK_schedule_slots_capacity" CHECK ("capacity" >= 1),
        CONSTRAINT "FK_schedule_slots_coach" FOREIGN KEY ("coach_id")
          REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_schedule_slots_coach_starts"
        ON "schedule_slots" ("coach_id", "starts_at")
    `);

    await queryRunner.query(`
      CREATE TABLE "sessions" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "schedule_slot_id" uuid NOT NULL,
        "starts_at" TIMESTAMPTZ NOT NULL,
        "ends_at" TIMESTAMPTZ NOT NULL,
        "mode" character varying(16) NOT NULL DEFAULT 'offline',
        "status" character varying(16) NOT NULL DEFAULT 'booked',
        "created_by" character varying(16) NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_sessions" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_sessions_schedule_slot_id" UNIQUE ("schedule_slot_id"),
        CONSTRAINT "CHK_sessions_range" CHECK ("ends_at" > "starts_at"),
        CONSTRAINT "CHK_sessions_status" CHECK (
          "status" IN ('booked', 'completed', 'cancelled', 'no_show')
        ),
        CONSTRAINT "CHK_sessions_mode" CHECK ("mode" IN ('online', 'offline')),
        CONSTRAINT "CHK_sessions_created_by" CHECK (
          "created_by" IN ('coach', 'student')
        ),
        CONSTRAINT "FK_sessions_coach" FOREIGN KEY ("coach_id")
          REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION,
        CONSTRAINT "FK_sessions_student" FOREIGN KEY ("student_id")
          REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION,
        CONSTRAINT "FK_sessions_slot" FOREIGN KEY ("schedule_slot_id")
          REFERENCES "schedule_slots"("id") ON DELETE RESTRICT ON UPDATE NO ACTION
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_sessions_coach_starts"
        ON "sessions" ("coach_id", "starts_at")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_sessions_student_id" ON "sessions" ("student_id")
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "sessions"`);
    await queryRunner.query(`DROP TABLE "schedule_slots"`);
  }
}
