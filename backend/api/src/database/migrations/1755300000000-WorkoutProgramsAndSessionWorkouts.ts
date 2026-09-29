import { MigrationInterface, QueryRunner } from 'typeorm';

export class WorkoutProgramsAndSessionWorkouts1755300000000
  implements MigrationInterface
{
  name = 'WorkoutProgramsAndSessionWorkouts1755300000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "workout_programs" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "recurring_booking_id" uuid NOT NULL,
        "owner_coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "horizon_weeks" int NOT NULL DEFAULT 2,
        "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
        CONSTRAINT "PK_workout_programs" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_workout_programs_recurring" UNIQUE ("recurring_booking_id"),
        CONSTRAINT "CHK_workout_programs_horizon"
          CHECK ("horizon_weeks" >= 1 AND "horizon_weeks" <= 8),
        CONSTRAINT "FK_workout_programs_recurring"
          FOREIGN KEY ("recurring_booking_id")
          REFERENCES "recurring_bookings"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_workout_programs_coach"
          FOREIGN KEY ("owner_coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_workout_programs_student"
          FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "workout_program_days" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "program_id" uuid NOT NULL,
        "weekday" smallint NOT NULL,
        CONSTRAINT "PK_workout_program_days" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_workout_program_days_weekday" UNIQUE ("program_id", "weekday"),
        CONSTRAINT "CHK_workout_program_days_weekday"
          CHECK ("weekday" >= 1 AND "weekday" <= 7),
        CONSTRAINT "FK_workout_program_days_program"
          FOREIGN KEY ("program_id")
          REFERENCES "workout_programs"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "workout_program_day_items" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "program_day_id" uuid NOT NULL,
        "sort_order" int NOT NULL,
        "template_id" uuid NOT NULL,
        "student_plan_id" uuid NOT NULL,
        CONSTRAINT "PK_workout_program_day_items" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_workout_program_day_items_order"
          UNIQUE ("program_day_id", "sort_order"),
        CONSTRAINT "FK_workout_program_day_items_day"
          FOREIGN KEY ("program_day_id")
          REFERENCES "workout_program_days"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_workout_program_day_items_template"
          FOREIGN KEY ("template_id")
          REFERENCES "training_plans"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_workout_program_day_items_copy"
          FOREIGN KEY ("student_plan_id")
          REFERENCES "training_plans"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "workout_progression_rules" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "program_id" uuid NOT NULL,
        "exercise_id" uuid NOT NULL,
        "start_weight_kg" numeric(6,2),
        "delta_kg" numeric(6,2) NOT NULL DEFAULT 0,
        "increment_kg" numeric(6,2) NOT NULL DEFAULT 2.50,
        "hold_on_miss" boolean NOT NULL DEFAULT true,
        "held_weight_kg" numeric(6,2),
        CONSTRAINT "PK_workout_progression_rules" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_workout_progression_rules_exercise"
          UNIQUE ("program_id", "exercise_id"),
        CONSTRAINT "FK_workout_progression_rules_program"
          FOREIGN KEY ("program_id")
          REFERENCES "workout_programs"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_workout_progression_rules_exercise"
          FOREIGN KEY ("exercise_id")
          REFERENCES "exercises"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "session_workout_items" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "session_id" uuid NOT NULL,
        "sort_order" int NOT NULL,
        "student_plan_id" uuid NOT NULL,
        "source" varchar(16) NOT NULL,
        "override_at" TIMESTAMPTZ,
        CONSTRAINT "PK_session_workout_items" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_session_workout_items_order" UNIQUE ("session_id", "sort_order"),
        CONSTRAINT "FK_session_workout_items_session"
          FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_workout_items_plan"
          FOREIGN KEY ("student_plan_id")
          REFERENCES "training_plans"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(`
      CREATE TABLE "session_prescription_sets" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "session_workout_item_id" uuid NOT NULL,
        "exercise_id" uuid NOT NULL,
        "exercise_name" varchar(120) NOT NULL,
        "exercise_kind" varchar(32) NOT NULL,
        "sort_order" int NOT NULL,
        "reps" int,
        "weight_kg" numeric(6,2),
        "duration_seconds" int,
        CONSTRAINT "PK_session_prescription_sets" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_session_prescription_sets_triple"
          UNIQUE ("session_workout_item_id", "exercise_id", "sort_order"),
        CONSTRAINT "FK_session_prescription_sets_item"
          FOREIGN KEY ("session_workout_item_id")
          REFERENCES "session_workout_items"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_prescription_sets_exercise"
          FOREIGN KEY ("exercise_id")
          REFERENCES "exercises"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_workout_program_days_program_id" ON "workout_program_days" ("program_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_workout_program_day_items_day_id" ON "workout_program_day_items" ("program_day_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_workout_progression_rules_program_id" ON "workout_progression_rules" ("program_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_session_workout_items_session_id" ON "session_workout_items" ("session_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_session_prescription_sets_item_id" ON "session_prescription_sets" ("session_workout_item_id")`,
    );

    await queryRunner.query(`
      INSERT INTO "session_workout_items"
        ("session_id", "sort_order", "student_plan_id", "source")
      SELECT "id", 0, "student_plan_id", 'manual'
      FROM "sessions"
      WHERE "student_plan_id" IS NOT NULL
    `);
    await queryRunner.query(`
      INSERT INTO "session_prescription_sets"
        ("session_workout_item_id", "exercise_id", "exercise_name",
         "exercise_kind", "sort_order", "reps", "weight_kg", "duration_seconds")
      SELECT
        item."id",
        pe."exercise_id",
        ex."name",
        ex."kind",
        ps."sort_order",
        ps."reps",
        ps."weight_kg",
        ps."duration_seconds"
      FROM "session_workout_items" item
      INNER JOIN "plan_exercises" pe ON pe."plan_id" = item."student_plan_id"
      INNER JOIN "exercises" ex ON ex."id" = pe."exercise_id"
      INNER JOIN "plan_sets" ps ON ps."plan_exercise_id" = pe."id"
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "session_prescription_sets"`);
    await queryRunner.query(`DROP TABLE "session_workout_items"`);
    await queryRunner.query(`DROP TABLE "workout_progression_rules"`);
    await queryRunner.query(`DROP TABLE "workout_program_day_items"`);
    await queryRunner.query(`DROP TABLE "workout_program_days"`);
    await queryRunner.query(`DROP TABLE "workout_programs"`);
  }
}
