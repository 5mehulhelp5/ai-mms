-- Remove the stale numeric "Subjects" — tags whose name is a single
-- digit "1" .. "5". They exist in `tag` with ~700 product relations
-- between them but render nowhere on the storefront: the badge
-- pipeline in MMD_CourseImage_Helper_Data::getCourseBadges() filters
-- displayed tags through getAllBadges(), whose canonical vocabulary
-- is fixed at WSQ / SkillsFuture Credit / PSEA / UTAP / IBF / HRDF /
-- SFEC / Absentee Payroll / MCES. Numeric tag names don't match
-- anything in that list, so the relations are dead weight cluttering
-- the Manage Subjects admin grid.
--
-- Audited with `grep -rn` across app/code/local + app/design — no
-- PHP, phtml, JS, or layout references the tags by id or by name.
-- Safe to delete the tag rows + every related table.
--
-- Scoping by name (not id) so the migration is environment-portable:
-- the dev DB has these as tag_id 239/241/242/243/245, but prod /
-- staging may differ.

DELETE tr
FROM tag_relation AS tr
INNER JOIN tag AS t ON t.tag_id = tr.tag_id
WHERE t.name IN ('1','2','3','4','5');

DELETE ts
FROM tag_summary AS ts
INNER JOIN tag AS t ON t.tag_id = ts.tag_id
WHERE t.name IN ('1','2','3','4','5');

DELETE tp
FROM tag_properties AS tp
INNER JOIN tag AS t ON t.tag_id = tp.tag_id
WHERE t.name IN ('1','2','3','4','5');

DELETE FROM tag
WHERE name IN ('1','2','3','4','5');
