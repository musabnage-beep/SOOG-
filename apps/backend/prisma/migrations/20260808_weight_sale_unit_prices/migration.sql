-- AlterTable Product: optional weight units + custom base-unit label
ALTER TABLE "Product"
  ADD COLUMN IF NOT EXISTS "halfKgPrice" DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS "kgPrice"     DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS "pieceLabel"  TEXT;
