-- Enum additions live in their own migration: PostgreSQL forbids using a value
-- added by ALTER TYPE ... ADD VALUE inside the same transaction that adds it.
ALTER TYPE "OrderStatus" ADD VALUE IF NOT EXISTS 'WAITING_FOR_COURIER';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'ORDER_WAITING_FOR_COURIER';
