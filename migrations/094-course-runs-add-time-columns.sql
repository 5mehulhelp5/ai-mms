-- Add course_start_time and course_end_time to course_runs so that
-- same-day classes with different timings produce distinct rows.
--
-- Uses INFORMATION_SCHEMA + PREPARE for idempotency (the migration runner
-- splits on ';' at end-of-line, so stored procedures are not used).

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_runs'
               AND COLUMN_NAME = 'course_start_time');
SET @sql := IF(@has = 0,
    'ALTER TABLE course_runs ADD COLUMN `course_start_time` TIME NULL AFTER course_end_date',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_runs'
               AND COLUMN_NAME = 'course_end_time');
SET @sql := IF(@has = 0,
    'ALTER TABLE course_runs ADD COLUMN `course_end_time` TIME NULL AFTER course_start_time',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Non-unique index first (safe even if rows already exist).
SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_runs'
               AND INDEX_NAME = 'idx_product_date_time');
SET @sql := IF(@has = 0,
    'ALTER TABLE course_runs ADD KEY `idx_product_date_time` (product_id, course_start_date, course_start_time, course_end_time)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Unique guard prevents duplicate classes from concurrent registrations.
-- Added separately so existing data can be audited before this runs.
SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_runs'
               AND INDEX_NAME = 'uk_product_date_time');
SET @sql := IF(@has = 0,
    'ALTER TABLE course_runs ADD UNIQUE KEY `uk_product_date_time` (product_id, course_start_date, course_start_time, course_end_time)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
