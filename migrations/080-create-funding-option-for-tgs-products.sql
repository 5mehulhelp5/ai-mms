-- Bulk-provision the "Funding Eligibility (Subject to Verification)"
-- custom option for every TGS-* product that has enable_sg_funding=1
-- but doesn't already carry the option.
--
-- Why we do this in SQL rather than firing the observer 299 times:
-- the observer runs on catalog_product_save_after, which would mean
-- iterating every product through the full save pipeline (price
-- index reindex, cache invalidation, customoptions_qty cascade, …).
-- For ~300 products that's slow and error-prone. The four direct
-- INSERTs below are exact and idempotent.
--
-- Schema (matches existing funding option id=34043 on the legacy site):
--   catalog_product_option            — radio option row per product
--   catalog_product_option_title      — store_id=0 title row
--   catalog_product_option_type_value — 5 radio values per product
--   catalog_product_option_type_title — store_id=0 title row per value
--
-- Idempotency: the target rows are gated by NOT EXISTS subqueries on
-- the option title; re-running this migration is a no-op once
-- options are present.

-- 1. Create the option row per target product.
INSERT INTO catalog_product_option
    (product_id, type, is_require, sku, sort_order,
     customoptions_is_onetime, image_path, customer_groups,
     qnty_input, in_group_id, is_dependent, div_class,
     sku_policy, image_mode, exclude_first_image)
SELECT p.entity_id, 'radio', 0, '', 100,
       0, '', '',
       0, 0, 0, '',
       0, 1, 0
FROM catalog_product_entity p
JOIN eav_attribute a ON a.entity_type_id=4 AND a.attribute_code='enable_sg_funding'
JOIN catalog_product_entity_int v
  ON v.entity_id=p.entity_id AND v.attribute_id=a.attribute_id AND v.value=1
WHERE p.sku LIKE 'TGS-%'
  AND NOT EXISTS (
      SELECT 1 FROM catalog_product_option o
      JOIN catalog_product_option_title ot ON ot.option_id=o.option_id AND ot.store_id=0
      WHERE o.product_id = p.entity_id
        AND ot.title = 'Funding Eligibility (Subject to Verification)'
  );

-- 2. Title for each new option (store_id=0 / default scope).
INSERT INTO catalog_product_option_title (option_id, store_id, title)
SELECT o.option_id, 0, 'Funding Eligibility (Subject to Verification)'
FROM catalog_product_option o
JOIN catalog_product_entity p ON p.entity_id=o.product_id
WHERE p.sku LIKE 'TGS-%'
  AND o.type='radio'
  AND o.sort_order=100
  AND NOT EXISTS (
      SELECT 1 FROM catalog_product_option_title t
      WHERE t.option_id=o.option_id AND t.store_id=0
  );

-- 3. Five canonical values per new option. The labels must match the
--    keys in MMD_SingaporePrice_Helper_Data::getFundingDiscountMap()
--    (normalised to lowercase). Order matches the storefront radio
--    order on the legacy SG site.
INSERT INTO catalog_product_option_type_value
    (option_id, sku, sort_order, reg_course, customoptions_qty,
     `default`, in_group_id, dependent_ids, weight)
SELECT o.option_id, '', v.sort_order, '', '',
       0, 0, '', 0
FROM catalog_product_option o
JOIN catalog_product_option_title ot
  ON ot.option_id=o.option_id AND ot.store_id=0
 AND ot.title='Funding Eligibility (Subject to Verification)'
JOIN catalog_product_entity p
  ON p.entity_id=o.product_id AND p.sku LIKE 'TGS-%'
CROSS JOIN (
    SELECT 1 AS sort_order UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5
) v
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_product_option_type_value tv
    WHERE tv.option_id=o.option_id
);

-- 4. Title (lowercased-key-matching label) for each value.
INSERT INTO catalog_product_option_type_title (option_type_id, store_id, title)
SELECT tv.option_type_id, 0,
       CASE tv.sort_order
           WHEN 1 THEN 'Singaporean above 40 yrs old'
           WHEN 2 THEN 'Singaporean below 40 yrs old'
           WHEN 3 THEN 'Singapore PR'
           WHEN 4 THEN 'non Singaporean'
           WHEN 5 THEN 'SME (Singaporean/PR Direct Hire)'
       END
FROM catalog_product_option_type_value tv
JOIN catalog_product_option o ON o.option_id=tv.option_id
JOIN catalog_product_option_title ot
  ON ot.option_id=o.option_id AND ot.store_id=0
 AND ot.title='Funding Eligibility (Subject to Verification)'
JOIN catalog_product_entity p
  ON p.entity_id=o.product_id AND p.sku LIKE 'TGS-%'
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_product_option_type_title ott
    WHERE ott.option_type_id=tv.option_type_id AND ott.store_id=0
);
