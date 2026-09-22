-- 1525: flatten the category-prefixed 301 targets created by 1524
--
-- Split out of 1524 because that file was already in the local ledger when the
-- flattening was found; an amended migration never re-runs (see
-- feedback_amended_migration_needs_followup_file).
--
-- Category URLs are always flat here (MMD_FlatCategoryUrl), so a stored target
-- like "adult-training-courses/project-management-masterclass.html" 301s into a
-- 404. Idempotent: rows already flat contain no '/' and are untouched.
-- Flatten any CATEGORY-PREFIXED 301 target to the bare slug. Category URLs are
-- always flat here (MMD_FlatCategoryUrl), so a target like
-- "adult-training-courses/project-management-masterclass.html" 301s into a 404.
-- Idempotent: rows already flat have no '/' and are untouched.
UPDATE core_url_rewrite
   SET target_path = SUBSTRING_INDEX(target_path, '/', -1)
 WHERE is_system = 0
   AND target_path LIKE '%/project-management-masterclass.html';
