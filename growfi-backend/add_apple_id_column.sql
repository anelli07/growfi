-- Add apple_id column to user table
ALTER TABLE "user" ADD COLUMN IF NOT EXISTS apple_id VARCHAR(255) UNIQUE;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS ix_user_apple_id ON "user" (apple_id); 