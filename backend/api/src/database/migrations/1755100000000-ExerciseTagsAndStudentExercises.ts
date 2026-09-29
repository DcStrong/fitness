import { MigrationInterface, QueryRunner } from 'typeorm';

export class ExerciseTagsAndStudentExercises1755100000000
  implements MigrationInterface
{
  name = 'ExerciseTagsAndStudentExercises1755100000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "exercise_tags" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "exercise_id" uuid NOT NULL,
        "tag_id" uuid NOT NULL,
        CONSTRAINT "PK_exercise_tags" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_exercise_tags_pair" UNIQUE ("exercise_id", "tag_id"),
        CONSTRAINT "FK_exercise_tags_exercise"
          FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_exercise_tags_tag"
          FOREIGN KEY ("tag_id") REFERENCES "tags"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_exercise_tags_exercise_id" ON "exercise_tags" ("exercise_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_exercise_tags_tag_id" ON "exercise_tags" ("tag_id")`,
    );

    await queryRunner.query(`
      CREATE TABLE "student_exercises" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "exercise_id" uuid NOT NULL,
        "assigned_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_student_exercises" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_student_exercises_triple"
          UNIQUE ("coach_id", "student_id", "exercise_id"),
        CONSTRAINT "FK_student_exercises_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_student_exercises_student"
          FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_student_exercises_exercise"
          FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_student_exercises_student_id" ON "student_exercises" ("student_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_student_exercises_coach_id" ON "student_exercises" ("coach_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_student_exercises_exercise_id" ON "student_exercises" ("exercise_id")`,
    );
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."IDX_student_exercises_exercise_id"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_student_exercises_coach_id"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_student_exercises_student_id"`,
    );
    await queryRunner.query(`DROP TABLE "student_exercises"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_exercise_tags_tag_id"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_exercise_tags_exercise_id"`,
    );
    await queryRunner.query(`DROP TABLE "exercise_tags"`);
  }
}
