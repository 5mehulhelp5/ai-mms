-- Restore per-country store base URLs after the SG rename in
-- migration 075. Symptom this fixes: www.tertiarycourses.com.gh and
-- www.tertiarycourses.com.ng 301-redirect to www.tertiarycourses.com.sg
-- because their store-scope base_url rows are missing, so Magento
-- falls back to the default scope (which is now pinned to SG by 075)
-- and the redirect_to_base check fires.
--
-- Idempotent: each INSERT … ON DUPLICATE KEY UPDATE re-asserts the
-- canonical base_url for every store, so re-runs on a healthy DB are
-- a no-op (the values match what migrations 059, 061, 066, 075
-- originally seeded).
--
-- Stores covered: Singapore (1), Malaysia (2), Ghana (3), Nigeria (4),
-- Bhutan (5), India (6). Bhutan/India don't have live domains yet so
-- they're left pointing at the default scope (localhost in local
-- dev, SG/whatever-Coolify-serves in prod). Infotech (7) is the
-- tertiaryinfotech.edu.sg store — wired in migration 071.

-- ===== Singapore (store_code='singapore', store_id=1) =====
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.sg/'
FROM core_store s WHERE s.code = 'singapore'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_url', 'https://www.tertiarycourses.com.sg/'
FROM core_store s WHERE s.code = 'singapore'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/use_in_frontend', '1'
FROM core_store s WHERE s.code = 'singapore'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ===== Malaysia =====
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.my/'
FROM core_store s WHERE s.code = 'malaysia'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_url', 'https://www.tertiarycourses.com.my/'
FROM core_store s WHERE s.code = 'malaysia'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/use_in_frontend', '1'
FROM core_store s WHERE s.code = 'malaysia'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ===== Ghana =====
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.gh/'
FROM core_store s WHERE s.code = 'ghana'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_url', 'https://www.tertiarycourses.com.gh/'
FROM core_store s WHERE s.code = 'ghana'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/use_in_frontend', '1'
FROM core_store s WHERE s.code = 'ghana'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ===== Nigeria =====
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.ng/'
FROM core_store s WHERE s.code = 'nigeria'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_url', 'https://www.tertiarycourses.com.ng/'
FROM core_store s WHERE s.code = 'nigeria'
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/use_in_frontend', '1'
FROM core_store s WHERE s.code = 'nigeria'
ON DUPLICATE KEY UPDATE value = VALUES(value);
