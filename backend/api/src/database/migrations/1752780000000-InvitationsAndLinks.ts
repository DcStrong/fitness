import { MigrationInterface, QueryRunner } from 'typeorm';

export class InvitationsAndLinks1752780000000 implements MigrationInterface {
  name = 'InvitationsAndLinks1752780000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "invitations" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "coach_id" uuid NOT NULL,
        "token_hash" character varying NOT NULL,
        "status" character varying(32) NOT NULL DEFAULT 'pending',
        "expires_at" TIMESTAMPTZ NOT NULL,
        "accepted_by_user_id" uuid,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_invitations_token_hash" UNIQUE ("token_hash"),
        CONSTRAINT "PK_invitations" PRIMARY KEY ("id"),
        CONSTRAINT "FK_invitations_coach" FOREIGN KEY ("coach_id")
          REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION,
        CONSTRAINT "FK_invitations_accepted_by" FOREIGN KEY ("accepted_by_user_id")
          REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_invitations_coach_id" ON "invitations" ("coach_id")
    `);

    await queryRunner.query(`
      CREATE TABLE "coach_student_links" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "source_invitation_id" uuid,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_coach_student_links_pair" UNIQUE ("coach_id", "student_id"),
        CONSTRAINT "PK_coach_student_links" PRIMARY KEY ("id"),
        CONSTRAINT "FK_coach_student_links_coach" FOREIGN KEY ("coach_id")
          REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION,
        CONSTRAINT "FK_coach_student_links_student" FOREIGN KEY ("student_id")
          REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION,
        CONSTRAINT "FK_coach_student_links_invitation" FOREIGN KEY ("source_invitation_id")
          REFERENCES "invitations"("id") ON DELETE SET NULL ON UPDATE NO ACTION
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_coach_student_links_coach_id" ON "coach_student_links" ("coach_id")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_coach_student_links_student_id" ON "coach_student_links" ("student_id")
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "coach_student_links"`);
    await queryRunner.query(`DROP TABLE "invitations"`);
  }
}
