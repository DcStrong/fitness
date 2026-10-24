import type { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Одна запись портфолио содержит несколько фото: `image_url` заменяется массивом `image_urls`.
 * Существующие фото переносятся как массив из одного элемента.
 */
export class PortfolioItemImages1755540000000 implements MigrationInterface {
  name = 'PortfolioItemImages1755540000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "trainer_portfolio_items" ADD "image_urls" text array NOT NULL DEFAULT '{}'`);
    await queryRunner.query(
      `UPDATE "trainer_portfolio_items" SET "image_urls" = ARRAY["image_url"] WHERE "image_url" IS NOT NULL`,
    );
    await queryRunner.query(`ALTER TABLE "trainer_portfolio_items" DROP CONSTRAINT "CHK_trainer_portfolio_image_http"`);
    await queryRunner.query(`ALTER TABLE "trainer_portfolio_items" DROP COLUMN "image_url"`);
  }

  /**
   * Сохраняет только первое фото каждой записи.
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "trainer_portfolio_items" ADD "image_url" character varying(2048)`);
    await queryRunner.query(`UPDATE "trainer_portfolio_items" SET "image_url" = "image_urls"[1]`);
    await queryRunner.query(
      `ALTER TABLE "trainer_portfolio_items" ADD CONSTRAINT "CHK_trainer_portfolio_image_http" CHECK ("image_url" IS NULL OR "image_url" ~ '^https?://')`,
    );
    await queryRunner.query(`ALTER TABLE "trainer_portfolio_items" DROP COLUMN "image_urls"`);
  }
}
