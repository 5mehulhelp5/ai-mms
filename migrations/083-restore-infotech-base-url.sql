-- Restore Infotech store base URLs. Migration 081 covered SG/MY/GH/NG
-- but not Infotech (store_id 7, code='infotech'), so
-- www.tertiaryinfotech.edu.sg is 301-redirecting to
-- www.tertiarycourses.com.sg via the same redirect_to_base mechanism
-- (default scope is pinned to SG, store-scope rows are missing).
--
-- Mirrors migration 009 exactly; idempotent on a healthy DB.

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_url', 'https://www.tertiaryinfotech.edu.sg/'
FROM core_store s WHERE s.code = 'infotech'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_url', 'https://www.tertiaryinfotech.edu.sg/'
FROM core_store s WHERE s.code = 'infotech'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/use_in_frontend', '1'
FROM core_store s WHERE s.code = 'infotech'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/use_in_adminhtml', '1'
FROM core_store s WHERE s.code = 'infotech'
ON DUPLICATE KEY UPDATE value = VALUES(value);
