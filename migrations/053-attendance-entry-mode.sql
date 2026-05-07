-- Add `entry_mode` to course_attendance so the trainer attendance UI
-- can show how each row was marked (manual / qr / digital / etc).
-- Previously the E-Attendance List table hardcoded the "Entry Mode"
-- column to "Manual" for every row. Now it reads this column.
--
-- All existing rows default to 'manual' since that's the only path
-- that's been alive since the QR check-in flow was retired in
-- migration 048.
--
-- Self-healing via INFORMATION_SCHEMA + PREPARE so re-runs are safe.

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_attendance'
               AND COLUMN_NAME = 'entry_mode');
SET @sql := IF(@has = 0,
    "ALTER TABLE course_attendance ADD COLUMN `entry_mode` VARCHAR(16) NOT NULL DEFAULT 'manual'",
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
