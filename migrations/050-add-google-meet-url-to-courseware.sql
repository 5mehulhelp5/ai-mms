-- Add a `google_meet_url` column to course_courseware so the developer
-- editor can save a virtual meeting link per course. The trainer and
-- learner course-detail views read it from this column when the class
-- mode is Virtual or Hybrid; for Physical classes the views render N/A
-- regardless of any saved value.
--
-- Self-healing via INFORMATION_SCHEMA + PREPARE so re-runs and DBs that
-- already have the column (manual hotfix, etc.) skip the ADD COLUMN.

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_courseware'
               AND COLUMN_NAME = 'google_meet_url');
SET @sql := IF(@has = 0,
    "ALTER TABLE course_courseware ADD COLUMN `google_meet_url` VARCHAR(512) NOT NULL DEFAULT ''",
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
