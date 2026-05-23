-- Seed WhatsApp float-button defaults per website.
-- Singapore (website_id=1, code "base")  : 6588666375
-- Malaysia  (website_id=2, code "malaysia"): 601123244187
--
-- Other countries (NG/GH/BT/IN/infotech) are left blank; admin can set via
-- System -> Configuration -> MMD -> WhatsApp Float Button (per website).
--
-- Idempotent: ON DUPLICATE KEY UPDATE rewrites the value if the row exists.
-- The (scope, scope_id, path) tuple is unique in core_config_data.

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('websites', 1, 'mmd_whatsapp/general/enabled', '1')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('websites', 1, 'mmd_whatsapp/general/number', '6588666375')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('websites', 2, 'mmd_whatsapp/general/enabled', '1')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('websites', 2, 'mmd_whatsapp/general/number', '601123244187')
ON DUPLICATE KEY UPDATE value = VALUES(value);
