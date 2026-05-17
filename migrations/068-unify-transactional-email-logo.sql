-- Unify the transactional-email header logo across every store/website.
-- Every scope should render the "Tertiary Infotech Academy" logo
-- (media/email/logo/default/Infotech-Academy-Email.jpg). Per-website overrides
-- are removed so all scopes fall back to the default value.

-- 1. Default scope: point at the unified logo + matching alt text + width.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'design/email/logo', 'default/Infotech-Academy-Email.jpg')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'design/email/logo_alt', 'Tertiary Infotech Academy')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'design/email/logo_width', '500')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- 2. Remove every website-level + store-level override so all scopes inherit
--    the unified default logo / alt / width above.
DELETE FROM core_config_data
WHERE path IN ('design/email/logo', 'design/email/logo_alt', 'design/email/logo_width')
  AND scope IN ('websites', 'stores');
