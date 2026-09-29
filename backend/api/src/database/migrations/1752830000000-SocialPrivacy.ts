import { MigrationInterface, QueryRunner } from 'typeorm';

export class SocialPrivacy1752830000000 implements MigrationInterface {
  name = 'SocialPrivacy1752830000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "user_profiles" (
        "user_id" uuid NOT NULL,
        "display_name" character varying(80),
        "avatar_url" character varying(2048),
        "bio" character varying(1000),
        "city" character varying(120),
        "specialties" character varying[] NOT NULL DEFAULT '{}',
        "training_modes" character varying[] NOT NULL DEFAULT '{}',
        "is_discoverable" boolean NOT NULL DEFAULT false,
        "show_rating" boolean NOT NULL DEFAULT true,
        "show_reviews" boolean NOT NULL DEFAULT true,
        "show_reviewer_name" boolean NOT NULL DEFAULT false,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_user_profiles" PRIMARY KEY ("user_id"),
        CONSTRAINT "FK_user_profiles_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_user_profiles_modes"
          CHECK ("training_modes" <@ ARRAY['online','offline']::character varying[]),
        CONSTRAINT "CHK_user_profiles_specialties_count"
          CHECK (cardinality("specialties") <= 10),
        CONSTRAINT "CHK_user_profiles_display_name"
          CHECK ("display_name" IS NULL OR char_length(trim("display_name")) BETWEEN 2 AND 80),
        CONSTRAINT "CHK_user_profiles_avatar_https"
          CHECK ("avatar_url" IS NULL OR "avatar_url" LIKE 'https://%')
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_user_profiles_discovery"
      ON "user_profiles" ("is_discoverable", "display_name", "user_id")
      WHERE "is_discoverable" = true
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_user_profiles_specialties_gin"
      ON "user_profiles" USING GIN ("specialties")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_user_profiles_modes_gin"
      ON "user_profiles" USING GIN ("training_modes")
    `);

    await queryRunner.query(`
      CREATE TABLE "trainer_portfolio_items" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "coach_id" uuid NOT NULL,
        "title" character varying(120) NOT NULL,
        "description" character varying(1000),
        "image_url" character varying(2048),
        "sort_order" integer NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_trainer_portfolio_items" PRIMARY KEY ("id"),
        CONSTRAINT "FK_trainer_portfolio_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_trainer_portfolio_order" CHECK ("sort_order" >= 0),
        CONSTRAINT "CHK_trainer_portfolio_title"
          CHECK (char_length(trim("title")) BETWEEN 1 AND 120),
        CONSTRAINT "CHK_trainer_portfolio_image_https"
          CHECK ("image_url" IS NULL OR "image_url" LIKE 'https://%')
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_trainer_portfolio_coach_order"
      ON "trainer_portfolio_items" ("coach_id", "sort_order")
    `);

    await queryRunner.query(`
      ALTER TABLE "sessions"
      ADD CONSTRAINT "UQ_sessions_review_ownership"
      UNIQUE ("id", "coach_id", "student_id")
    `);
    await queryRunner.query(`
      CREATE TABLE "session_reviews" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "session_id" uuid NOT NULL,
        "coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "rating" smallint NOT NULL,
        "text" character varying(2000),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_session_reviews" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_session_reviews_session" UNIQUE ("session_id"),
        CONSTRAINT "FK_session_reviews_session"
          FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_reviews_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_reviews_student"
          FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_reviews_session_ownership"
          FOREIGN KEY ("session_id", "coach_id", "student_id")
          REFERENCES "sessions"("id", "coach_id", "student_id") ON DELETE CASCADE,
        CONSTRAINT "CHK_session_reviews_rating" CHECK ("rating" BETWEEN 1 AND 5)
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_session_reviews_coach_created"
      ON "session_reviews" ("coach_id", "created_at")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_session_reviews_student_created"
      ON "session_reviews" ("student_id", "created_at")
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."IDX_session_reviews_student_created"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_session_reviews_coach_created"`,
    );
    await queryRunner.query(`DROP TABLE "session_reviews"`);
    await queryRunner.query(
      `ALTER TABLE "sessions" DROP CONSTRAINT "UQ_sessions_review_ownership"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_trainer_portfolio_coach_order"`,
    );
    await queryRunner.query(`DROP TABLE "trainer_portfolio_items"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_user_profiles_modes_gin"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_user_profiles_specialties_gin"`,
    );
    await queryRunner.query(`DROP INDEX "public"."IDX_user_profiles_discovery"`);
    await queryRunner.query(`DROP TABLE "user_profiles"`);
  }
}
