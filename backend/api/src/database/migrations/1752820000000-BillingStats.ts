import { MigrationInterface, QueryRunner } from 'typeorm';

export class BillingStats1752820000000 implements MigrationInterface {
  name = 'BillingStats1752820000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "coach_finance_settings" (
        "coach_id" uuid NOT NULL,
        "default_session_price_minor" bigint NOT NULL,
        "currency" character(3) NOT NULL DEFAULT 'RUB',
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_coach_finance_settings" PRIMARY KEY ("coach_id"),
        CONSTRAINT "FK_coach_finance_settings_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_coach_finance_settings_price"
          CHECK ("default_session_price_minor" > 0),
        CONSTRAINT "CHK_coach_finance_settings_currency"
          CHECK ("currency" = 'RUB')
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "session_charges" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "session_id" uuid NOT NULL,
        "coach_id" uuid NOT NULL,
        "student_id" uuid NOT NULL,
        "amount_minor" bigint NOT NULL,
        "currency" character(3) NOT NULL,
        "status" character varying(16) NOT NULL DEFAULT 'pending',
        "earned_at" TIMESTAMP WITH TIME ZONE,
        "paid_at" TIMESTAMP WITH TIME ZONE,
        "payment_method" character varying(16),
        "cancelled_at" TIMESTAMP WITH TIME ZONE,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_session_charges" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_session_charges_session" UNIQUE ("session_id"),
        CONSTRAINT "FK_session_charges_session"
          FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_charges_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_session_charges_student"
          FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_session_charges_amount" CHECK ("amount_minor" > 0),
        CONSTRAINT "CHK_session_charges_currency" CHECK ("currency" = 'RUB'),
        CONSTRAINT "CHK_session_charges_status"
          CHECK ("status" IN ('pending', 'paid', 'cancelled')),
        CONSTRAINT "CHK_session_charges_payment_method"
          CHECK ("payment_method" IS NULL OR "payment_method" IN ('cash', 'transfer', 'card', 'other')),
        CONSTRAINT "CHK_session_charges_state"
          CHECK (
            ("status" = 'pending' AND "paid_at" IS NULL AND "payment_method" IS NULL AND "cancelled_at" IS NULL)
            OR ("status" = 'paid' AND "earned_at" IS NOT NULL AND "paid_at" IS NOT NULL AND "payment_method" IS NOT NULL AND "cancelled_at" IS NULL)
            OR ("status" = 'cancelled' AND "paid_at" IS NULL AND "payment_method" IS NULL AND "cancelled_at" IS NOT NULL)
          )
      )
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_session_charges_coach_status_earned"
      ON "session_charges" ("coach_id", "status", "earned_at")
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_session_charges_student_id"
      ON "session_charges" ("student_id")
    `);

    await queryRunner.query(`
      CREATE TABLE "finance_ledger_entries" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "coach_id" uuid NOT NULL,
        "type" character varying(16) NOT NULL,
        "amount_minor" bigint NOT NULL,
        "currency" character(3) NOT NULL,
        "source_type" character varying(32) NOT NULL,
        "source_id" uuid,
        "category" character varying(100),
        "note" character varying(500),
        "occurred_at" TIMESTAMP WITH TIME ZONE NOT NULL,
        "reverses_entry_id" uuid,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_finance_ledger_entries" PRIMARY KEY ("id"),
        CONSTRAINT "FK_finance_ledger_coach"
          FOREIGN KEY ("coach_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_finance_ledger_reverses"
          FOREIGN KEY ("reverses_entry_id") REFERENCES "finance_ledger_entries"("id") ON DELETE RESTRICT,
        CONSTRAINT "UQ_finance_ledger_reverses" UNIQUE ("reverses_entry_id"),
        CONSTRAINT "CHK_finance_ledger_type"
          CHECK ("type" IN ('income', 'expense', 'adjustment')),
        CONSTRAINT "CHK_finance_ledger_amount"
          CHECK (
            ("type" IN ('income', 'expense') AND "amount_minor" > 0)
            OR ("type" = 'adjustment' AND "amount_minor" <> 0)
          ),
        CONSTRAINT "CHK_finance_ledger_currency" CHECK ("currency" = 'RUB'),
        CONSTRAINT "CHK_finance_ledger_source"
          CHECK ("source_type" IN ('session_charge', 'manual')),
        CONSTRAINT "CHK_finance_ledger_session_source"
          CHECK (
            ("source_type" = 'session_charge' AND "source_id" IS NOT NULL)
            OR "source_type" = 'manual'
          )
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_finance_ledger_charge_income"
      ON "finance_ledger_entries" ("source_type", "source_id", "type")
      WHERE "source_type" = 'session_charge' AND "type" = 'income'
    `);
    await queryRunner.query(`
      CREATE INDEX "IDX_finance_ledger_coach_occurred"
      ON "finance_ledger_entries" ("coach_id", "occurred_at")
    `);
  }

  /**
   *
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."IDX_finance_ledger_coach_occurred"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."UQ_finance_ledger_charge_income"`,
    );
    await queryRunner.query(`DROP TABLE "finance_ledger_entries"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_session_charges_student_id"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_session_charges_coach_status_earned"`,
    );
    await queryRunner.query(`DROP TABLE "session_charges"`);
    await queryRunner.query(`DROP TABLE "coach_finance_settings"`);
  }
}
