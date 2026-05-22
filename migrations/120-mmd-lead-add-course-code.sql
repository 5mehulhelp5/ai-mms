-- MMD_Leads: add the optional "Course Code" captured from the Contact Us form.
--
-- The storefront form now has an optional Course Code field (e.g. a SkillsFuture
-- TGS reference). It is stored verbatim and feeds the WSQ course recommender in
-- MMD_Leads_Helper_Data::recommendCourse — an explicit code is an exact match.
--
-- Idempotent: INFORMATION_SCHEMA guard around the ADD COLUMN.

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'mmd_lead'
               AND COLUMN_NAME = 'course_code');
SET @sql := IF(@has = 0,
    'ALTER TABLE mmd_lead ADD COLUMN `course_code` VARCHAR(64) NOT NULL DEFAULT '''' AFTER courses_interested',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
