import type { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Allow cancelled/completed sessions to detach from a slot so the slot can be
 * rebooked after cancel releases time.
 */
export class NullableSessionScheduleSlot1754400000000
  implements MigrationInterface
{
  name = 'NullableSessionScheduleSlot1754400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "sessions"
      ALTER COLUMN "schedule_slot_id" DROP NOT NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE "sessions"
      SET "schedule_slot_id" = (
        SELECT s.id FROM schedule_slots s
        WHERE s.coach_id = sessions.coach_id
          AND s.starts_at = sessions.starts_at
          AND s.ends_at = sessions.ends_at
        LIMIT 1
      )
      WHERE "schedule_slot_id" IS NULL
    `);
    await queryRunner.query(`
      ALTER TABLE "sessions"
      ALTER COLUMN "schedule_slot_id" SET NOT NULL
    `);
  }
}
