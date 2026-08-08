-- AlterTable Settings: admin kill-switch for delivery orders
ALTER TABLE "Settings"
  ADD COLUMN IF NOT EXISTS "deliveryEnabled" BOOLEAN NOT NULL DEFAULT true;
