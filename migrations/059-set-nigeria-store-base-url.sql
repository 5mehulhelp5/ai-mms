-- Set base URLs for Nigeria store view
-- Maps www.tertiarycourses.com.ng to the Nigeria store (code: nigeria).
-- Verify store_id by visiting System > Manage Stores > Nigeria Store View
-- and reading store_id/X in the URL. Pattern matches 009-set-infotech-store-base-url.sql.
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
