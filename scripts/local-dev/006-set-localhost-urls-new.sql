-- Improved replacement for 004-set-localhost-urls.sql.
-- Uses INSERT ... ON DUPLICATE KEY UPDATE (handles missing rows) and covers
-- all URL paths including base_media_url, base_skin_url, base_js_url, and
-- cookie_domain which the original 004 did not address.
--
-- Port defaults to http://localhost:8080/ — apply-local-dev-urls.php
-- substitutes LOCAL_BASE_URL at runtime for developers on a different port.

INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
('default', 0, 'web/unsecure/base_url',      'http://localhost:8080/'),
('default', 0, 'web/secure/base_url',         'http://localhost:8080/'),
('default', 0, 'web/unsecure/base_link_url',  '{{unsecure_base_url}}'),
('default', 0, 'web/secure/base_link_url',    '{{secure_base_url}}'),
('default', 0, 'web/unsecure/base_js_url',    '{{unsecure_base_url}}js/'),
('default', 0, 'web/secure/base_js_url',      '{{secure_base_url}}js/'),
('default', 0, 'web/unsecure/base_skin_url',  '{{unsecure_base_url}}skin/'),
('default', 0, 'web/secure/base_skin_url',    '{{secure_base_url}}skin/'),
('default', 0, 'web/unsecure/base_media_url', '{{unsecure_base_url}}media/'),
('default', 0, 'web/secure/base_media_url',   '{{secure_base_url}}media/'),
('default', 0, 'web/secure/use_in_frontend',  '0'),
('default', 0, 'web/secure/use_in_adminhtml', '0'),
('default', 0, 'web/url/redirect_to_base',    '0'),
('default', 0, 'web/cookie/cookie_domain',    '')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop ALL store/website-scoped URL rows so default scope wins
DELETE FROM core_config_data
 WHERE scope IN ('stores', 'websites')
   AND path IN (
     'web/unsecure/base_url',      'web/secure/base_url',
     'web/unsecure/base_link_url', 'web/secure/base_link_url',
     'web/unsecure/base_js_url',   'web/secure/base_js_url',
     'web/unsecure/base_skin_url', 'web/secure/base_skin_url',
     'web/unsecure/base_media_url','web/secure/base_media_url',
     'web/secure/use_in_frontend', 'web/secure/use_in_adminhtml',
     'web/url/redirect_to_base',   'web/cookie/cookie_domain'
   );
