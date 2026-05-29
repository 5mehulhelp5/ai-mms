-- Backfill class_id for any course_runs rows that have NULL/empty class_id.
--
-- Root cause: run_id=1 was created manually via the admin "Create Class" form
-- on 2026-05-06, before migration 096 added the class_id column (2026-05-22).
-- When 096 ran it left existing rows as NULL; nothing subsequently backfilled them.
--
-- Strategy: compute the current MAX sequential number per country-code prefix,
-- then assign the next available ID to each NULL row in run_id order.
-- Uses a MySQL user-variable so multiple NULL rows each get a unique increment
-- rather than all receiving the same value.
--
-- Only SG is handled here because all known NULL rows belong to SG courses.
-- If NULL rows for other prefixes are discovered later a separate migration
-- should be added for each prefix (MY/GH/NG/BT/IN/TI).

SET @max_sg := (
    SELECT COALESCE(MAX(CAST(SUBSTRING(class_id, 3) AS UNSIGNED)), 0)
      FROM course_runs
     WHERE class_id LIKE 'SG%'
);

UPDATE course_runs
   SET class_id = CONCAT('SG', LPAD(@max_sg := @max_sg + 1, 6, '0'))
 WHERE (class_id IS NULL OR class_id = '')
 ORDER BY run_id;
