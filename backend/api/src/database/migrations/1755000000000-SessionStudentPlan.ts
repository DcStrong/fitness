import { MigrationInterface, QueryRunner } from 'typeorm';

export class SessionStudentPlan1755000000000 implements MigrationInterface {
  name = 'SessionStudentPlan1755000000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "sessions"
        ADD COLUMN "student_plan_id" uuid
    `);
    await queryRunner.query(`
      ALTER TABLE "sessions"
        ADD CONSTRAINT "FK_sessions_student_plan"
          FOREIGN KEY ("student_plan_id") REFERENCES "training_plans"("id")
          ON DELETE SET NULL
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_sessions_student_plan_id" ON "sessions" ("student_plan_id")`,
    );
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_training_plans_student_copy_pair"
        ON "training_plans" ("parent_template_id", "assigned_student_id")
        WHERE "kind" = 'student_copy'
          AND "parent_template_id" IS NOT NULL
          AND "assigned_student_id" IS NOT NULL
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."UQ_training_plans_student_copy_pair"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_sessions_student_plan_id"`,
    );
    await queryRunner.query(`
      ALTER TABLE "sessions"
        DROP CONSTRAINT "FK_sessions_student_plan",
        DROP COLUMN "student_plan_id"
    `);
  }
}
