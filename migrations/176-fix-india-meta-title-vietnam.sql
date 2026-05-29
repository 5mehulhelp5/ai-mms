-- 542 products on the India store view (store_id=6) have meta_title ending
-- with "Tertiary Courses Vietnam" instead of "Tertiary Courses India".
-- Cause is unknown — most likely a misconfigured AI SEO meta generation
-- run, or India being repurposed from a Vietnam draft store. Either way,
-- the bad title is now serving as the <title> tag in Google for Indian
-- courses, hurting India SEO.
--
-- Targeted REPLACE only touches the bad suffix; the per-course prefix
-- ("AI for Healthcare:..." etc) is preserved verbatim.
--
-- Verified scope: only catalog_product_entity_varchar / store_id=6 /
-- attribute_id=meta_title is affected. catalog_product_entity_text and
-- cms_block for store_id=6 are clean (audit done 2026-05-29).
--
-- Idempotent: WHERE filter only matches rows still containing the bad
-- suffix, so a re-apply is a no-op.

SET @meta_title_id := (SELECT attribute_id FROM eav_attribute
    WHERE entity_type_id = 4 AND attribute_code = 'meta_title');

-- Main case: 540 rows ending in "Tertiary Courses Vietnam"
UPDATE catalog_product_entity_varchar
SET value = REPLACE(value, 'Tertiary Courses Vietnam', 'Tertiary Courses India')
WHERE attribute_id = @meta_title_id
  AND store_id = 6
  AND value LIKE '%Tertiary Courses Vietnam%';

-- Straggler 1 (SKU M362) — AI-generated title used "Architecture Vietnam"
-- as the second clause instead of the country-branded suffix.
UPDATE catalog_product_entity_varchar
SET value = REPLACE(value, 'Architecture Vietnam', 'Architecture India')
WHERE attribute_id = @meta_title_id
  AND store_id = 6
  AND value LIKE '%Architecture Vietnam%';

-- Straggler 2 (SKU M1783) — title has the double-country gaffe
-- "Tertiary Courses Singapore Vietnam". Collapse it to the India brand.
UPDATE catalog_product_entity_varchar
SET value = REPLACE(value, 'Tertiary Courses Singapore Vietnam', 'Tertiary Courses India')
WHERE attribute_id = @meta_title_id
  AND store_id = 6
  AND value LIKE '%Tertiary Courses Singapore Vietnam%';
