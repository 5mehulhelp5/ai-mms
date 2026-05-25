-- Assessment Duration product attribute.
--
-- Single-select dropdown rendered on the product page Course Information card
-- next to Sessions / Duration / Level. Options: NA + 0.5..3 in 0.5 steps.
--
-- Backfill rules:
--   - WSQ courses (SKU prefix 'TGS-'):
--       sessions = 1   -> '1'
--       sessions 2..5  -> '2'
--   - Non-WSQ courses (any other SKU) -> 'NA'
--
-- Re-runnable: every INSERT is guarded.

-- 1) Create the select attribute.
SET @aid := (SELECT attribute_id FROM eav_attribute
             WHERE entity_type_id=4 AND attribute_code='assessment_duration' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, source_model, frontend_input, frontend_label, is_required, is_user_defined, is_unique, note)
SELECT 4, 'assessment_duration', 'int', 'eav/entity_attribute_source_table', 'select', 'Assessment Duration', 0, 1, 0,
       'Hours allocated to the final assessment. WSQ (TGS-) 1-day courses default to 1 hr; 2-5 day courses default to 2 hrs. Non-WSQ defaults to NA.'
FROM DUAL WHERE @aid IS NULL;
SET @aid := IFNULL(@aid, LAST_INSERT_ID());

UPDATE eav_attribute SET source_model='eav/entity_attribute_source_table'
WHERE attribute_id=@aid AND (source_model IS NULL OR source_model='');

INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing)
VALUES (@aid, 1, 1, 0);

-- 2) Seed the option values. Capture each option_id into a per-label var so
--    the backfill below can reference them without re-querying.

-- NA
SET @opt_na := (SELECT eao.option_id FROM eav_attribute_option eao
                JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id
                WHERE eao.attribute_id=@aid AND eaov.store_id=0 AND eaov.value='NA' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid, 10 FROM DUAL WHERE @opt_na IS NULL;
SET @opt_na := IFNULL(@opt_na, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt_na, 0, 'NA');

-- 0.5
SET @opt_05 := (SELECT eao.option_id FROM eav_attribute_option eao
                JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id
                WHERE eao.attribute_id=@aid AND eaov.store_id=0 AND eaov.value='0.5' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid, 20 FROM DUAL WHERE @opt_05 IS NULL;
SET @opt_05 := IFNULL(@opt_05, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt_05, 0, '0.5');

-- 1
SET @opt_1 := (SELECT eao.option_id FROM eav_attribute_option eao
               JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id
               WHERE eao.attribute_id=@aid AND eaov.store_id=0 AND eaov.value='1' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid, 30 FROM DUAL WHERE @opt_1 IS NULL;
SET @opt_1 := IFNULL(@opt_1, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt_1, 0, '1');

-- 1.5
SET @opt_15 := (SELECT eao.option_id FROM eav_attribute_option eao
                JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id
                WHERE eao.attribute_id=@aid AND eaov.store_id=0 AND eaov.value='1.5' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid, 40 FROM DUAL WHERE @opt_15 IS NULL;
SET @opt_15 := IFNULL(@opt_15, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt_15, 0, '1.5');

-- 2
SET @opt_2 := (SELECT eao.option_id FROM eav_attribute_option eao
               JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id
               WHERE eao.attribute_id=@aid AND eaov.store_id=0 AND eaov.value='2' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid, 50 FROM DUAL WHERE @opt_2 IS NULL;
SET @opt_2 := IFNULL(@opt_2, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt_2, 0, '2');

-- 2.5
SET @opt_25 := (SELECT eao.option_id FROM eav_attribute_option eao
                JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id
                WHERE eao.attribute_id=@aid AND eaov.store_id=0 AND eaov.value='2.5' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid, 60 FROM DUAL WHERE @opt_25 IS NULL;
SET @opt_25 := IFNULL(@opt_25, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt_25, 0, '2.5');

-- 3
SET @opt_3 := (SELECT eao.option_id FROM eav_attribute_option eao
               JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id
               WHERE eao.attribute_id=@aid AND eaov.store_id=0 AND eaov.value='3' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid, 70 FROM DUAL WHERE @opt_3 IS NULL;
SET @opt_3 := IFNULL(@opt_3, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt_3, 0, '3');

-- 3) Attach to the "Course Details" group on every product attribute set.
INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @aid, 85
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'Course Details' AND eas.entity_type_id = 4
  AND @aid IS NOT NULL;

-- 4) Backfill. Look up sessions value from catalog_product_entity_varchar
--    (attribute_code='sessions' is backend_type=varchar) at admin scope.
SET @aid_sessions := (SELECT attribute_id FROM eav_attribute
                      WHERE entity_type_id=4 AND attribute_code='sessions' LIMIT 1);

-- WSQ, 1-day -> '1'
INSERT IGNORE INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @aid, 0, cpe.entity_id, @opt_1
FROM catalog_product_entity cpe
LEFT JOIN catalog_product_entity_varchar v
  ON v.entity_id=cpe.entity_id AND v.attribute_id=@aid_sessions AND v.store_id=0
WHERE cpe.sku LIKE 'TGS-%' AND CAST(v.value AS UNSIGNED)=1;

-- WSQ, 2..5 days -> '2'
INSERT IGNORE INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @aid, 0, cpe.entity_id, @opt_2
FROM catalog_product_entity cpe
LEFT JOIN catalog_product_entity_varchar v
  ON v.entity_id=cpe.entity_id AND v.attribute_id=@aid_sessions AND v.store_id=0
WHERE cpe.sku LIKE 'TGS-%' AND CAST(v.value AS UNSIGNED) BETWEEN 2 AND 5;

-- Non-WSQ -> 'NA'
INSERT IGNORE INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @aid, 0, cpe.entity_id, @opt_na
FROM catalog_product_entity cpe
WHERE cpe.sku NOT LIKE 'TGS-%';
