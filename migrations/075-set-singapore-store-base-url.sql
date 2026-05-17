-- Wire www.tertiarycourses.com.sg to the Singapore store view.
-- Mirrors migrations 059 (Nigeria), 061 (Ghana), 066 (Malaysia).
--
-- Background: the Singapore store was originally created with the
-- legacy code 'default' (the seed value for the first store view in
-- every fresh Magento install). The .htaccess block we just added
-- sets MAGE_RUN_CODE=singapore for tertiarycourses.com.sg, so we
-- need a store with code='singapore' or the request falls through to
-- the default scope and 301s to ai-mms.tertiaryinfo.tech.
--
-- Steps:
--   1. Rename core_store.code 'default' → 'singapore' on website_id=1
--      so the MAGE_RUN_CODE match succeeds.
--   2. Set the store-scope base_urls to https://www.tertiarycourses.com.sg/.
--   3. Force secure URLs in the frontend.
--
-- Also covers the asset base URLs (skin/js/media) via the same
-- pattern as migration 072 — but 072 already pins those from the
-- store-scope web/unsecure/base_url for any store whose base_url is
-- https://%, so as long as steps 1 + 2 land first, 072's logic will
-- catch this store automatically on the next deploy. We add an
-- explicit asset block here so a fresh DB also gets it right.

-- 1. Rename the store code so .htaccess MAGE_RUN_CODE=singapore matches a real store.
UPDATE core_store
SET code = 'singapore'
WHERE code = 'default' AND website_id = 1;

-- 2. Store-scope base URLs.
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

-- 3. Self-host skin/js/media assets at the same domain (mirrors migration 072).
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_skin_url', 'https://www.tertiarycourses.com.sg/skin/'
FROM core_store s WHERE s.code = 'singapore'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_js_url', 'https://www.tertiarycourses.com.sg/js/'
FROM core_store s WHERE s.code = 'singapore'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_media_url', 'https://www.tertiarycourses.com.sg/media/'
FROM core_store s WHERE s.code = 'singapore'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_skin_url', 'https://www.tertiarycourses.com.sg/skin/'
FROM core_store s WHERE s.code = 'singapore'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_js_url', 'https://www.tertiarycourses.com.sg/js/'
FROM core_store s WHERE s.code = 'singapore'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_media_url', 'https://www.tertiarycourses.com.sg/media/'
FROM core_store s WHERE s.code = 'singapore'
ON DUPLICATE KEY UPDATE value = VALUES(value);
