-- C1433 PL-300 Microsoft Power BI Data Analyst Training: 2 days -> 3 days.
--
-- The course was converted from its WSQ parent TGS-2023037468 (3 days), so the
-- non-WSQ twin now runs the same length: 3 x 7.5 = 22.5 instructional hours,
-- 9:30am - 5:30pm. Sessions and Duration tiles must agree with the Lesson Plan.
-- Fee moves to the 3-day band ($1050) set by 1508.
--
-- Idempotent: every UPDATE is guarded on the old value.
-- SG only -- guarded on the SKU, so partner sites (M-prefix) are untouched.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1433');

SET @a_dur := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code = 'duration' AND entity_type_id = 4);
SET @a_ses := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code = 'sessions' AND entity_type_id = 4);

UPDATE catalog_product_entity_varchar
   SET value = '22.5'
 WHERE entity_id = @pid AND attribute_id = @a_dur AND TRIM(value) = '15';

UPDATE catalog_product_entity_varchar
   SET value = '3'
 WHERE entity_id = @pid AND attribute_id = @a_ses AND TRIM(value) = '2';
