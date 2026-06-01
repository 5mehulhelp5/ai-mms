-- Lock in Magento's built-in canonical tag for product and category pages.
--
-- These config values may already be empty/default; we explicitly set them so a
-- future admin edit (or env reset) doesn't silently drop the canonical tag and
-- break the cross-store SEO setup that depends on it:
--   1. head.phtml emits hreflang on every page.
--   2. Magento's built-in canonical handles product/category self-canonical.
--   3. head.phtml emits its own self-canonical for homepage / CMS / other pages.

INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
  ('default', 0, 'catalog/seo/use_canonical_tag',                 '1'),
  ('default', 0, 'catalog/seo/use_canonical_tag_for_categories',  '1')
ON DUPLICATE KEY UPDATE value = VALUES(value);
