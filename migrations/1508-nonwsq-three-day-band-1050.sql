-- Every 3-day non-WSQ (C-prefix) course is priced at $1050.
--
-- The day count sets the fee, mirroring the 5-day $1800 band (migration 1480).
-- 3 days = 3 x 7.5 = 22.5 instructional hours. The WSQ parent's price is never
-- the reference -- the funded twin is priced on its own basis.
--
-- Scoped `sku LIKE 'C%' AND sku NOT LIKE 'CASL%'` so no TGS- (WSQ/CASL/IBF) or
-- M- (partner) course is touched. EVERY scope row is updated, not just store 0,
-- so a lingering store-scope override cannot keep serving the old price.
--
-- Idempotent: re-running is a no-op once every row already reads 1050.
-- Run AFTER 1507, which makes C1433 a 22.5-hour course.

SET @a_dur := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code = 'duration' AND entity_type_id = 4);
SET @a_prc := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code = 'price' AND entity_type_id = 4);

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity e
    ON e.entity_id = d.entity_id
  JOIN catalog_product_entity_varchar v
    ON v.entity_id = e.entity_id
   AND v.attribute_id = @a_dur
   AND v.store_id = 0
   SET d.value = 1050.0000
 WHERE d.attribute_id = @a_prc
   AND e.sku LIKE 'C%'
   AND e.sku NOT LIKE 'CASL%'
   AND TRIM(v.value) IN ('22.5', '22.50')
   AND d.value <> 1050.0000;
