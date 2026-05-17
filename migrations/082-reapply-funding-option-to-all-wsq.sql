-- Backstop migration: re-apply the SG Funding Eligibility custom
-- option to every TGS-* WSQ product that's still missing it after
-- migrations 079 + 080. Same logic as 080 but worth re-running once
-- because a few prod products were observed missing the option even
-- after 080 applied (probable cause: enable_sg_funding=1 was not yet
-- committed when 080's INNER JOIN ran on prod, so those products
-- fell through 080's filter).
--
-- All four INSERTs are guarded with NOT EXISTS / ON DUPLICATE KEY
-- UPDATE so re-running on a healthy DB is a no-op. The only new
-- writes are for TGS-* products whose option is still missing.

-- 1. Re-assert enable_sg_funding=1 for every TGS-* SKU (idempotent
--    catch-up for any product that 079 missed).
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, p.entity_id, 1
FROM catalog_product_entity p
CROSS JOIN eav_attribute a
WHERE a.entity_type_id = 4
  AND a.attribute_code = 'enable_sg_funding'
  AND p.sku LIKE 'TGS-%'
ON DUPLICATE KEY UPDATE value = 1;

-- 2. Create the radio option row per missing product.
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
WHERE p.sku LIKE 'TGS-%'
  AND NOT EXISTS (
      SELECT 1 FROM catalog_product_option o
      JOIN catalog_product_option_title ot ON ot.option_id=o.option_id AND ot.store_id=0
      WHERE o.product_id = p.entity_id
        AND ot.title = 'Funding Eligibility (Subject to Verification)'
  );

-- 3. Title for each new option.
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

-- 4. Five canonical values per new option.
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

-- 5. Title (lowercased-key-matching label) for each value.
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
