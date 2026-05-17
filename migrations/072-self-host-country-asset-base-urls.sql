-- Make every real-domain country store serve its own skin/js/media
-- assets instead of cross-loading them from ai-mms.tertiaryinfo.tech.
--
-- Root cause of the "checkout steps don't expand" bug on
-- www.tertiarycourses.com.my:
--
--   Migration 066 set web/{unsecure,secure}/base_url for the Malaysia
--   store to https://www.tertiarycourses.com.my/ but never set the
--   asset base URLs (base_skin_url / base_js_url / base_media_url).
--   On prod those store-scope rows are absent, so they fall back to
--   the default scope, which still points at the original Coolify
--   host https://ai-mms.tertiaryinfo.tech/. The page HTML is therefore
--   served from .com.my while prototype.js (in the merged JS bundle),
--   accordion.js and opcheckout.js are loaded from ai-mms. Whenever
--   ai-mms is unhealthy (it crash-loops on deploy / migration churn),
--   those <script>s 502 -> Accordion/Checkout/$ are undefined -> the
--   inline OnePage init throws -> the checkout accordion never binds
--   -> the four steps render but won't expand or advance.
--
-- Fix: for every store whose own base_url is a real https domain,
-- pin its skin/js/media base URLs to that same domain so the store
-- is fully self-hosted and no longer depends on ai-mms being up.
-- Stores still on http://localhost (Bhutan/India, not yet cut over)
-- are intentionally excluded by the LIKE 'https://%' guard so this
-- never rewrites a dev/placeholder URL.
--
-- Derived from each store's existing base_url (no hard-coded domains),
-- so it stays correct as more country domains are wired up and is safe
-- to re-run. Idempotent: the (scope,scope_id,path) unique key drives
-- ON DUPLICATE KEY UPDATE.

-- Unsecure: skin / js / media  <- web/unsecure/base_url
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', b.scope_id, 'web/unsecure/base_skin_url', CONCAT(b.value, 'skin/')
FROM core_config_data b
WHERE b.path = 'web/unsecure/base_url' AND b.scope = 'stores'
  AND b.value LIKE 'https://%'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', b.scope_id, 'web/unsecure/base_js_url', CONCAT(b.value, 'js/')
FROM core_config_data b
WHERE b.path = 'web/unsecure/base_url' AND b.scope = 'stores'
  AND b.value LIKE 'https://%'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', b.scope_id, 'web/unsecure/base_media_url', CONCAT(b.value, 'media/')
FROM core_config_data b
WHERE b.path = 'web/unsecure/base_url' AND b.scope = 'stores'
  AND b.value LIKE 'https://%'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Secure: skin / js / media  <- web/secure/base_url
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', b.scope_id, 'web/secure/base_skin_url', CONCAT(b.value, 'skin/')
FROM core_config_data b
WHERE b.path = 'web/secure/base_url' AND b.scope = 'stores'
  AND b.value LIKE 'https://%'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', b.scope_id, 'web/secure/base_js_url', CONCAT(b.value, 'js/')
FROM core_config_data b
WHERE b.path = 'web/secure/base_url' AND b.scope = 'stores'
  AND b.value LIKE 'https://%'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', b.scope_id, 'web/secure/base_media_url', CONCAT(b.value, 'media/')
FROM core_config_data b
WHERE b.path = 'web/secure/base_url' AND b.scope = 'stores'
  AND b.value LIKE 'https://%'
ON DUPLICATE KEY UPDATE value = VALUES(value);
