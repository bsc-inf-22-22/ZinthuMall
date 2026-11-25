import { MigrationInterface, QueryRunner } from 'typeorm';

/** Products can have several photos; existing single photos become the first one. */
export class ProductImageGallery1795600000000 implements MigrationInterface {
  name = 'ProductImageGallery1795600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "products" ADD "imageUrls" jsonb NOT NULL DEFAULT '[]'`,
    );
    await queryRunner.query(
      `UPDATE "products" SET "imageUrls" = jsonb_build_array("imageUrl") WHERE "imageUrl" IS NOT NULL AND "imageUrl" <> ''`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "products" DROP COLUMN "imageUrls"`);
  }
}
