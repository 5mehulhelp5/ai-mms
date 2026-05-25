-- Per-store general/store_information/name (a.k.a. Store::getFrontendName())
-- Lead auto-reply renders this in the email header and signature via
-- {{var store.frontend_name}}. If the value isn't set at the store scope,
-- Magento falls back to the default-scope value -- which is why an MY
-- visitor was receiving "Tertiary Infotech Academy" in their acknowledgement
-- email even though MY's correct brand is "Tertiary Courses Malaysia".
--
-- Idempotent: ON DUPLICATE KEY UPDATE rewrites the value if a row already
-- exists at that scope. Each store is looked up by code so this works in
-- any environment regardless of store_id ordering.

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'general/store_information/name', n.brand_name
FROM core_store s
JOIN (
    SELECT 'singapore' AS code, 'Tertiary Courses Singapore' AS brand_name UNION ALL
    SELECT 'malaysia',  'Tertiary Courses Malaysia'  UNION ALL
    SELECT 'ghana',     'Tertiary Courses Ghana'     UNION ALL
    SELECT 'nigeria',   'Tertiary Courses Nigeria'   UNION ALL
    SELECT 'bhutan',    'Tertiary Courses Bhutan'    UNION ALL
    SELECT 'india',     'Tertiary Courses India'
) n ON n.code = s.code
ON DUPLICATE KEY UPDATE value = VALUES(value);
