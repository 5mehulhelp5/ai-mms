-- Add `area_of_expertise` to courses_trainers so the View Trainers grid
-- column (currently always rendering "N/A" because no column existed)
-- has actual data to display. The Edit Trainer modal now exposes a
-- free-form text field for it; typical values are short comma-separated
-- lists like "Cybersecurity, Cloud Computing, AI".
--
-- Idempotent: only adds when not already present.

SET @col_exists := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'courses_trainers'
      AND COLUMN_NAME  = 'area_of_expertise'
);
SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE courses_trainers ADD COLUMN area_of_expertise VARCHAR(500) NULL AFTER trainer_type',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
