-- 190: Resolve the only genuine category url_key collision -> clean flat URLs.
--
-- cat 257 "CompTIA Exam Vouchers" shared url_key 'comptia-practice-exams' with
-- the live cat 35 "CompTIA Practice Exams". Because the base path was owned by
-- cat 35, every catalog_url reindex bumped 257's canonical to the next free
-- suffix (-40 -> -41 -> ... -> -81), producing an ever-growing 301 chain and no
-- clean URL for 257. Audit of all 388 active SG categories showed this is the
-- ONLY genuine collision; every other category already resolves flat at
-- /<url-key>.html (cat 152 "Recommended Courses" 404s on SG correctly — it is
-- is_active=0 at the SG store view).
--
-- Fix: give 257 its own semantic url_key 'comptia-exam-vouchers' (was free).
-- The collision disappears, 257 resolves flat at /comptia-exam-vouchers.html,
-- cat 35 keeps /comptia-practice-exams.html, and the suffix-climb stops for good.
-- The entrypoint catalog_url reindex (which runs after migrations) regenerates
-- the canonical from the new url_key; we also set the canonical + url_path
-- directly here so it is correct immediately even before the reindex.
-- Verified on local: rename + reindex -> both pages 200, flat, correct category.
-- Idempotent.

-- 1. New url_key (default scope) + drop any store-level url_key overrides.
UPDATE catalog_category_entity_varchar
  SET value = 'comptia-exam-vouchers'
  WHERE entity_id = 257 AND store_id = 0
    AND attribute_id = (SELECT attribute_id FROM eav_attribute
        WHERE attribute_code = 'url_key'
          AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'));

DELETE FROM catalog_category_entity_varchar
  WHERE entity_id = 257 AND store_id <> 0
    AND attribute_id = (SELECT attribute_id FROM eav_attribute
        WHERE attribute_code = 'url_key'
          AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'));

-- 2. url_path (default scope) so $category->getUrl() renders flat immediately.
UPDATE catalog_category_entity_varchar
  SET value = 'comptia-exam-vouchers.html'
  WHERE entity_id = 257 AND store_id = 0
    AND attribute_id = (SELECT attribute_id FROM eav_attribute
        WHERE attribute_code = 'url_path'
          AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'));

DELETE FROM catalog_category_entity_varchar
  WHERE entity_id = 257 AND store_id <> 0
    AND attribute_id = (SELECT attribute_id FROM eav_attribute
        WHERE attribute_code = 'url_path'
          AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'));

-- 3. Point the canonical (is_system=1) rewrites at the clean flat path now.
UPDATE core_url_rewrite
  SET request_path = 'comptia-exam-vouchers.html'
  WHERE category_id = 257 AND product_id IS NULL AND is_system = 1;

-- 4. Drop 257's stale comptia-practice-exams-<N> save-history rows (the climb).
DELETE FROM core_url_rewrite
  WHERE category_id = 257 AND product_id IS NULL
    AND request_path REGEXP '^comptia-practice-exams-[0-9]+\\.html$';
