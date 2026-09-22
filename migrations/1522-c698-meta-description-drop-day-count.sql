-- C698: drop the day count from meta_description.
--
-- 1521 set "...in this 2-day masterclass in Singapore." The non-WSQ convention
-- is that the marketing copy never states a day count -- the Duration and
-- Sessions tiles are the single source of truth, so a phrase in the text can
-- only ever contradict them after a schedule change. Same wording otherwise.
--
-- meta_description is varchar(255); the replacement is 171 chars.
-- SG-only course (C-prefix). Idempotent: guarded on the old string.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C698');

SET @a_mdesc := (SELECT attribute_id FROM eav_attribute a
                 JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                 WHERE t.entity_type_code = 'catalog_product'
                   AND a.attribute_code = 'meta_description');

UPDATE catalog_product_entity_varchar
SET value = 'Master Agile project management for business. Learn Agile values, the Scrum framework, Lean methodology, sprint execution and project tracking at Tertiary Courses Singapore.'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid
  AND attribute_id = @a_mdesc
  AND value LIKE '%2-day masterclass%';
