-- CreateEnum
DO $$ BEGIN
  CREATE TYPE "DeliveryMethod" AS ENUM ('STORE', 'THIRD_PARTY');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- CreateTable
CREATE TABLE IF NOT EXISTS "DeliveryProvider" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "logo" TEXT,
    "logoKey" TEXT,
    "phone" TEXT,
    "website" TEXT,
    "deliveryFee" DECIMAL(10,2) NOT NULL,
    "estimatedDays" INTEGER NOT NULL DEFAULT 2,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DeliveryProvider_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "deliveryMethod" "DeliveryMethod" NOT NULL DEFAULT 'STORE';
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "deliveryProviderId" TEXT;

-- CreateIndex
CREATE INDEX IF NOT EXISTS "Order_deliveryProviderId_idx" ON "Order"("deliveryProviderId");

-- AddForeignKey
DO $$ BEGIN
  ALTER TABLE "Order" ADD CONSTRAINT "Order_deliveryProviderId_fkey"
    FOREIGN KEY ("deliveryProviderId") REFERENCES "DeliveryProvider"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
