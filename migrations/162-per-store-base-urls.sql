-- Set per-store base_url overrides so each country domain renders absolute URLs
-- (sitemap entries, canonical tags, email links, store-switcher links) correctly.
--
-- Root cause this fixes:
--   Before this migration NO country store had a per-store base_url override.
--   Every store fell back to the default base_url (production: tertiarycourses.com.sg).
--   So .com.my / .com.gh / .com.ng / etc. sitemaps and canonical tags pointed at
--   .com.sg URLs, which Google interpreted as duplicate content and refused to
--   index ~6,450 pages on the country domains.
--
-- After this migration each store's absolute URLs match its own domain.
--
-- LOCAL DEV: run scripts/local-dev/reset-base-urls-to-localhost.sql after
-- applying this migration to get http://localhost:8080/ back for local testing.

INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
  ('stores', 1, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.sg/'),
  ('stores', 1, 'web/secure/base_url',   'https://www.tertiarycourses.com.sg/'),
  ('stores', 2, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.my/'),
  ('stores', 2, 'web/secure/base_url',   'https://www.tertiarycourses.com.my/'),
  ('stores', 3, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.gh/'),
  ('stores', 3, 'web/secure/base_url',   'https://www.tertiarycourses.com.gh/'),
  ('stores', 4, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.ng/'),
  ('stores', 4, 'web/secure/base_url',   'https://www.tertiarycourses.com.ng/'),
  -- Bhutan + India: domains reserved but DNS not yet pointed at this hosting.
  -- Base URL is set to the future production URL so cutover is zero-migration,
  -- but these stores are excluded from hreflang and robots.txt sitemap discovery
  -- until they go live (otherwise Google indexes 404s).
  ('stores', 5, 'web/unsecure/base_url', 'https://www.tertiarycourses.bt/'),
  ('stores', 5, 'web/secure/base_url',   'https://www.tertiarycourses.bt/'),
  ('stores', 6, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.in/'),
  ('stores', 6, 'web/secure/base_url',   'https://www.tertiarycourses.com.in/'),
  ('stores', 7, 'web/unsecure/base_url', 'https://www.tertiaryinfotech.edu.sg/'),
  ('stores', 7, 'web/secure/base_url',   'https://www.tertiaryinfotech.edu.sg/')
ON DUPLICATE KEY UPDATE value = VALUES(value);
