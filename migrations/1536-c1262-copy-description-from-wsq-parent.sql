-- C1262: copy "What's This Course About" + course topics from the WSQ parent TGS-2023020567.
-- Copied IN-DATABASE from the parent row, so no quoting/encoding round-trip can corrupt the HTML.
-- The parent text states no day count (verified 2026-09-22); the only edit is dropping the
-- "WSQ-accredited" phrase, which must not appear on a non-WSQ course.
-- Idempotent: re-running copies the same parent values again.
-- Guarded: no-ops on any site where either SKU is absent (partner sites have neither).

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1262' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023020567' LIMIT 1);

SET @a_short := (SELECT attribute_id FROM eav_attribute a
                 JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id AND t.entity_type_code = 'catalog_product'
                 WHERE a.attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute a
                 JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id AND t.entity_type_code = 'catalog_product'
                 WHERE a.attribute_code = 'description');

-- short_description: parent text with the WSQ accreditation phrase removed
SET @short_src := (SELECT value FROM catalog_product_entity_text
                    WHERE entity_id = @src AND attribute_id = @a_short AND store_id = 0 LIMIT 1);
SET @short_new := REPLACE(@short_src,
                          'effective negotiation strategies in this WSQ-accredited course',
                          'effective negotiation strategies in this hands-on course');

-- course topics: verbatim from the parent
SET @desc_new := (SELECT value FROM catalog_product_entity_text
                   WHERE entity_id = @src AND attribute_id = @a_desc AND store_id = 0 LIMIT 1);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT e.entity_type_id, @a_short, 0, @pid, @short_new
  FROM catalog_product_entity e
 WHERE e.entity_id = @pid AND @pid IS NOT NULL AND @src IS NOT NULL AND @short_new IS NOT NULL
ON DUPLICATE KEY UPDATE value = @short_new;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT e.entity_type_id, @a_desc, 0, @pid, @desc_new
  FROM catalog_product_entity e
 WHERE e.entity_id = @pid AND @pid IS NOT NULL AND @src IS NOT NULL AND @desc_new IS NOT NULL
ON DUPLICATE KEY UPDATE value = @desc_new;

-- clear any store-scope overrides so the store-0 copy is what renders
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0 AND @pid IS NOT NULL;
