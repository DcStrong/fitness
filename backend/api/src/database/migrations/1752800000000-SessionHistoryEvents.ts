import { MigrationInterface, QueryRunner } from 'typeorm';

export class SessionHistoryEvents1752800000000 implements MigrationInterface {
  name = 'SessionHistoryEvents1752800000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "session_history_events" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "session_id" uuid NOT NULL,
        "actor_user_id" uuid NOT NULL,
        "from_status" character varying(16) NOT NULL,
        "to_status" character varying(16) NOT NULL,
        "note" character varying(500),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_session_history_events" PRIMARY KEY ("id"),
        CONSTRAINT "FK_session_history_session"
          FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_history_actor"
          FOREIGN KEY ("actor_user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_session_history_from_status"
          CHECK ("from_status" IN ('booked', 'completed', 'cancelled', 'no_show')),
        CONSTRAINT "CHK_session_history_to_status"
          CHECK ("to_status" IN ('booked', 'completed', 'cancelled', 'no_show'))
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_session_history_session_created"
      ON "session_history_events" ("session_id", "created_at")
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."IDX_session_history_session_created"`,
    );
    await queryRunner.query(`DROP TABLE "session_history_events"`);
  }
}
