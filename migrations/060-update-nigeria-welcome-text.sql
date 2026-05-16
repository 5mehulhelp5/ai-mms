-- Update header welcome text for Nigeria store view
-- Proof-of-deploy migration: demonstrates that www.tertiarycourses.com.ng
-- is served by this app and updates flow through the migration pipeline.
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'design/header/welcome', 'AI and Certificate Training in Nigeria'
FROM core_store s WHERE s.code = 'nigeria'
ON DUPLICATE KEY UPDATE value = VALUES(value);
