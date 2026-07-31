-- Storage key of the uploaded category photo, so the old file can be replaced.
ALTER TABLE "Category" ADD COLUMN IF NOT EXISTS "iconKey" TEXT;
