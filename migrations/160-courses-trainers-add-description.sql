-- Add a `description` TEXT column on courses_trainers so each trainer
-- record carries its own bio. This is the column the View Trainers grid
-- on the dashboard now reads from, and the same value gets synced from
-- a trainer-role admin user's My Profile (admin_user.trainer_description)
-- via the AccountController save handler.
--
-- The actual bio data is backfilled by the next migration (161), which
-- harvests names + descriptions from the long-form `trainerprofile`
-- product attribute (eav id 153) where they've lived historically.
--
-- Idempotent: only adds when not already present.

SET @col_exists := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'courses_trainers'
      AND COLUMN_NAME  = 'description'
);
SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE courses_trainers ADD COLUMN description TEXT NULL AFTER linkedin_url',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
