import { MigrationInterface, QueryRunner } from 'typeorm';

export class StructuredWorkoutTemplates1754900000000 implements MigrationInterface {
  name = 'StructuredWorkoutTemplates1754900000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "training_plans"
        ADD COLUMN "kind" character varying(32) NOT NULL DEFAULT 'template',
        ADD COLUMN "goal" character varying(32) NOT NULL DEFAULT 'general',
        ADD COLUMN "parent_template_id" uuid,
        ADD COLUMN "assigned_student_id" uuid
    `);
    await queryRunner.query(`
      ALTER TABLE "training_plans"
        ADD CONSTRAINT "CHK_training_plans_kind"
          CHECK ("kind" IN ('template', 'catalog_seed', 'student_copy')),
        ADD CONSTRAINT "CHK_training_plans_goal"
          CHECK ("goal" IN ('hypertrophy', 'fat_loss', 'general')),
        ADD CONSTRAINT "FK_training_plans_parent_template"
          FOREIGN KEY ("parent_template_id") REFERENCES "training_plans"("id") ON DELETE SET NULL,
        ADD CONSTRAINT "FK_training_plans_assigned_student"
          FOREIGN KEY ("assigned_student_id") REFERENCES "users"("id") ON DELETE SET NULL
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_training_plans_kind" ON "training_plans" ("kind")`,
    );

    await queryRunner.query(`
      CREATE TABLE "exercises" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying(120) NOT NULL,
        "kind" character varying(32) NOT NULL,
        "owner_coach_id" uuid,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_exercises" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_exercises_kind"
          CHECK ("kind" IN ('weight_reps', 'bodyweight_reps', 'duration')),
        CONSTRAINT "FK_exercises_owner"
          FOREIGN KEY ("owner_coach_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_exercises_owner_coach_id" ON "exercises" ("owner_coach_id")`,
    );
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_exercises_owner_lower_name"
        ON "exercises" ("owner_coach_id", LOWER("name"))
        WHERE "owner_coach_id" IS NOT NULL
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_exercises_catalog_lower_name"
        ON "exercises" (LOWER("name"))
        WHERE "owner_coach_id" IS NULL
    `);

    await queryRunner.query(`
      CREATE TABLE "plan_exercises" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "plan_id" uuid NOT NULL,
        "exercise_id" uuid NOT NULL,
        "sort_order" integer NOT NULL,
        "rest_seconds" integer,
        "notes" text NOT NULL DEFAULT '',
        CONSTRAINT "PK_plan_exercises" PRIMARY KEY ("id"),
        CONSTRAINT "FK_plan_exercises_plan"
          FOREIGN KEY ("plan_id") REFERENCES "training_plans"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_plan_exercises_exercise"
          FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_plan_exercises_plan_id" ON "plan_exercises" ("plan_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_plan_exercises_exercise_id" ON "plan_exercises" ("exercise_id")`,
    );

    await queryRunner.query(`
      CREATE TABLE "plan_sets" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "plan_exercise_id" uuid NOT NULL,
        "sort_order" integer NOT NULL,
        "reps" integer,
        "weight_kg" numeric(6,2),
        "duration_seconds" integer,
        CONSTRAINT "PK_plan_sets" PRIMARY KEY ("id"),
        CONSTRAINT "FK_plan_sets_plan_exercise"
          FOREIGN KEY ("plan_exercise_id") REFERENCES "plan_exercises"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_plan_sets_plan_exercise_id" ON "plan_sets" ("plan_exercise_id")`,
    );
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."IDX_plan_sets_plan_exercise_id"`,
    );
    await queryRunner.query(`DROP TABLE "plan_sets"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_plan_exercises_exercise_id"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_plan_exercises_plan_id"`,
    );
    await queryRunner.query(`DROP TABLE "plan_exercises"`);
    await queryRunner.query(
      `DROP INDEX "public"."UQ_exercises_catalog_lower_name"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."UQ_exercises_owner_lower_name"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_exercises_owner_coach_id"`,
    );
    await queryRunner.query(`DROP TABLE "exercises"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_training_plans_kind"`);
    await queryRunner.query(`
      ALTER TABLE "training_plans"
        DROP CONSTRAINT "FK_training_plans_assigned_student",
        DROP CONSTRAINT "FK_training_plans_parent_template",
        DROP CONSTRAINT "CHK_training_plans_goal",
        DROP CONSTRAINT "CHK_training_plans_kind",
        DROP COLUMN "assigned_student_id",
        DROP COLUMN "parent_template_id",
        DROP COLUMN "goal",
        DROP COLUMN "kind"
    `);
  }
}
