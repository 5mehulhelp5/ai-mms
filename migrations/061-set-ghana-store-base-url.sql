-- Set base URLs for Ghana store view
-- Maps www.tertiarycourses.com.gh to the Ghana store (code: ghana).
-- Auto-resolves store_id via core_store.code lookup.
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
