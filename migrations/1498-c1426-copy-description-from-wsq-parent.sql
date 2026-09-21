-- C1426 (AZ-900 Azure Fundamentals Training) — copy "What's This Course About"
-- (short_description) and the course topics (description) from its WSQ parent
-- TGS-2023036449, so both catalogue entries describe the same course.
--
-- Copied by SKU lookup (entity ids differ per partner site), store 0 only — C1426
-- has no store-scope override for either attribute. Idempotent: re-running copies
-- the same parent values.
--
-- meta_description is rewritten separately below: the WSQ parent's states funding
-- ("up to 70% WSQ funding subsidy"), which a non-WSQ course must never carry.

UPDATE catalog_product_entity_text dst
  JOIN catalog_product_entity de ON de.entity_id = dst.entity_id AND de.sku = 'C1426'
  JOIN eav_attribute a ON a.attribute_id = dst.attribute_id
   AND a.entity_type_id = 4
   AND a.attribute_code IN ('short_description','description')
  JOIN catalog_product_entity se ON se.sku = 'TGS-2023036449'
  JOIN catalog_product_entity_text src
    ON src.entity_id = se.entity_id
   AND src.attribute_id = dst.attribute_id
   AND src.store_id = 0
   SET dst.value = src.value
 WHERE dst.store_id = 0;

-- Non-funded meta description (varchar, 255 cap), no day count, no funding wording.
UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity e ON e.entity_id = v.entity_id AND e.sku = 'C1426'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 4 AND a.attribute_code = 'meta_description'
   SET v.value = 'Master Microsoft Azure fundamentals and prepare for the AZ-900 exam with hands-on labs in the Azure Portal and Cloud Shell. Cloud concepts, Azure architecture, security, cost and governance at Tertiary Courses Singapore.'
 WHERE v.store_id = 0;
