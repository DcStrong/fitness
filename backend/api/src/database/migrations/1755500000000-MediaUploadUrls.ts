import type { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Загруженные в хранилище картинки в dev/на стенде могут отдаваться по http,
 * поэтому CHECK допускает http и https; допустимость адреса проверяет API.
 */
export class MediaUploadUrls1755500000000 implements MigrationInterface {
  name = 'MediaUploadUrls1755500000000';

  /**
   *
   */
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "user_profiles" DROP CONSTRAINT "CHK_user_profiles_avatar_https"`);
    await queryRunner.query(
      `ALTER TABLE "user_profiles" ADD CONSTRAINT "CHK_user_profiles_avatar_http" CHECK ("avatar_url" IS NULL OR "avatar_url" ~ '^https?://')`,
    );
    await queryRunner.query(`ALTER TABLE "trainer_portfolio_items" DROP CONSTRAINT "CHK_trainer_portfolio_image_https"`);
    await queryRunner.query(
      `ALTER TABLE "trainer_portfolio_items" ADD CONSTRAINT "CHK_trainer_portfolio_image_http" CHECK ("image_url" IS NULL OR "image_url" ~ '^https?://')`,
    );
  }

  /**
   * Обнуляет http-ссылки, иначе вернуть https-ограничение нельзя.
   */
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "trainer_portfolio_items" DROP CONSTRAINT "CHK_trainer_portfolio_image_http"`);
    await queryRunner.query(`UPDATE "trainer_portfolio_items" SET "image_url" = NULL WHERE "image_url" LIKE 'http://%'`);
    await queryRunner.query(
      `ALTER TABLE "trainer_portfolio_items" ADD CONSTRAINT "CHK_trainer_portfolio_image_https" CHECK ("image_url" IS NULL OR "image_url" LIKE 'https://%')`,
    );
    await queryRunner.query(`ALTER TABLE "user_profiles" DROP CONSTRAINT "CHK_user_profiles_avatar_http"`);
    await queryRunner.query(`UPDATE "user_profiles" SET "avatar_url" = NULL WHERE "avatar_url" LIKE 'http://%'`);
    await queryRunner.query(
      `ALTER TABLE "user_profiles" ADD CONSTRAINT "CHK_user_profiles_avatar_https" CHECK ("avatar_url" IS NULL OR "avatar_url" LIKE 'https://%')`,
    );
  }
}
