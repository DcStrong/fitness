import { MigrationInterface, QueryRunner } from 'typeorm';

export class TagsAndTrainingPlans1752810000000 implements MigrationInterface {
  name = 'TagsAndTrainingPlans1752810000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "tags" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying(64) NOT NULL,
        "creator_id" uuid NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_tags" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_tags_creator_name" UNIQUE ("creator_id", "name"),
        CONSTRAINT "FK_tags_creator"
          FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_tags_creator_id" ON "tags" ("creator_id")`,
    );

    await queryRunner.query(`
      CREATE TABLE "user_tags" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "tag_id" uuid NOT NULL,
        "assigned_by" uuid NOT NULL,
        "assigned_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_user_tags" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_user_tags_pair" UNIQUE ("user_id", "tag_id"),
        CONSTRAINT "FK_user_tags_user"
          FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_user_tags_tag"
          FOREIGN KEY ("tag_id") REFERENCES "tags"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_user_tags_assigner"
          FOREIGN KEY ("assigned_by") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_user_tags_user_id" ON "user_tags" ("user_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_user_tags_tag_id" ON "user_tags" ("tag_id")`,
    );

    await queryRunner.query(`
      CREATE TABLE "training_plans" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "owner_coach_id" uuid NOT NULL,
        "title" character varying(200) NOT NULL,
        "body" text NOT NULL DEFAULT '',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_training_plans" PRIMARY KEY ("id"),
        CONSTRAINT "FK_training_plans_owner"
          FOREIGN KEY ("owner_coach_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_training_plans_owner_coach_id" ON "training_plans" ("owner_coach_id")`,
    );

    await queryRunner.query(`
      CREATE TABLE "training_plan_tags" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "plan_id" uuid NOT NULL,
        "tag_id" uuid NOT NULL,
        CONSTRAINT "PK_training_plan_tags" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_training_plan_tags_pair" UNIQUE ("plan_id", "tag_id"),
        CONSTRAINT "FK_training_plan_tags_plan"
          FOREIGN KEY ("plan_id") REFERENCES "training_plans"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_training_plan_tags_tag"
          FOREIGN KEY ("tag_id") REFERENCES "tags"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      `CREATE INDEX "IDX_training_plan_tags_plan_id" ON "training_plan_tags" ("plan_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_training_plan_tags_tag_id" ON "training_plan_tags" ("tag_id")`,
    );
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."IDX_training_plan_tags_tag_id"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_training_plan_tags_plan_id"`,
    );
    await queryRunner.query(`DROP TABLE "training_plan_tags"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_training_plans_owner_coach_id"`,
    );
    await queryRunner.query(`DROP TABLE "training_plans"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_user_tags_tag_id"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_user_tags_user_id"`);
    await queryRunner.query(`DROP TABLE "user_tags"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_tags_creator_id"`);
    await queryRunner.query(`DROP TABLE "tags"`);
  }
}
