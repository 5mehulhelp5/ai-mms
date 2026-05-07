-- Add `certificate_url` to course_courseware so the developer can save
-- a real certificate-delivery link per course. The trainer / learner
-- Certificate Delivery section reads it from this column instead of
-- the hardcoded `https://example.com/certificate-demo` placeholder
-- that previously rendered for every course.
--
-- Self-healing via INFORMATION_SCHEMA + PREPARE so re-runs are safe.

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_courseware'
               AND COLUMN_NAME = 'certificate_url');
SET @sql := IF(@has = 0,
    "ALTER TABLE course_courseware ADD COLUMN `certificate_url` VARCHAR(512) NOT NULL DEFAULT ''",
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
