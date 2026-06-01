-- Per-store sitemap configuration.
--
-- Before: only stores 1 (SG) and 2 (MY) had sitemap rows, both writing to
-- sitemap.xml at the web root. Result: each cron run overwrote the previous
-- store's file, and all country domains ended up serving whichever store
-- generated last (in practice always SG).
--
-- After: each active store has its own filename (sitemap-<code>.xml).
-- .htaccess routes /sitemap.xml on each country domain to the matching file.
-- Sitemap cron generates all 7 daily.
--
-- Bootstrap note: this migration only seeds the config rows. To actually
-- generate the files immediately (rather than waiting for the next cron),
-- run: docker exec ai-mms-web-1 php /var/www/html/scripts/seo/generate-sitemaps.php
-- (production: equivalent command on the live container, or wait one cron cycle).

DELETE FROM sitemap WHERE store_id IN (1,2,3,4,5,6,7);

-- Filenames use underscores: Magento 1's Mage_Sitemap_Model_Sitemap::_validate()
-- rejects hyphens (only a-z 0-9 _ allowed).
INSERT INTO sitemap (sitemap_filename, sitemap_path, sitemap_time, store_id) VALUES
  ('sitemap_singapore.xml', '/', NOW(), 1),
  ('sitemap_malaysia.xml',  '/', NOW(), 2),
  ('sitemap_ghana.xml',     '/', NOW(), 3),
  ('sitemap_nigeria.xml',   '/', NOW(), 4),
  ('sitemap_bhutan.xml',    '/', NOW(), 5),
  ('sitemap_india.xml',     '/', NOW(), 6),
  ('sitemap_infotech.xml',  '/', NOW(), 7);

-- Ensure sitemap cron is on at default scope. Defaults already enable it but
-- pin the values so a future admin edit doesn't accidentally drop generation.
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
  ('default', 0, 'sitemap/generate/enabled',   '1'),
  ('default', 0, 'sitemap/generate/frequency', 'D'),
  ('default', 0, 'sitemap/generate/time',      '03,00,00')
ON DUPLICATE KEY UPDATE value = VALUES(value);
