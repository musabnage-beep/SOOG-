-- CreateEnum
CREATE TYPE "SaleUnit" AS ENUM ('PIECE', 'CARTON');

-- AlterTable Product: carton sale support
ALTER TABLE "Product"
  ADD COLUMN "sellByCarton"   BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "unitsPerCarton" INTEGER,
  ADD COLUMN "cartonPrice"    DECIMAL(10,2);

-- AlterTable CartItem: per-unit lines
ALTER TABLE "CartItem" ADD COLUMN "unit" "SaleUnit" NOT NULL DEFAULT 'PIECE';

DROP INDEX "CartItem_userId_productId_key";

CREATE UNIQUE INDEX "CartItem_userId_productId_unit_key" ON "CartItem"("userId", "productId", "unit");

-- AlterTable OrderItem: snapshot of chosen unit
ALTER TABLE "OrderItem"
  ADD COLUMN "unit" "SaleUnit" NOT NULL DEFAULT 'PIECE',
  ADD COLUMN "unitsPerCarton" INTEGER;
