-- Add created_by to course_runs so each class row records whether it was
-- created automatically by the TGS registration bridge ("System") or
-- manually by an admin (their email). NULL means pre-existing row with
-- no attribution — displays as blank on the UI.

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_runs'
               AND COLUMN_NAME = 'created_by');
SET @sql := IF(@has = 0,
    'ALTER TABLE course_runs ADD COLUMN `created_by` VARCHAR(255) NULL AFTER created_at',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
