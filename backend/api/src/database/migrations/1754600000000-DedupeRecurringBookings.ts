import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Collapse duplicate recurring_bookings with the same pattern
 * (coach, student, weekdays, start_minute, mode).
 * Active: keep oldest, cancel extras + free future slots.
 * Cancelled archive: keep latest, delete older twins.
 * Then unique index on active patterns.
 */
export class DedupeRecurringBookings1754600000000 implements MigrationInterface {
  name = 'DedupeRecurringBookings1754600000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE "recurring_bookings"
      SET "weekdays" = (
        SELECT COALESCE(array_agg(x ORDER BY x), '{}')
        FROM unnest("weekdays") AS x
      )
    `);

    await queryRunner.query(`
      CREATE TEMP TABLE tmp_active_dupes ON COMMIT DROP AS
      WITH ranked AS (
        SELECT
          id,
          ROW_NUMBER() OVER (
            PARTITION BY coach_id, student_id, start_minute, mode, weekdays
            ORDER BY created_at ASC, id ASC
          ) AS rn
        FROM recurring_bookings
        WHERE status = 'active'
      )
      SELECT id FROM ranked WHERE rn > 1
    `);

    await queryRunner.query(`
      UPDATE recurring_bookings rb
      SET
        status = 'cancelled',
        cancelled_at = COALESCE(cancelled_at, NOW()),
        updated_at = NOW()
      FROM tmp_active_dupes d
      WHERE rb.id = d.id
    `);

    await queryRunner.query(`
      UPDATE schedule_slots sl
      SET status = 'open'
      WHERE sl.status = 'booked'
        AND sl.id IN (
          SELECT s.schedule_slot_id
          FROM sessions s
          WHERE s.recurring_booking_id IN (SELECT id FROM tmp_active_dupes)
            AND s.status = 'booked'
            AND s.starts_at > NOW()
            AND s.schedule_slot_id IS NOT NULL
        )
    `);

    await queryRunner.query(`
      UPDATE sessions s
      SET status = 'cancelled', schedule_slot_id = NULL
      WHERE s.recurring_booking_id IN (SELECT id FROM tmp_active_dupes)
        AND s.status = 'booked'
        AND s.starts_at > NOW()
    `);

    await queryRunner.query(`
      CREATE TEMP TABLE tmp_cancelled_obsolete ON COMMIT DROP AS
      WITH ranked AS (
        SELECT
          id,
          ROW_NUMBER() OVER (
            PARTITION BY coach_id, student_id, start_minute, mode, weekdays
            ORDER BY COALESCE(cancelled_at, updated_at) DESC, id DESC
          ) AS rn
        FROM recurring_bookings
        WHERE status = 'cancelled'
      )
      SELECT id FROM ranked WHERE rn > 1
    `);

    await queryRunner.query(`
      DELETE FROM recurring_booking_overrides
      WHERE recurring_booking_id IN (SELECT id FROM tmp_cancelled_obsolete)
    `);

    await queryRunner.query(`
      UPDATE sessions
      SET recurring_booking_id = NULL, recurring_local_date = NULL
      WHERE recurring_booking_id IN (SELECT id FROM tmp_cancelled_obsolete)
    `);

    await queryRunner.query(`
      DELETE FROM recurring_bookings
      WHERE id IN (SELECT id FROM tmp_cancelled_obsolete)
    `);

    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_recurring_bookings_active_pattern"
      ON "recurring_bookings" ("coach_id", "student_id", "start_minute", "mode", "weekdays")
      WHERE "status" = 'active'
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX IF EXISTS "UQ_recurring_bookings_active_pattern"`,
    );
  }
}
