-- Wire www.tertiarycourses.com.my to the Malaysia store view.
--
-- The store was originally created with code='english' (legacy from when
-- it was a translation view rather than a country store). .htaccess sets
-- MAGE_RUN_CODE=malaysia MAGE_RUN_TYPE=store on the .com.my host (scaffold
-- from commit a24b9737), but there is no store with code='malaysia' — only
-- website code='malaysia' — so the request falls back to the SG default
-- view and the .com.my domain renders the SG site.
--
-- Fix:
--   1. Rename core_store.code 'english' → 'malaysia' so the .htaccess
--      MAGE_RUN_CODE matches a real store. Mirrors the gh/ng pattern.
--   2. Set the store-scope base_urls to https://www.tertiarycourses.com.my/.
--
-- Idempotent: rename is guarded by a WHERE clause; base_url inserts use
-- ON DUPLICATE KEY UPDATE (path,scope,scope_id is the unique key).

UPDATE core_store
SET code = 'malaysia'
WHERE code = 'english' AND website_id = 2;

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
