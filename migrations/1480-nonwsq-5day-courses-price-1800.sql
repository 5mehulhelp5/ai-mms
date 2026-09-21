-- House rule: every 5-day NON-WSQ (C-prefix) course is priced at $1800.
--
-- 5 days x 7.5 instructional hours = 37.5 hrs. Confirmed with the user on
-- 2026-09-21 to apply to ALL 49 matching courses at exactly $1800, including
-- the ones currently priced ABOVE it (C471/C584/C1287 $2000, C251 $2500,
-- C1543 $3500 take a price CUT) and the disabled ones (status = 2), so the
-- whole 5-day non-WSQ band is uniform.
--
-- Scope guard: sku LIKE 'C%' AND sku NOT LIKE 'CASL%' and sessions = '5'.
--   - TGS- (WSQ/CASL/IBF) courses are NOT touched — they are funded and priced
--     on their own basis.
--   - M-prefix partner SKUs are NOT touched (MY/GH run their own pricing), and
--     on a partner server no C-prefix rows exist, so this is a no-op there.
--
-- `price` is a DECIMAL attribute. Rows are written at the scope they already
-- exist at: the default-scope (store_id = 0) row is updated, and any
-- store-scope override rows for the same products are updated too, so a
-- lingering override cannot keep serving the old price.
--
-- Idempotent: re-running writes the same 1800.00.
--
-- AFTER DEPLOY: reindex + flush, or the flat catalog keeps serving the old
-- price -> /reindex/api/run?flush=1&token=<mmd_reindex/api/token>

SET @a_price := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'price' AND entity_type_id = 4 LIMIT 1);
SET @a_sess  := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'sessions' AND entity_type_id = 4 LIMIT 1);

-- The 5-day non-WSQ set, resolved once.
DROP TEMPORARY TABLE IF EXISTS tmp_nonwsq_5day;
CREATE TEMPORARY TABLE tmp_nonwsq_5day (entity_id INT PRIMARY KEY);

INSERT INTO tmp_nonwsq_5day (entity_id)
SELECT e.entity_id
  FROM catalog_product_entity e
  JOIN catalog_product_entity_varchar s
    ON s.entity_id = e.entity_id AND s.attribute_id = @a_sess AND s.store_id = 0
 WHERE e.sku LIKE 'C%'
   AND e.sku NOT LIKE 'CASL%'
   AND TRIM(s.value) = '5';

UPDATE catalog_product_entity_decimal d
  JOIN tmp_nonwsq_5day t ON t.entity_id = d.entity_id
   SET d.value = 1800.0000
 WHERE d.attribute_id = @a_price;

DROP TEMPORARY TABLE IF EXISTS tmp_nonwsq_5day;
