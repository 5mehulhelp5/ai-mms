-- Final backstop: ensure EVERY TGS-* WSQ product has the
-- Funding Eligibility option provisioned. Migrations 080 and 082
-- already cover this, but a fresh migration is the only way to make
-- the same idempotent SQL re-execute on prod (apply.php skips files
-- it has already recorded in schema_migrations).
--
-- Same four-table provision as 080/082, gated by NOT EXISTS on the
-- option title; no-op on rows already provisioned.

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
