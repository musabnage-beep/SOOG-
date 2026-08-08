-- Enum additions live in their own migration: Postgres forbids using a value
-- added by ALTER TYPE ... ADD VALUE inside the same transaction.
ALTER TYPE "SaleUnit" ADD VALUE IF NOT EXISTS 'HALF_KG';
ALTER TYPE "SaleUnit" ADD VALUE IF NOT EXISTS 'KG';
