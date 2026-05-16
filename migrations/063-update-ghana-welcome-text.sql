-- Update header welcome text for Ghana store view
-- Proof-of-deploy / heading rebrand for www.tertiarycourses.com.gh.
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'design/header/welcome', 'Best Cyber Security and AI Trainings in Ghana'
FROM core_store s WHERE s.code = 'ghana'
ON DUPLICATE KEY UPDATE value = VALUES(value);
