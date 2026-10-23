import { MigrationInterface, QueryRunner } from 'typeorm';

export class CoachStudentChat1755400000000 implements MigrationInterface {
  name = 'CoachStudentChat1755400000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "chat_conversations" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "last_message_at" TIMESTAMP WITH TIME ZONE,
        "coach_last_read_at" TIMESTAMP WITH TIME ZONE,
        "student_last_read_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_chat_conversations" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_chat_conversations_pair" UNIQUE ("coach_id", "student_id"),
        CONSTRAINT "FK_chat_conversations_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_chat_conversations_student"
          FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_chat_conversations_coach_id" ON "chat_conversations" ("coach_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_chat_conversations_student_id" ON "chat_conversations" ("student_id")`,
    );
    await queryRunner.query(`
      CREATE TABLE "chat_messages" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "conversation_id" uuid NOT NULL,
        "sender_id" uuid,
        "kind" varchar(16) NOT NULL,
        "body" text NOT NULL,
        "system_type" varchar(32),
        "payload" jsonb,
        "client_id" uuid,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
        CONSTRAINT "PK_chat_messages" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_chat_messages_kind" CHECK ("kind" IN ('text', 'system')),
        CONSTRAINT "FK_chat_messages_conversation"
          FOREIGN KEY ("conversation_id") REFERENCES "chat_conversations"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_chat_messages_sender"
          FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_chat_messages_conversation_created" ON "chat_messages" ("conversation_id", "created_at", "id")`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "UQ_chat_messages_client_id" ON "chat_messages" ("conversation_id", "sender_id", "client_id") WHERE "client_id" IS NOT NULL`,
    );
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "public"."UQ_chat_messages_client_id"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_chat_messages_conversation_created"`,
    );
    await queryRunner.query(`DROP TABLE "chat_messages"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_chat_conversations_student_id"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_chat_conversations_coach_id"`,
    );
    await queryRunner.query(`DROP TABLE "chat_conversations"`);
  }
}
