-- 1480: C1162 "CompTIA Linux+ Training" -- follow-up to 1477.
--
-- 1477 set duration (37.5 hrs) and price ($1,800) for the 3-day -> 5-day move,
-- but the course-information panel's "Sessions" tile is driven by a SEPARATE
-- `sessions` attribute, which was left at 3. The live page therefore showed
-- "Sessions 3 days" next to "Duration 37.5 hrs" -- internally contradictory
-- (37.5 hrs over 3 days is not the 7.5 hrs/day house rule).
--
-- Sessions is the DAY COUNT, rendered by
-- app/design/frontend/ultimo/default/template/catalog/product/view/rightData.phtml:18
-- as "<sessions> day(s)". Parent TGS-2024048316 carries 5; the twin now runs the
-- same 5 days on the E02 counterpart template, so 3 -> 5.
--
-- Lesson for future duration changes: `duration` and `sessions` are two
-- attributes and BOTH must move together, or the tiles disagree.
--
-- store_id = 0, keyed on SKU -- clean no-op where the row is absent. Idempotent.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1162');
SET @a_sessions := (SELECT attribute_id FROM eav_attribute
                    WHERE entity_type_id = 4 AND attribute_code = 'sessions');

UPDATE catalog_product_entity_varchar
SET value = '5'
WHERE entity_id = @e AND attribute_id = @a_sessions AND store_id = 0
  AND @e IS NOT NULL AND @a_sessions IS NOT NULL;
