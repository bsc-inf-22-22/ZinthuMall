import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1795501225479 implements MigrationInterface {
  name = 'InitialSchema1795501225479';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "admin" ("id" SERIAL NOT NULL, "email" character varying NOT NULL, "password" character varying NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_de87485f6489f5d0995f5841952" UNIQUE ("email"), CONSTRAINT "PK_e032310bcef831fb83101899b10" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "customers" ("id" SERIAL NOT NULL, "name" character varying NOT NULL, "email" character varying NOT NULL, "phone" character varying, "address" character varying, "city" character varying, "password" character varying NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_8536b8b85c06969f84f0c098b03" UNIQUE ("email"), CONSTRAINT "PK_133ec679a801fab5e070f73d3ea" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "products" ("id" SERIAL NOT NULL, "name" character varying NOT NULL, "category" character varying NOT NULL, "price" numeric(10,2) NOT NULL, "stock" integer NOT NULL DEFAULT '0', "discount" integer, "description" text, "sizes" text, "imageUrl" character varying, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_0806c755e0aca124e67c0cf6d7d" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_c3932231d2385ac248d0888d95" ON "products"  ("category") `,
    );
    await queryRunner.query(
      `CREATE TABLE "inventory_transactions" ("id" SERIAL NOT NULL, "productId" integer NOT NULL, "quantity" integer NOT NULL, "type" character varying(20) NOT NULL, "notes" character varying, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_9b7144851f08f9eededde7edd42" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_f21250669a9728997c6d8f6f5d" ON "inventory_transactions"  ("productId") `,
    );
    await queryRunner.query(
      `CREATE TABLE "notifications" ("id" SERIAL NOT NULL, "title" character varying NOT NULL, "message" text NOT NULL, "type" character varying NOT NULL DEFAULT 'order', "isRead" boolean NOT NULL DEFAULT false, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_6a72c3c0f683f6462415e653c3a" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "orders" ("id" SERIAL NOT NULL, "customerId" integer, "customerName" character varying NOT NULL, "customerEmail" character varying NOT NULL, "customerPhone" character varying NOT NULL, "deliveryAddress" character varying NOT NULL, "deliveryCity" character varying NOT NULL, "subtotal" numeric(10,2) NOT NULL DEFAULT '0', "deliveryFee" numeric(10,2) NOT NULL DEFAULT '0', "totalAmount" numeric(10,2) NOT NULL, "status" character varying NOT NULL DEFAULT 'pending', "paymentStatus" character varying NOT NULL DEFAULT 'pending', "paymentMethod" character varying, "transactionId" character varying, "items" jsonb NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_710e2d4957aa5878dfe94e4ac2f" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_e5de51ca888d8b1f5ac25799dd" ON "orders"  ("customerId") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_775c9f06fc27ae3ff8fb26f2c4" ON "orders"  ("status") `,
    );
    await queryRunner.query(
      `CREATE TABLE "reviews" ("id" SERIAL NOT NULL, "productId" integer NOT NULL, "productName" character varying NOT NULL, "customerId" integer, "customerName" character varying NOT NULL, "rating" integer NOT NULL, "comment" text, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_36e31ae3716d3703c86952a1943" UNIQUE ("customerId", "productId"), CONSTRAINT "PK_231ae565c273ee700b283f15c1d" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_a6b3c434392f5d10ec17104366" ON "reviews"  ("productId") `,
    );
    await queryRunner.query(
      `CREATE TABLE "settings" ("id" integer NOT NULL DEFAULT '1', "storeName" character varying NOT NULL DEFAULT 'Kachipapa Store', "storeEmail" character varying, "storePhone" character varying, "storeAddress" character varying, "currency" character varying NOT NULL DEFAULT 'MK', "deliveryFee" numeric(10,2) NOT NULL DEFAULT '0', "freeDeliveryThreshold" numeric(10,2) NOT NULL DEFAULT '5000', "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_0669fe20e252eb692bf4d344975" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "wishlist_items" ("id" SERIAL NOT NULL, "customerId" integer NOT NULL, "productId" integer NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_33724555bd846f3f31b998136b9" UNIQUE ("customerId", "productId"), CONSTRAINT "PK_0bd52924a97cda208ed2a07bd69" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_transactions" ADD CONSTRAINT "FK_f21250669a9728997c6d8f6f5da" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" ADD CONSTRAINT "FK_a6b3c434392f5d10ec171043666" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "wishlist_items" ADD CONSTRAINT "FK_e6b23f67d5a558a97c5e7315a2f" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "wishlist_items" ADD CONSTRAINT "FK_485ece8ab9b569d1c560144aa25" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "wishlist_items" DROP CONSTRAINT "FK_485ece8ab9b569d1c560144aa25"`,
    );
    await queryRunner.query(
      `ALTER TABLE "wishlist_items" DROP CONSTRAINT "FK_e6b23f67d5a558a97c5e7315a2f"`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" DROP CONSTRAINT "FK_a6b3c434392f5d10ec171043666"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_transactions" DROP CONSTRAINT "FK_f21250669a9728997c6d8f6f5da"`,
    );
    await queryRunner.query(`DROP TABLE "wishlist_items"`);
    await queryRunner.query(`DROP TABLE "settings"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_a6b3c434392f5d10ec17104366"`,
    );
    await queryRunner.query(`DROP TABLE "reviews"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_775c9f06fc27ae3ff8fb26f2c4"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_e5de51ca888d8b1f5ac25799dd"`,
    );
    await queryRunner.query(`DROP TABLE "orders"`);
    await queryRunner.query(`DROP TABLE "notifications"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_f21250669a9728997c6d8f6f5d"`,
    );
    await queryRunner.query(`DROP TABLE "inventory_transactions"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_c3932231d2385ac248d0888d95"`,
    );
    await queryRunner.query(`DROP TABLE "products"`);
    await queryRunner.query(`DROP TABLE "customers"`);
    await queryRunner.query(`DROP TABLE "admin"`);
  }
}
