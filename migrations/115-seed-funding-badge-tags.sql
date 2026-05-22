-- Seed the 9 canonical funding-badge tags used by MMD_CourseImage and the
-- storefront chip renderer. These form the controlled vocabulary that
-- admins pick from in the course-cover dialog and that the catalog list /
-- view pages render as colored pills under the course title.
--
-- status = 1 (Mage_Tag_Model_Tag::STATUS_APPROVED) so admin-managed and
-- visible to the storefront immediately. first_store_id = 0 (admin scope,
-- shared across all websites — funding badges are catalogue-wide metadata
-- and we filter rendering by website in PHP, not by tag scope).
--
-- The `tag` table has no unique constraint on `name`, so we guard each
-- insert with NOT EXISTS to stay idempotent. The `schema_migrations`
-- ledger also prevents re-runs at the apply.php level, but the guard is
-- belt-and-braces in case the migration is ever replayed manually.

INSERT INTO tag (name, status, first_store_id)
SELECT 'WSQ', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'WSQ');

INSERT INTO tag (name, status, first_store_id)
SELECT 'SkillsFuture Credit', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'SkillsFuture Credit');

INSERT INTO tag (name, status, first_store_id)
SELECT 'PSEA', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'PSEA');

INSERT INTO tag (name, status, first_store_id)
SELECT 'UTAP', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'UTAP');

INSERT INTO tag (name, status, first_store_id)
SELECT 'IBF', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'IBF');

INSERT INTO tag (name, status, first_store_id)
SELECT 'HRDF', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'HRDF');

INSERT INTO tag (name, status, first_store_id)
SELECT 'SFEC', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'SFEC');

INSERT INTO tag (name, status, first_store_id)
SELECT 'Absentee Payroll', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'Absentee Payroll');

INSERT INTO tag (name, status, first_store_id)
SELECT 'MCES', 1, 0
FROM dual WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'MCES');
