import { MigrationInterface, QueryRunner } from 'typeorm';

export class TrainerGyms1755520000000 implements MigrationInterface {
  name = 'TrainerGyms1755520000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "gyms" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying(120) NOT NULL,
        "address" character varying(255) NOT NULL,
        "city" character varying(120) NOT NULL,
        "district" character varying(120),
        "dedupe_key" character varying(520) NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_gyms" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_gyms_dedupe_key" UNIQUE ("dedupe_key")
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "trainer_gyms" (
        "coach_id" uuid NOT NULL,
        "gym_id" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_trainer_gyms" PRIMARY KEY ("coach_id", "gym_id"),
        CONSTRAINT "FK_trainer_gyms_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_trainer_gyms_gym"
          FOREIGN KEY ("gym_id") REFERENCES "gyms"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_trainer_gyms_gym" ON "trainer_gyms" ("gym_id")`,
    );

    // Специализации: ≤ 8 тегов, ≤ 30 символов на тег. Формат хранения
    // (varchar[] в нижнем регистре) не меняется — подрезаем legacy-данные.
    await queryRunner.query(`
      UPDATE "user_profiles"
      SET "specialties" = (
        SELECT COALESCE(
          array_agg(left(q.s, 30) ORDER BY q.ord)::character varying[],
          '{}'::character varying[]
        )
        FROM (
          SELECT t.s, t.ord
          FROM unnest("user_profiles"."specialties") WITH ORDINALITY AS t(s, ord)
          ORDER BY t.ord
          LIMIT 8
        ) q
      )
      WHERE cardinality("specialties") > 8
        OR EXISTS (
          SELECT 1 FROM unnest("user_profiles"."specialties") AS e(s)
          WHERE char_length(e.s) > 30
        )
    `);
    await queryRunner.query(
      `ALTER TABLE "user_profiles" DROP CONSTRAINT "CHK_user_profiles_specialties_count"`,
    );
    await queryRunner.query(`
      ALTER TABLE "user_profiles"
      ADD CONSTRAINT "CHK_user_profiles_specialties_count"
      CHECK (cardinality("specialties") <= 8)
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "user_profiles" DROP CONSTRAINT "CHK_user_profiles_specialties_count"`,
    );
    await queryRunner.query(`
      ALTER TABLE "user_profiles"
      ADD CONSTRAINT "CHK_user_profiles_specialties_count"
      CHECK (cardinality("specialties") <= 10)
    `);
    await queryRunner.query(`DROP INDEX "public"."IDX_trainer_gyms_gym"`);
    await queryRunner.query(`DROP TABLE "trainer_gyms"`);
    await queryRunner.query(`DROP TABLE "gyms"`);
  }
}
