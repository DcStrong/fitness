import { MigrationInterface, QueryRunner } from 'typeorm';

export class SessionSetLogs1755200000000 implements MigrationInterface {
  name = 'SessionSetLogs1755200000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "session_set_logs" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "session_id" uuid NOT NULL,
        "exercise_id" uuid NOT NULL,
        "sort_order" int NOT NULL,
        "reps" int,
        "weight_kg" numeric(6,2),
        "duration_seconds" int,
        CONSTRAINT "PK_session_set_logs" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_session_set_logs_triple"
          UNIQUE ("session_id", "exercise_id", "sort_order"),
        CONSTRAINT "FK_session_set_logs_session"
          FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_set_logs_exercise"
          FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_session_set_logs_session_id" ON "session_set_logs" ("session_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_session_set_logs_exercise_id" ON "session_set_logs" ("exercise_id")`,
    );
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."IDX_session_set_logs_exercise_id"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_session_set_logs_session_id"`,
    );
    await queryRunner.query(`DROP TABLE "session_set_logs"`);
  }
}
