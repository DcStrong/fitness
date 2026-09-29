import { MigrationInterface, QueryRunner } from 'typeorm';

export class SessionPackages1754500000000 implements MigrationInterface {
  name = 'SessionPackages1754500000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "session_packages" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "total_sessions" integer NOT NULL,
        "remaining_sessions" integer NOT NULL,
        "expires_at" TIMESTAMPTZ,
        "status" character varying(16) NOT NULL DEFAULT 'active',
        "archived_at" TIMESTAMPTZ,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_session_packages" PRIMARY KEY ("id"),
        CONSTRAINT "FK_session_packages_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_packages_student"
          FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_session_packages_total"
          CHECK ("total_sessions" > 0),
        CONSTRAINT "CHK_session_packages_remaining"
          CHECK ("remaining_sessions" >= 0 AND "remaining_sessions" <= "total_sessions"),
        CONSTRAINT "CHK_session_packages_status"
          CHECK ("status" IN ('active', 'exhausted', 'expired', 'archived'))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_session_packages_coach"
      ON "session_packages" ("coach_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_session_packages_student"
      ON "session_packages" ("student_id")
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_session_packages_active_pair"
      ON "session_packages" ("coach_id", "student_id")
      WHERE "status" = 'active'
    `);

    await queryRunner.query(`
      CREATE TABLE "session_package_debits" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "package_id" uuid NOT NULL,
        "session_id" uuid NOT NULL,
        "delta" integer NOT NULL,
        "reason" character varying(32) NOT NULL,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_session_package_debits" PRIMARY KEY ("id"),
        CONSTRAINT "FK_session_package_debits_package"
          FOREIGN KEY ("package_id")
          REFERENCES "session_packages"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_package_debits_session"
          FOREIGN KEY ("session_id")
          REFERENCES "sessions"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_session_package_debits_delta"
          CHECK ("delta" = -1),
        CONSTRAINT "CHK_session_package_debits_reason"
          CHECK ("reason" IN ('completed', 'no_show_chargeable'))
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_session_package_debits_package_session"
      ON "session_package_debits" ("package_id", "session_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_session_package_debits_session"
      ON "session_package_debits" ("session_id")
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX IF EXISTS "IDX_session_package_debits_session"`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS "UQ_session_package_debits_package_session"`,
    );
    await queryRunner.query(
      `DROP TABLE IF EXISTS "session_package_debits"`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS "UQ_session_packages_active_pair"`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS "IDX_session_packages_student"`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS "IDX_session_packages_coach"`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS "session_packages"`);
  }
}
